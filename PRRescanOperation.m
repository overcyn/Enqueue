#import "PRRescanOperation.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRTagEditor.h"
#import "PRTask.h"
#import "PRTaskManager.h"
#import "NSIndexSet+Extensions.h"
#import "NSEnumerator+Extensions.h"
#import "NSFileManager+Extensions.h"
#import "PRAlbumArtController.h"
#import "PRDirectoryEnumerator.h"
#import "PRUserDefaults.h"
#import "PRNowPlayingController.h"


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
    NSLog(@"begin import");
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    PRTask *task = [PRTask task];
    [task setTitle:@"Scanning Folders..."];
    [[_core taskManager] addTask:task];
    
    // Get Monitored files
    void (^blk)(void) = ^{
        [_db execute:@"DROP TABLE IF EXISTS tmp_tbl_monitored_files"];
        [_db execute:@"CREATE TEMP TABLE tmp_tbl_monitored_files (file_id INTEGER UNIQUE NOT NULL, path TEXT NOT NULL, exist INTEGER DEFAULT 0)"];
        for (NSURL *i in _URLs) {
            NSString *stm = @"INSERT OR IGNORE INTO tmp_tbl_monitored_files (file_id, path) SELECT file_id, path FROM library WHERE hfs_begins(?1, path)";
            NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:[i absoluteString], [NSNumber numberWithInt:1], nil];
            [_db execute:stm bindings:bnd columns:nil];
        }
    };
    [[NSOperationQueue mainQueue] addBlockAndWait:blk];
    
    // Filter and add/update files
    NSArray *files;
    PRDirectoryEnumerator *dirEnum = [PRDirectoryEnumerator enumeratorWithURLs:_URLs];
    while ((files = [dirEnum nextXObjects:200])) {
        [task setTitle:[NSString stringWithFormat:@"Scanning Folders... %d%%", (int)([dirEnum progress] * 90)]];
        [self filterURLs:files];
        if ([task shouldCancel]) {
            goto end;
        }
    }
    
    // Remove files
    [task setTitle:@"Scanning Folders... 95%%"];
    NSMutableArray *toRemove = [NSMutableArray array];
    blk = ^{
        NSString *stm = @"SELECT file_id FROM tmp_tbl_monitored_files WHERE exist = 0";
        NSArray *col = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
        NSArray *rst = [_db execute:stm bindings:nil columns:col];
        for (NSArray *i in rst) {
            [toRemove addObject:[i objectAtIndex:0]];
        }
    };
    [[NSOperationQueue mainQueue] addBlockAndWait:blk];
    [self removeFiles:toRemove];
    
    // Update lastEventStreamEventId
    [task setTitle:@"Scanning Folders... 100%%"];
    blk = ^{
        [[PRUserDefaults userDefaults] setLastEventStreamEventId:_eventId];
        if (_monitor) {
            [[_core folderMonitor] monitor];
        }
    };
    [[NSOperationQueue mainQueue] addBlockAndWait:blk];
    
end:;
    [[_core taskManager] removeTask:task];
    [p drain];
    NSLog(@"end import");
}

