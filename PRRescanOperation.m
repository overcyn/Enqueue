#import "PRRescanOperation.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRTask.h"
#import "PRTaskManager.h"
#import "NSIndexSet+Extensions.h"
#import "NSEnumerator+Extensions.h"
#import "NSFileManager+Extensions.h"
#import "PRAlbumArtController.h"
#import "PRDirectoryEnumerator.h"
#import "PRUserDefaults.h"
#import "PRNowPlayingController.h"
#import "PRFileInfo.h"
#import "PRTagger.h"


@implementation PRRescanOperation

// ========================================
// Initialization
// ========================================

+ (id)operationWithURLs:(NSArray *)URLs core:(PRCore *)core
{
    return [[[PRRescanOperation alloc] initWithURLs:URLs core:core] autorelease];
}

- (id)initWithURLs:(NSArray *)URLs core:(PRCore *)core
{
    if (!(self = [super init])) {return nil;}
    _core = core;
    _db = [_core db];
    _URLs = [URLs retain];
    _eventId = 0;
    _monitor = FALSE;
	return self;
}

- (void)dealloc
{
    [_URLs release];
    [super dealloc];
}

// ========================================
// Accessors
// ========================================

@synthesize eventId = _eventId;
@synthesize monitor = _monitor;

// ========================================
// Action
// ========================================

- (void)main
{
    NSLog(@"begin folderrescan");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PRTask *task = [PRTask task];
    [task setTitle:@"Rescanning Folders..."];
    [[_core taskManager] addTask:task];
    
    // Get Monitored files
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [_db execute:@"DROP TABLE IF EXISTS tmp_tbl_monitored_files"];
        [_db execute:@"CREATE TEMP TABLE tmp_tbl_monitored_files (file_id INTEGER UNIQUE NOT NULL, path TEXT NOT NULL, exist INTEGER DEFAULT 0)"];
        for (NSURL *i in _URLs) {
            [_db execute:@"INSERT OR IGNORE INTO tmp_tbl_monitored_files (file_id, path) SELECT file_id, path FROM library WHERE hfs_begins(?1, path)"
                bindings:[NSDictionary dictionaryWithObjectsAndKeys:[i absoluteString], [NSNumber numberWithInt:1], nil]
                 columns:nil];
        }
    }];
    
    // Filter and add/update files
    NSArray *files;
    PRDirectoryEnumerator *dirEnum = [PRDirectoryEnumerator enumeratorWithURLs:_URLs];
    while ((files = [dirEnum nextXObjects:100])) {
        [task setPercent:(int)([dirEnum progress] * 90)];
        [self filterURLs:files];
        if ([task shouldCancel]) {
            goto end;
        }
    }
    
    // Remove files
    [task setPercent:95];
    NSMutableIndexSet *toRemove = [NSMutableIndexSet indexSet];
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        NSArray *rlt = [_db execute:@"SELECT file_id FROM tmp_tbl_monitored_files WHERE exist = 0"
                           bindings:nil 
                            columns:[NSArray arrayWithObjects:PRColInteger, nil]];
        for (NSArray *i in rlt) {
            [toRemove addIndex:[[i objectAtIndex:0] intValue]];
        }
    }];
    [self removeFiles:toRemove];
    
    // Update lastEventStreamEventId
    [task setPercent:99];
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [[PRUserDefaults userDefaults] setLastEventStreamEventId:_eventId];
        if (_monitor) {
            [[_core folderMonitor] monitor];
        }
    }];

end:;
    [[_core taskManager] removeTask:task];
    [pool drain];
    NSLog(@"end folderrescan");
}

- (void)filterURLs:(NSArray *)URLs // Array of dictionaries containing NSURL, size, lastmodified, caseSensitive
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray *toUpdate = [NSMutableArray array];
    NSMutableArray *toAdd = [NSMutableArray array];
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        for (NSDictionary *i in URLs) {
            NSURL *URL = [i objectForKey:@"URL"];
            // Find similar (case insensitive compare) files to current URL and merge them.
            [self mergeSimilar:URL];
            // Find existing files. Add if none. Update if Size or LastModified changed.
            NSInteger f = [[[_db library] filesWithValue:[URL absoluteString] forAttribute:PRPathFileAttribute] firstIndex];
            if (f == NSNotFound) {
                [toAdd addObject:URL];
            } else {
                NSNumber *size = [i objectForKey:@"size"];
                NSString *last = [[i objectForKey:@"lastModified"] description];
                NSNumber *size2 = [[_db library] valueForFile:f attribute:PRSizeFileAttribute];
                NSString *last2 = [[_db library] valueForFile:f attribute:PRLastModifiedFileAttribute];
                if ([size isEqualToNumber:size2] && [last isEqualToString:last2]) {
                    [self setFileExists:f];
                } else {
                    [toUpdate addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:f], @"file", 
                                         URL, @"URL", nil]];
                }
            }
        }
    }];
    [self addURLs:toAdd];
    [self updateFiles:toUpdate];
    [pool drain];
}

