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

- (id)initWithURLs:(NSArray *)URLs_ recursive:(BOOL)recursive_ core:(PRCore *)core_
{
    self = [super init];
	if (self) {
        core = core_;
        _db = [core db2];
		URLs = [URLs_ retain];
        URLsToPlay = [[NSMutableArray alloc] init];
        background = FALSE;
        _tempFileCount = 0;
	}
	return self;
}

- (void)dealloc
{
    [URLs release];
    [super dealloc];
}

// ========================================
// Accessors
// ========================================

@synthesize background;
@synthesize playWhenDone;
@synthesize completionInvocation;
@synthesize completionInvocation2;

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
    [[core taskManager] addTask:task];
    [[_db library] clearTempFiles];
        
    BOOL playURLs = TRUE;
    if ([URLs count] == 1 && [[[[URLs objectAtIndex:0] path] pathExtension] caseInsensitiveCompare:@"m3u"] == NSOrderedSame) {
        [self addM3UFile:[URLs objectAtIndex:0] depth:0];
        goto end;
    }
    
    // recurse through URLs adding files
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    for (NSURL *URL in URLs) {
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
    
end:;
    [[_db library] mergeTempFilesToLibrary];
    
    if (playWhenDone && playURLs) {
        NSMutableArray *filesToPlay = [NSMutableArray array];
        for (NSURL *i in URLsToPlay) {
            NSIndexSet *files;
            [[_db library] files:&files withValue:[i absoluteString] forAttribute:PRPathFileAttribute _error:nil];
            if ([files count] == 1) {
                [filesToPlay addObject:[NSNumber numberWithInt:[files firstIndex]]];
            }
        }
        [[core now] performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:TRUE];
        [[_db playlists] clearPlaylist:[[core now] currentPlaylist]];
        for (NSNumber *i in filesToPlay) {
            [[_db playlists] appendFile:[i intValue] toPlaylist:[[core now] currentPlaylist]];
        }
        [[core now] performSelectorOnMainThread:@selector(postNotificationForCurrentPlaylist) withObject:nil waitUntilDone:TRUE];
        [[core now] performSelectorOnMainThread:@selector(playPause) withObject:nil waitUntilDone:TRUE];
    }
    
	NSNotification *notification = [NSNotification notificationWithName:PRLibraryDidChangeNotification 
                                                                 object:self 
                                                               userInfo:nil];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
														   withObject:notification 
														waitUntilDone:TRUE];

    [[core taskManager] removeTask:task];
    [pool drain];
    NSLog(@"Finished Open Operation");
}

- (void)addFile:(NSURL *)URL
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // File exists?
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
    NSIndexSet *files;
    [[_db library] files:&files withPath:[URL absoluteString] caseSensitive:[URL caseSensitive] _error:nil];
    PRFile existingFile;
    if ([files count] > 0) {
        existingFile = [files firstIndex];
    } else {
        existingFile = 0;
    }
    
    // existing file?
    if (existingFile != 0) {
        NSString *lastModified = [[PRTagEditor lastModifiedForFileAtPath:[URL path]] description];
        NSString *prevLastModified;
        [[_db library] value:&prevLastModified forFile:existingFile attribute:PRLastModifiedFileAttribute _error:nil];
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
        NSIndexSet *prevFiles;
        [[_db library] files:&prevFiles withValue:size forAttribute:PRSizeFileAttribute _error:nil];
        if ([prevFiles count] > 0) {
            NSData *checkSum = [PRTagEditor checkSumForFileAtPath:[URL path]];
            if (!checkSum) {
                goto cleanup;
            }
            NSUInteger i = [prevFiles firstIndex];
            while (i != NSNotFound) {
                NSString *prevURLString;
                [[_db library] value:&prevURLString forFile:i attribute:PRPathFileAttribute _error:nil];
                NSData *prevCheckSum;
                [[_db library] value:&prevCheckSum forFile:i attribute:PRCheckSumFileAttribute _error:nil];
                NSString *prevPath = [[NSURL URLWithString:prevURLString] path];
                BOOL prevFileExists = [[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:prevPath isDirectory:nil];
                if (!prevFileExists && [prevCheckSum isEqualToData:checkSum]) {
                    [[_db library] setValue:[URL absoluteString] forFile:i attribute:PRPathFileAttribute _error:nil];
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