- (void)filterURLs:(NSArray *)URLs
{
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    NSMutableArray *toUpdate = [NSMutableArray array];
    NSMutableArray *toAdd = [NSMutableArray array];
    NSMutableIndexSet *didRemove = [NSMutableIndexSet indexSet];
    void (^blk)(void) = ^{
        for (NSDictionary *i in URLs) {
            NSURL *u = [i objectForKey:@"URL"];
            // Find similar (case insensitive compare) files to current URL
            NSArray *similar = [[_db library] filesWithSimilarURL:u]; 
            NSMutableArray *toMerge = [NSMutableArray array];
            BOOL merge = FALSE;
            for (NSNumber *j in similar) {
                // If similar file is equivalent to current URL, set them to be merged
                NSString *uStr = [[_db library] valueForFile:[j intValue] attribute:PRPathFileAttribute];
                if ([uStr isEqualToString:[u absoluteString]]) {
                    [toMerge addObject:j];
                    break;
                }
                NSURL *u2 = [NSURL URLWithString:uStr];
                if ([[NSFileManager defaultManager] itemAtURL:u equalsItemAtURL:u2]) {
                    merge = TRUE;
                    [toMerge addObject:j];
                }
            }
            if (merge) {
                [didRemove addIndexes:[self mergeFiles:toMerge newURL:u]];
            }
            // If no existing file, add
            NSInteger f = [[[_db library] filesWithValue:[u absoluteString] forAttribute:PRPathFileAttribute] firstIndex];
            if (f == NSNotFound) {
                [toAdd addObject:u];
                continue;
            }
            // If existing file and last modified or size modified, update
            NSNumber *size = [i objectForKey:@"size"];
            NSString *last = [[i objectForKey:@"lastModified"] description];
            NSNumber *size2 = [[_db library] valueForFile:f attribute:PRSizeFileAttribute];
            NSString *last2 = [[_db library] valueForFile:f attribute:PRLastModifiedFileAttribute];
            if ([size isEqualToNumber:size2] && [last isEqualToString:last2]) {
                [self setFileExists:f];
                continue;
            }
            [toUpdate addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:f], @"file", 
                                 u, @"URL", nil]];
        }
        // post notification for merged files
        if ([didRemove count] > 0) {
            if ([didRemove containsIndex:[[_core now] currentFile]]) {
                [[_core now] stop];
            }
            [[NSNotificationCenter defaultCenter] postLibraryChanged];
            [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[[_core now] currentPlaylist]];
        }
    };
    [[NSOperationQueue mainQueue] addBlockAndWait:blk];
    [self addURLs:toAdd];
    [self updateFiles:toUpdate];
    [p drain];
}

- (NSIndexSet *)mergeFiles:(NSArray *)files newURL:(NSURL *)URL
{
    // remove all but the first index
    NSMutableIndexSet *toRemove = [NSMutableIndexSet indexSet];
    for (int i = 0; i < [files count]; i++) {
        if (i == 0) {continue;}
        [self setFileExists:[[files objectAtIndex:i] intValue]];
        [toRemove addIndex:[[files objectAtIndex:i] intValue]];
    }
    if ([toRemove count] > 0) {
        [[_db library] removeFiles:toRemove];
    }
    // update path of first file and set to be updated
    PRFile f = [[files objectAtIndex:0] intValue];
    [[_db library] setValue:[URL absoluteString] forFile:f attribute:PRPathFileAttribute];
    [[_db library] setValue:[[NSDate distantPast] description] forFile:f attribute:PRLastModifiedFileAttribute];
    return toRemove;
}

- (void)addURLs:(NSArray *)URLs
{
    [[_db albumArtController] clearTempArt];
    // Get info for URLs
    NSMutableArray *infoArray = [NSMutableArray array];
    for (int i = 0; i < [URLs count]; i++) {
        NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
        PRTagEditor *te = [PRTagEditor tagEditorForURL:[URLs objectAtIndex:i]];
        if (!te) {continue;}
        NSMutableDictionary *info = [te info];
        [[info objectForKey:@"attr"] setObject:[[NSDate date] description] forKey:[NSNumber numberWithInt:PRDateAddedFileAttribute]];
        if ([info objectForKey:@"art"]) {
            int tempArt = [[_db albumArtController] saveTempArt:[info objectForKey:@"art"]];
            [info setObject:[NSNumber numberWithInt:tempArt] forKey:@"tempart"];
            [info removeObjectForKey:@"art"]; 
        }
        [infoArray addObject:info];
        [p drain];
    }
    void (^blk)(void) = ^{
        [_db begin];
        for (NSMutableDictionary *i in infoArray) {
            // If file exists with same checksum and size update path
            NSDictionary *attr = [i objectForKey:@"attr"];
            BOOL move = FALSE;
            NSString *str = @"SELECT file_id, path FROM library WHERE checkSum = ?1 AND size = ?2";
            NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [attr objectForKey:[NSNumber numberWithInt:PRCheckSumFileAttribute]], [NSNumber numberWithInt:1], 
                                 [attr objectForKey:[NSNumber numberWithInt:PRSizeFileAttribute]], [NSNumber numberWithInt:2], nil];
            NSArray *col = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:PRColumnString], nil];
            NSArray *rlt = [_db execute:str bindings:bnd columns:col];
            for (NSArray *j in rlt) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:[[NSURL URLWithString:[j objectAtIndex:1]] path]]) {
                    move = TRUE;
                    [[_db library] setValue:[attr objectForKey:[NSNumber numberWithInt:PRPathFileAttribute]] forFile:[[j objectAtIndex:0] intValue] attribute:PRPathFileAttribute];
                    [self setFileExists:[[j objectAtIndex:0] intValue]];
                    break;
                }
            }
            // Add file if doesnt exist
            if (!move) {
                PRFile file = [[_db library] addFileWithAttributes:[i objectForKey:@"attr"]];
                [i setObject:[NSNumber numberWithInt:file] forKey:@"file"];
            }
        }
        [_db commit];
        // post notification
        if ([infoArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postLibraryChanged];
        }
    };
    [[NSOperationQueue mainQueue] addBlockAndWait:blk];
    // set artwork for files
    for (NSDictionary *i in infoArray) {
        if ([i objectForKey:@"tempart"] && [i objectForKey:@"file"]) {
            [[_db albumArtController] setTempArt:[[i objectForKey:@"tempart"] intValue] forFile:[[i objectForKey:@"file"] intValue]];
        }
    }
}

