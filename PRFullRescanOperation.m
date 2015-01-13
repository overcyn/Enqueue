#import "PRFullRescanOperation.h"
#import "PRPlaylists.h"
#import "NSNotificationCenter+Extensions.h"
#import "PROperationProgress.h"
#import "PRCore.h"
#import "PRProgressManager.h"
#import "PRDb.h"
#import "PRAlbumArtController.h"
#import "PRTagger.h"
#import "PRFileInfo.h"

@implementation PRFullRescanOperation

#pragma mark - Initialization

+ (id)operationWithCore:(PRCore *)core {
    return [[PRFullRescanOperation alloc] initWithCore:core];
}

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    return self;
}

#pragma mark - Action

- (void)main {
    NSLog(@"begin fullrescan");
    @autoreleasepool {
        PROperationProgress *task = [PROperationProgress task];
        [task setTitle:@"Rescanning Library..."];
        [[_core taskManager] addTask:task];
        
        int count = [[[[[_core db] execute:@"SELECT count(file_id) FROM library" bindings:nil columns:@[PRColInteger]] objectAtIndex:0] objectAtIndex:0] intValue];
        if (count == 0) {
            count = 1;
        }
        
        int offset = 0;
        while (YES) {
            [task setPercent:((float)offset*90)/count];
            
            __block NSArray *rlt;
            [[NSOperationQueue mainQueue] addBlockAndWait:^{
                rlt = [[_core db] execute:@"SELECT file_id, path FROM library ORDER BY file_id LIMIT 200 OFFSET ?1"
                                 bindings:@{@1:[NSNumber numberWithInt:offset]}
                                  columns:@[PRColInteger, PRColString]];
            }];
            if ([rlt count] == 0) {
                break;
            }
            [self updateFiles:rlt];
            offset += 200;
            if ([task shouldCancel]) {
                goto end;
            }
        }
        
end:;
        [[_core taskManager] removeTask:task];
    }
    NSLog(@"end fullrescan");
}

- (void)updateFiles:(NSArray *)array {
    @autoreleasepool {
        [[[_core db] albumArtController] clearTempArtwork];
        // get updated attributes
        NSMutableArray *infoArray = [NSMutableArray array];
        for (NSArray *i in array) {
            @autoreleasepool {
                PRFileInfo *info = [PRTagger infoForURL:[NSURL URLWithString:[i objectAtIndex:1]]];
                if (!info) {
                    continue;
                }
                [info setItem:[i objectAtIndex:0]];
                if ([info art]) {
                    [info setTempArt:[[[_core db] albumArtController] saveTempArtwork:[info art]]];
                    [info setArt:nil];
                }
                [infoArray addObject:info];
            }
        }
        [[NSOperationQueue mainQueue] addBlockAndWait:^{
            [[_core db] begin];
            // set updated attributes
            NSMutableArray *updated = [NSMutableArray array];
            for (PRFileInfo *i in infoArray) {
                [[[_core db] library] setAttrs:[i attributes] forItem:[i item]];
                [updated addObject:[i item]];
            }
            [[_core db] commit];
            // post notifications
            if ([infoArray count] > 0) {
                [[NSNotificationCenter defaultCenter] postItemsChanged:updated];
            }
        }];
        // set art
        for (PRFileInfo *i in infoArray) {
            if (![i item]) {continue;}
            [[[_core db] albumArtController] setTempArtwork:[i tempArt] forItem:[i item]];
        }
    }
}

@end
