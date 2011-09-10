#import "PRImportOperation.h"
#import "PRLibrary.h"
#import "PRTagEditor.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRCore.h"
#import "PRTask.h"
#import "PRTaskManager.h"
#import "PRNowPlayingController.h"
#import "NSURL+Extensions.h"


@implementation PRImportOperation

// ========================================
// Initialization
// ========================================

+ (id)operationWithURLs:(NSArray *)URLs core:(PRCore *)core
{
    return [[[PRImportOperation alloc] initWithURLs:URLs core:core] autorelease];
}

- (id)initWithURLs:(NSArray *)URLs core:(PRCore *)core
{
    if (!(self = [super init])) {return nil;}
    _core = core;
    _db = [_core db2];
    _URLs = [URLs retain];
    URLsToPlay = [[NSMutableArray array] retain];
    _removeMissing = FALSE;
    background = FALSE;
    _tempFileCount = 0;
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

@synthesize background;
@synthesize playWhenDone;
@synthesize completionInvocation;
@synthesize completionInvocation2;
@synthesize removeMissing = _removeMissing;

// ========================================
// Action
// ========================================

- (void)main
{
    NSLog(@"Begin Open Operation");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    task = [[[PRTask alloc] init] autorelease];
    if (background) {
        [task setTitle:@"Updating Library..."];
    } else {
        [task setTitle:@"Adding Files..."];
    }
    [task setBackground:background];
    [[_core taskManager] addTask:task];
    [[_db library] clearTempFiles];
    
    BOOL playURLs = TRUE;
    if ([_URLs count] == 1 && [[[[_URLs objectAtIndex:0] path] pathExtension] caseInsensitiveCompare:@"m3u"] == NSOrderedSame) {
        [self addM3UFile:[_URLs objectAtIndex:0] depth:0];
        goto end;
    }
    
//    // Monitored Folders. Assume case-insensitive. Check again before removing.
//    if (_removeMissing) {
//        [_db execute:@"PRAGMA case_sensitive_like = TRUE"];
//        [_db execute:@"CREATE TEMP TABLE temp_tbl_files_to_remove (path STRING NOT NULL DEFAULT '', contains INT NOT NULL DEFAULT 0)"];
//        NSMutableString *string = [NSMutableString stringWithString:@"INSERT into temp_tbl_files_to_remove (path) VALUES SELECT path FROM library WHERE "];
//        NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
//        int bindingIndex = 1;
//        for (NSURL *i in URLs) {
//            [string appendFormat:@"path LIKE ?1 ESCAPE '\\' "];
//            NSMutableString *escapedPath = [NSMutableString stringWithString:[i path]];
//            [escapedPath replaceOccurrencesOfString:@"%%" withString:@"\\%%" options:NSLiteralSearch range:NSMakeRange(0, [escapedPath length])];
//            [escapedPath replaceOccurrencesOfString:@"_" withString:@"\\_" options:NSLiteralSearch range:NSMakeRange(0, [escapedPath length])];
//            [escapedPath appendFormat:@"%%"];
//            [bindings setObject:escapedPath forKey:[NSNumber numberWithInt:bindingIndex]];
//            bindingIndex++;
//        }
//        [_db execute:string bindings:bindings columns:nil];
//        [_db execute:@"PRAGMA case_sensitive_like = FALSE"];
//    }
    
    // recurse through URLs adding files
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    for (NSURL *URL in _URLs) {
        BOOL isDir;
        NSString *path = [URL path];
        [fileManager fileExistsAtPath:path isDirectory:&isDir];
        if (isDir) {
            playURLs = FALSE;
            NSString *relativePath;
            NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:path];
            while ((relativePath = [directoryEnumerator nextObject])) {
                NSURL *URL = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:relativePath]];
                [self addFile:URL];
                if ([task shouldCancel]) {
                    goto end;
                }
            }
        } else {
            NSURL *URL = [NSURL fileURLWithPath:path];
            [URLsToPlay addObject:URL];
            [self addFile:URL];
            
            if ([task shouldCancel]) {
                goto end;
            }
        }
    }

    [completionInvocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:TRUE];
    [completionInvocation2 performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:TRUE];
    