- (void)updateFiles:(NSArray *)files // array of dictionaries with file and corresponding url
{
    [[_db albumArtController] clearTempArt];
    // get updated attributes and files to remove
    NSMutableArray *toRemove = [NSMutableArray array];
    NSMutableArray *infoArray = [NSMutableArray array];
    NSMutableIndexSet *updated = [NSMutableIndexSet indexSet];
    for (NSDictionary *i in files) {
        NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
        PRTagEditor *te = [PRTagEditor tagEditorForURL:[i objectForKey:@"URL"]];
        if (te) {
            NSMutableDictionary *info = [te info];
            [info setObject:[i objectForKey:@"file"] forKey:@"file"];
            if ([info objectForKey:@"art"]) {
                int tempArt = [[_db albumArtController] saveTempArt:[info objectForKey:@"art"]];
                [info setObject:[NSNumber numberWithInt:tempArt] forKey:@"tempart"];
                [info removeObjectForKey:@"art"]; 
            }
            [infoArray addObject:info];
            [updated addIndex:[[i objectForKey:@"file"] intValue]];
        } else {
            [toRemove addObject:[i objectForKey:@"URL"]];
        }
        [p drain];
    }
    void (^blk)(void) = ^{
        [_db begin];
        // set updated attributes
        for (NSMutableDictionary *i in infoArray) {
            [[_db library] setAttributes:[i objectForKey:@"attr"] forFile:[[i objectForKey:@"file"] intValue]];
            [self setFileExists:[[i objectForKey:@"file"] intValue]];
        }
        [_db commit];
        // post notifications
        if ([infoArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postFilesChanged:updated];
        }
    };
    [[NSOperationQueue mainQueue] addBlockAndWait:blk];
    // set art
    for (NSDictionary *i in infoArray) {
        if ([i objectForKey:@"file"]) {
            PRFile file = [[i objectForKey:@"file"] intValue];
            if ([i objectForKey:@"tempart"]) {
                [[_db albumArtController] setTempArt:[[i objectForKey:@"tempart"] intValue] forFile:file];
            } else {
                [[_db albumArtController] clearAlbumArtForFile2:file];
            }
        }
    }
}

- (void)removeFiles:(NSArray *)files
{
    NSMutableIndexSet *toRemove = [NSMutableIndexSet indexSet];
    for (NSNumber *i in files) {
        [toRemove addIndex:[i intValue]];
    }
    if ([toRemove count] == 0) {
        return;
    }
    void (^blk)(void) = ^{        
        if ([toRemove containsIndex:[[_core now] currentFile]]) {
            [[_core now] stop];
        }
        [[_db library] removeFiles:toRemove];
        [[NSNotificationCenter defaultCenter] postLibraryChanged];
        [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[[_core now] currentPlaylist]];
    };
    [[NSOperationQueue mainQueue] addBlockAndWait:blk];
}

// ========================================
// Misc
// ========================================

- (void)setFileExists:(PRFile)file
{
    NSString *stm = @"UPDATE tmp_tbl_monitored_files SET exist = 1 WHERE file_id = ?1";
    NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    [_db execute:stm bindings:bnd columns:nil];
}

@end
