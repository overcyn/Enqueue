#import "PRImportOperation.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRCore.h"
#import "PROperationProgress.h"
#import "PRProgressManager.h"
#import "PRPlayer.h"
#import "NSIndexSet+Extensions.h"
#import "PRDirectoryEnumerator.h"
#import "NSEnumerator+Extensions.h"
#import "PRAlbumArtController.h"


@implementation PRImportOperation

#pragma mark - Action

- (void)main {
    NSLog(@"begin import");
    @autoreleasepool {
        PROperationProgress *task = [PROperationProgress task];
        [task setTitle:@"Adding Files..."];
        [[_core taskManager] addTask:task];
        
//    // if single m3u file
//    if ([_URLs count] == 1 && [[[[_URLs objectAtIndex:0] path] pathExtension] caseInsensitiveCompare:@"m3u"] == NSOrderedSame) {
//        [self addM3UFile:[_URLs objectAtIndex:0] depth:0];
//        goto end;
//    }
        
        // Filter and add/update files
        NSArray *files;
        PRDirectoryEnumerator *dirEnum = [PRDirectoryEnumerator enumeratorWithURLs:_URLs];
        int filesPerTransaction = 50;
        while ((files = [dirEnum nextXObjects:filesPerTransaction])) {
            [task setPercent:(int)([dirEnum progress] * 90)];
            [self filterURLs:files];
            if ([task shouldCancel]) {
                goto end;
            }
            if (filesPerTransaction < 1000) {
                filesPerTransaction += 200;
            }
        }
        
end:;
        [[_core taskManager] removeTask:task];
    }
    NSLog(@"end import");
}

//- (void)addM3UFile:(NSURL *)URL depth:(int)depth
//{
//    NSURL *baseURL = [NSURL fileURLWithPath:[[URL path] stringByDeletingLastPathComponent]];
//    
//    NSStringEncoding stringEncoding;
//    NSString *contents = [NSString stringWithContentsOfURL:URL usedEncoding:&stringEncoding error:nil];
//    if (!contents) {
//        return;
//    }
//    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//    NSMutableArray *trimmedLines = [NSMutableArray array];
//    for (NSString *i in lines) {
//        NSString *trimmedLine = [i stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        if ([trimmedLine length] != 0) {
//            [trimmedLines addObject:trimmedLine];
//        }
//    }
//    
//    if (![[trimmedLines objectAtIndex:0] hasPrefix:@"#EXTM3U"]) {
//        return;
//    }
//    for (NSString *i in trimmedLines) {
//        if ([i hasPrefix:@"#EXTINF"] || [i hasPrefix:@"#EXTM3U"] || [i hasPrefix:@"http://"]) {
//            continue;
//        }
//        NSURL *URL2 = [NSURL URLWithString:[i stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
//                             relativeToURL:baseURL];
//        if (!URL2) {
//            continue;
//        }
//        
//        if ([[[URL2 path] pathExtension] caseInsensitiveCompare:@"m3u"] == NSOrderedSame) {
//            if (depth < 5) {
//                [self addM3UFile:URL2 depth:depth+1];
//            }
//        } else {
////            [self addFiles:@[URL2]];
//        }
//    }
//}

#pragma mark - Misc

- (void)setFileExists:(PRItemID *)file {
    
}

@end