- (void)mergeSimilar:(NSURL *)URL
{
    NSArray *similar = [[_db library] filesWithSimilarURL:URL]; 
    NSMutableArray *toMerge = [NSMutableArray array];
    BOOL exact = FALSE;
    // Find all files at URL
    for (NSNumber *i in similar) {
        NSString *URLString = [[_db library] valueForFile:[i intValue] attribute:PRPathFileAttribute];
        if ([URLString isEqualToString:[URL absoluteString]]) {
            exact = TRUE;
            [toMerge insertObject:i atIndex:0];
        } else {
            NSURL *URL2 = [NSURL URLWithString:URLString];
            if ([[NSFileManager defaultManager] itemAtURL:URL equalsItemAtURL:URL2]) {
                [toMerge addObject:i];
            }
        }
    }
    if ([toMerge count] >= 1 && !exact) {
        // If no exact match update with new path.
        [[_db library] setValue:[URL absoluteString] forFile:[[toMerge objectAtIndex:0] intValue] attribute:PRPathFileAttribute];
    }
}

- (void)addURLs:(NSArray *)URLs // Array of NSURLs to add
{
    [[_db albumArtController] clearTempArt];
    // Get info for URLs
    NSMutableArray *infoArray = [NSMutableArray array];
    for (int i = 0; i < [URLs count]; i++) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        PRFileInfo *info = [PRTagger infoForURL:[URLs objectAtIndex:i]];
        if (!info) {
            [pool drain]; continue;
        }
        [[info attributes] setObject:[[NSDate date] description] forKey:[NSNumber numberWithInt:PRDateAddedFileAttribute]];
        if ([info art]) {
            [info setTempArt:[[_db albumArtController] saveTempArt:[info art]]];
            [info setArt:nil];
        }
        [infoArray addObject:info];
        [pool drain];
    }
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [_db begin];
        for (PRFileInfo *i in infoArray) {
            // Check if file exists with same checksum and size
            NSArray *rlt = [_db execute:@"SELECT file_id, path FROM library WHERE checkSum = ?1 AND size = ?2" 
                               bindings:[NSDictionary dictionaryWithObjectsAndKeys:
                                         [[i attributes] objectForKey:[NSNumber numberWithInt:PRCheckSumFileAttribute]], [NSNumber numberWithInt:1], 
                                         [[i attributes] objectForKey:[NSNumber numberWithInt:PRSizeFileAttribute]], [NSNumber numberWithInt:2], nil]
                                columns:[NSArray arrayWithObjects:PRColInteger, PRColString, nil]];
            PRFile moved = 0;
            for (NSArray *j in rlt) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:[[NSURL URLWithString:[j objectAtIndex:1]] path]]) {
                    moved = [[j objectAtIndex:0] intValue];
                }
            }
            // Add file if doesnt exist. Update path if it does
            if (moved == 0) {
                PRFile file = [[_db library] addFileWithAttributes:[i attributes]];
                [i setFile:file];
            } else {
                [[_db library] setValue:[[i attributes] objectForKey:[NSNumber numberWithInt:PRPathFileAttribute]] 
                                forFile:moved 
                              attribute:PRPathFileAttribute];
                [self setFileExists:moved];
            }
        }
        [_db commit];
        // post notifications
        if ([infoArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postLibraryChanged];
        }
    }];
    // set artwork for files
    for (PRFileInfo *i in infoArray) {
        if ([i tempArt] != 0 && [i file] != 0) {
            [[_db albumArtController] setTempArt:[i tempArt] forFile:[i file]];
        }
    }
}

- (void)updateFiles:(NSArray *)files // Array of NSDictionary with file (as NSNumber) and corresponding NSURL
{
    [[_db albumArtController] clearTempArt];
    // get updated attributes
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSDictionary *i in files) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        PRFileInfo *info = [PRTagger infoForURL:[i objectForKey:@"URL"]];
        if (!info) {
            [pool drain]; continue;
        }
        [info setFile:[[i objectForKey:@"file"] intValue]];
        if ([info art]) {
            [info setTempArt:[[_db albumArtController] saveTempArt:[info art]]];
            [info setArt:nil];
        }
        [infoArray addObject:info];
        [pool drain];
    }
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [_db begin];
        // set updated attributes
        NSMutableIndexSet *updated = [NSMutableIndexSet indexSet];
        for (PRFileInfo *i in infoArray) {
            [[_db library] setAttributes:[i attributes] forFile:[i file]];
            [self setFileExists:[i file]];
            [updated addIndex:[i file]];
        }
        [_db commit];
        // post notifications
        if ([infoArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postFilesChanged:updated];
        }
    }];
    // set art
    for (PRFileInfo *i in infoArray) {
        if ([i file] == 0) {continue;}
        if ([i tempArt] != 0) {
            [[_db albumArtController] setTempArt:[i tempArt] forFile:[i file]];
        } else {
            [[_db albumArtController] clearAlbumArtForFile2:[i file]];
        }
    }
}

- (void)removeFiles:(NSIndexSet *)files
{
    if ([files count] == 0) {return;}
    [[NSOperationQueue mainQueue] addBlockAndWait:^{        
        if ([files containsIndex:[[_core now] currentFile]]) {
            [[_core now] stop];
        }
        [[_db library] removeFiles:files];
        [[NSNotificationCenter defaultCenter] postLibraryChanged];
        [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[[_core now] currentPlaylist]];
    }];
}

// ========================================
// Misc
// ========================================

- (void)setFileExists:(PRFile)file // Should only be called on the main thread
{
    [_db execute:@"UPDATE tmp_tbl_monitored_files SET exist = 1 WHERE file_id = ?1"
        bindings:[NSDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil]
         columns:nil];
}

@end
