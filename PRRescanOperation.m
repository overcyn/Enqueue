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
#import "PRFolderMonitor.h"


@implementation PRRescanOperation

// ========================================
// Initialization

+ (id)operationWithURLs:(NSArray *)URLs core:(PRCore *)core {
    return [[[PRRescanOperation alloc] initWithURLs:URLs core:core] autorelease];
}

- (id)initWithURLs:(NSArray *)URLs core:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _db = [_core db];
    _URLs = [URLs retain];
    _eventId = 0;
    _monitor = FALSE;
	return self;
}

- (void)dealloc {
    [_URLs release];
    [super dealloc];
}

// ========================================
// Accessors

@synthesize eventId = _eventId, monitor = _monitor;

// ========================================
// Action

- (void)main {
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
    NSMutableArray *toRemove = [NSMutableArray array];
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        NSArray *rlt = [_db execute:@"SELECT file_id FROM tmp_tbl_monitored_files WHERE exist = 0"
                           bindings:nil 
                            columns:[NSArray arrayWithObjects:PRColInteger, nil]];
        for (NSArray *i in rlt) {
            [toRemove addObject:[i objectAtIndex:0]];
        }
    }];
    [self removeFiles:toRemove];
    
    // Update lastEventStreamEventId
    [task setPercent:99];
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [[PRUserDefaults userDefaults] setLastEventStreamEventId:_eventId];
        if (_monitor) {
            [[_core folderMonitor] monitor2];
        }
    }];

end:;
    [[_core taskManager] removeTask:task];
    [pool drain];
    NSLog(@"end folderrescan");
}

// Array of dictionaries containing NSURL, size, lastmodified, caseSensitive
- (void)filterURLs:(NSArray *)URLs {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray *toUpdate = [NSMutableArray array];
    NSMutableArray *toAdd = [NSMutableArray array];
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        for (NSDictionary *i in URLs) {
            NSURL *URL = [i objectForKey:@"URL"];
            // Find similar (case insensitive compare) files to current URL and merge them.
            [self mergeSimilar:URL];
            // Find existing files. Add if none. Update if Size or LastModified changed.
            NSArray *array = [[_db library] itemsWithValue:[URL absoluteString] forAttr:PRItemAttrPath];
            if ([array count] == 0) {
                [toAdd addObject:URL];
            } else {
                PRItem *item = [array objectAtIndex:0];
                NSNumber *size = [i objectForKey:@"size"];
                NSString *last = [[i objectForKey:@"lastModified"] description];
                NSNumber *size2 = [[_db library] valueForItem:item attr:PRItemAttrSize];
                NSString *last2 = [[_db library] valueForItem:item attr:PRItemAttrLastModified];
                if ([size isEqualToNumber:size2] && [last isEqualToString:last2]) {
                    [self setFileExists:[item intValue]];
                } else {
                    [toUpdate addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                         item, @"file", 
                                         URL, @"URL", nil]];
                }
            }
        }
    }];
    [self addURLs:toAdd];
    [self updateFiles:toUpdate];
    [pool drain];
}

- (void)mergeSimilar:(NSURL *)URL {
    NSArray *similar = [[_db library] itemsWithSimilarURL:URL]; 
    NSMutableArray *toMerge = [NSMutableArray array];
    BOOL exact = FALSE;
    // Find all files at URL
    for (NSNumber *i in similar) {
        NSString *URLString = [[_db library] valueForItem:i attr:PRItemAttrPath];
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
        [[_db library] setValue:[URL absoluteString] forItem:[toMerge objectAtIndex:0] attr:PRItemAttrPath];
    }
}

// Array of NSURLs to add
- (void)addURLs:(NSArray *)URLs {
    [[_db albumArtController] clearTempArtwork];
    // Get info for URLs
    NSMutableArray *infoArray = [NSMutableArray array];
    for (int i = 0; i < [URLs count]; i++) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        PRFileInfo *info = [PRTagger infoForURL:[URLs objectAtIndex:i]];
        if (!info) {
            [pool drain]; continue;
        }
        [[info attributes] setObject:[[NSDate date] description] forKey:PRItemAttrDateAdded];
        if ([info art]) {
            [info setTempArt:[[_db albumArtController] saveTempArtwork:[info art]]];
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
                                         [[i attributes] objectForKey:PRItemAttrCheckSum], [NSNumber numberWithInt:1], 
                                         [[i attributes] objectForKey:PRItemAttrSize], [NSNumber numberWithInt:2], nil]
                                columns:[NSArray arrayWithObjects:PRColInteger, PRColString, nil]];
            PRFile moved = 0;
            for (NSArray *j in rlt) {
                if (![[NSFileManager defaultManager] fileExistsAtPath:[[NSURL URLWithString:[j objectAtIndex:1]] path]]) {
                    moved = [[j objectAtIndex:0] intValue];
                }
            }
            // Add file if doesnt exist. Update path if it does
            if (moved == 0) {
                PRFile file = [[[_db library] addItemWithAttrs:[i attributes]] intValue];
                [i setFile:file];
            } else {
                [[_db library] setValue:[[i attributes] objectForKey:PRItemAttrPath] forItem:[NSNumber numberWithInt:moved] attr:PRItemAttrPath];
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
            [[_db albumArtController] setTempArtwork:[i tempArt] forItem:[PRItem numberWithInt:[i file]]];
        }
    }
}

// Array of NSDictionary with file (as NSNumber) and corresponding NSURL
- (void)updateFiles:(NSArray *)files {
    [[_db albumArtController] clearTempArtwork];
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
            [info setTempArt:[[_db albumArtController] saveTempArtwork:[info art]]];
            [info setArt:nil];
        }
        [infoArray addObject:info];
        [pool drain];
    }
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [_db begin];
        // set updated attributes
        NSMutableArray *updated = [NSMutableArray array];
        for (PRFileInfo *i in infoArray) {
            [[_db library] setAttrs:[i attributes] forItem:[NSNumber numberWithInt:[i file]]];
            [self setFileExists:[i file]];
            [updated addObject:[PRItem numberWithInt:[i file]]];
        }
        [_db commit];
        // post notifications
        if ([infoArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postItemsChanged:updated];
        }
    }];
    // set art
    for (PRFileInfo *i in infoArray) {
        if ([i file] == 0) {continue;}
		[[_db albumArtController] setTempArtwork:[i tempArt] forItem:[PRItem numberWithInt:[i file]]];
    }
}

- (void)removeFiles:(NSArray *)items {
    if ([items count] == 0) {
        return;
    }
    [[NSOperationQueue mainQueue] addBlockAndWait:^{        
        if ([items containsObject:[[_core now] currentItem]]) {
            [[_core now] stop];
        }
        [[_db library] removeItems:items];
        [[NSNotificationCenter defaultCenter] postLibraryChanged];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[[_core now] currentList]];
    }];
}

// ========================================
// Misc

// Should only be called on the main thread
- (void)setFileExists:(PRFile)file {
    [_db execute:@"UPDATE tmp_tbl_monitored_files SET exist = 1 WHERE file_id = ?1"
        bindings:[NSDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil]
         columns:nil];
}

@end