//    // Remove missing files
//    NSString *string = @"SELECT path FROM temp_tbl_files_to_remove WHERE contains == 0";
//    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
//    NSArray *results = [_db execute:string bindings:nil columns:columns];
//    NSMutableArray *pathsToRemove = [NSMutableArray array];
//    for (NSArray *i in results) {
//        NSString *path = [i objectAtIndex:0];
//        BOOL exists = [fileManager fileExistsAtPath:path isDirectory:nil];
//        if (!exists) {
//            [pathsToRemove addObject:path];
//        }
//    }
//    for (NSString *i in pathsToRemove) {
//        string = @"DELETE FROM library WHERE path = ?1";
//        NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                  i, [NSNumber numberWithInt:1], nil];
//        [_db execute:string bindings:bindings columns:nil];
//    }
    
end:;
//    [_db execute:@"DROP TABLE IF EXISTS temp_tbl_files_to_remove"];
    [[_db library] mergeTempFilesToLibrary];
    
    if (playWhenDone && playURLs) {
        NSMutableArray *filesToPlay = [NSMutableArray array];
        for (NSURL *i in URLsToPlay) {
            NSIndexSet *files = [[_db library] filesWithValue:[i absoluteString] forAttribute:PRPathFileAttribute];
            if ([files count] == 1) {
                [filesToPlay addObject:[NSNumber numberWithInt:[files firstIndex]]];
            }
        }
        [[_core now] performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:TRUE];
        [[_db playlists] clearPlaylist:[[_core now] currentPlaylist]];
        for (NSNumber *i in filesToPlay) {
            [[_db playlists] appendFile:[i intValue] toPlaylist:[[_core now] currentPlaylist]];
        }
        [[_core now] performSelectorOnMainThread:@selector(postNotificationForCurrentPlaylist) withObject:nil waitUntilDone:TRUE];
        [[_core now] performSelectorOnMainThread:@selector(playPause) withObject:nil waitUntilDone:TRUE];
    }
    
	NSNotification *notification = [NSNotification notificationWithName:PRLibraryDidChangeNotification 
                                                                 object:self 
                                                               userInfo:nil];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
														   withObject:notification 
														waitUntilDone:TRUE];

    [[_core taskManager] removeTask:task];
    [pool drain];
    NSLog(@"Finished Open Operation");
}

- (void)addFile:(NSURL *)URL
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // File exists? isDirectory?
    if (!URL) {
        goto cleanup;
    }
    BOOL isDir;
    BOOL fileExists = [[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:[URL path] isDirectory:&isDir];
    if (isDir || !fileExists) {
        if (!background) {
            [task performSelector:@selector(setTitle:) 
                         onThread:[NSThread mainThread]
                       withObject:[NSString stringWithFormat:@"Scanning Folder: %@", [[URL path] lastPathComponent]] 
                    waitUntilDone:FALSE];
        }
        goto cleanup;
    }
    
    // Previous File?
    BOOL caseSensitive = [URL caseSensitive];
    NSIndexSet *files = [[_db library] filesWithPath:[URL absoluteString] caseSensitive:caseSensitive];
    PRFile existingFile;
    if ([files count] > 0) {
        existingFile = [files firstIndex];
    } else {
        existingFile = 0;
    }
    
    // existing file?
    if (existingFile != 0) {
//        NSString *string = @"UPDATE temp_tbl_files_to_remove SET contains = 1 WHERE path = ?1";
//        NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:[URL absoluteString], [NSNumber numberWithInt:1], nil];
//        [_db execute:string bindings:bindings columns:nil];
        
        NSString *lastModified = [[PRTagEditor lastModifiedForFileAtPath:[URL path]] description];
        NSString *prevLastModified = [[_db library] valueForFile:existingFile attribute:PRLastModifiedFileAttribute];
        if ([lastModified isEqualToString:prevLastModified]) {
            goto cleanup;
        }
        
//        NSNumber *size = [PRTagEditor sizeForFileAtPath:[URL path]];
//        NSNumber *prevSize;
//        [[_db library] value:&prevSize forFile:existingFile attribute:PRSizeFileAttribute _error:nil];
//        NSData *checkSum = [PRTagEditor checkSumForFileAtPath:[URL path]];
//        NSData *prevCheckSum;
//        [[_db library] value:&prevCheckSum forFile:existingFile attribute:PRCheckSumFileAttribute _error:nil];
//        if ([checkSum isEqualToData:prevCheckSum] && [size isEqualToNumber:prevSize]) {
//            goto cleanup;
//        }
        
        PRTagEditor *tagEditor = [[[PRTagEditor alloc] initWithFile:existingFile db:_db] autorelease];
        [tagEditor updateTags];
    } else {
        // valid file?
        PRTagEditor *tagEditor = [[[PRTagEditor alloc] initWithURL:URL db:_db] autorelease];
        if (!tagEditor) {
            goto cleanup;
        }
        
        // Is equal to previous file?
        NSNumber *size = [PRTagEditor sizeForFileAtPath:[URL path]];
        if (!size) {
            goto cleanup;
        }
        NSIndexSet *prevFiles = [[_db library] filesWithValue:size forAttribute:PRSizeFileAttribute];
        if ([prevFiles count] > 0) {
            NSData *checkSum = [PRTagEditor checkSumForFileAtPath:[URL path]];
            if (!checkSum) {
                goto cleanup;
            }
            NSUInteger i = [prevFiles firstIndex];
            while (i != NSNotFound) {
                NSString *prevURLString = [[_db library] valueForFile:i attribute:PRPathFileAttribute];
                NSData *prevCheckSum = [[_db library] valueForFile:i attribute:PRCheckSumFileAttribute];
                NSString *prevPath = [[NSURL URLWithString:prevURLString] path];
                BOOL prevFileExists = [[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:prevPath isDirectory:nil];
                if (!prevFileExists && [prevCheckSum isEqualToData:checkSum]) {
                    [[_db library] setValue:[URL absoluteString] forFile:i attribute:PRPathFileAttribute];
                    goto cleanup;
                }
                i = [prevFiles indexGreaterThanIndex:i];
            }
        }
//        // add file
//        if (!background) {
//            [task performSelector:@selector(setTitle:) 
//                         onThread:[NSThread mainThread]
//                       withObject:[NSString stringWithFormat:@"Adding File: %@", [[URL path] lastPathComponent]] 
//                    waitUntilDone:FALSE];
//        }
        
        PRFile tempFile = [[_db library] addTempFileWithPath:[URL absoluteString]];
        [tagEditor setFile:tempFile];
        [tagEditor setTempFile:TRUE];
        [tagEditor updateTags];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [[NSDate date] description], [NSNumber numberWithInt:PRDateAddedFileAttribute], nil];
        [[_db library] setAttributes:attributes forTempFile:tempFile];
        
        _tempFileCount += 1;
        if (_tempFileCount > 500) {
            [[_db library] mergeTempFilesToLibrary];
            NSNotification *notification = [NSNotification notificationWithName:PRLibraryDidChangeNotification 
                                                                         object:self 
                                                                       userInfo:nil];
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
                                                                   withObject:notification 
                                                                waitUntilDone:TRUE];
            _tempFileCount = 0;
        }
    }
cleanup:;
    [pool drain];
}

- (void)addM3UFile:(NSURL *)URL depth:(int)depth
{
    if (!URL) {
        return;
    }
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[URL path] stringByDeletingLastPathComponent]];
    
    NSStringEncoding stringEncoding;
    NSString *contents = [NSString stringWithContentsOfURL:URL usedEncoding:&stringEncoding error:nil];
    if (!contents) {
        return;
    }
    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *trimmedLines = [NSMutableArray array];
    for (NSString *i in lines) {
        NSString *trimmedLine = [i stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmedLine length] != 0) {
            [trimmedLines addObject:trimmedLine];
        }
    }
    
    if (![[trimmedLines objectAtIndex:0] hasPrefix:@"#EXTM3U"]) {
        return;
    }
    for (NSString *i in trimmedLines) {
        if ([i hasPrefix:@"#EXTINF"] || [i hasPrefix:@"#EXTM3U"] || [i hasPrefix:@"http://"]) {
            continue;
        }
        NSURL *URL2 = [NSURL URLWithString:[i stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
                             relativeToURL:baseURL];
        if (!URL2) {
            continue;
        }
        
        if ([[[URL2 path] pathExtension] caseInsensitiveCompare:@"m3u"] == NSOrderedSame) {
            if (depth < 5) {
                [self addM3UFile:URL2 depth:depth+1];
            }
        } else {
            [self addFile:URL2];
            [URLsToPlay addObject:URL2];
        }
    }
}

@end