#import "PRFullRescanOperation.h"
#import "PRTask.h"
#import "PRCore.h"
#import "PRTaskManager.h"
#import "PRDb.h"
#import "PRAlbumArtController.h"
#import "PRTagger.h"
#import "PRFileInfo.h"

@implementation PRFullRescanOperation

// ========================================
// Initialization

+ (id)operationWithCore:(PRCore *)core
{
    return [[[PRFullRescanOperation alloc] initWithCore:core] autorelease];
}

- (id)initWithCore:(PRCore *)core
{
    if (!(self = [super init])) {return nil;}
    _core = core;
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

// ========================================
// Action

- (void)main
{
    NSLog(@"begin fullrescan");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PRTask *task = [PRTask task];
    [task setTitle:@"Rescanning Library..."];
    [[_core taskManager] addTask:task];
    
    int count = [[[[[_core db] execute:@"SELECT count(file_id) FROM library" 
                              bindings:nil 
                               columns:[NSArray arrayWithObject:PRColInteger]] objectAtIndex:0] objectAtIndex:0] intValue];
    if (count == 0) {
        count = 1;
    }
    
    int offset = 0;
    while (TRUE) {
        [task setPercent:((float)offset*90)/count];
        
        __block NSArray *rlt;
        [[NSOperationQueue mainQueue] addBlockAndWait:^{
            rlt = [[_core db] execute:@"SELECT file_id, path FROM library ORDER BY file_id LIMIT 200 OFFSET ?1"
                             bindings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:offset], [NSNumber numberWithInt:1], nil] 
                              columns:[NSArray arrayWithObjects:PRColInteger, PRColString, nil]];
            [rlt retain];
        }];
        [rlt autorelease];
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
    [pool drain];
    NSLog(@"end fullrescan");
}

- (void)updateFiles:(NSArray *)array
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[[_core db] albumArtController] clearTempArt];
    // get updated attributes
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSArray *i in array) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        PRFileInfo *info = [PRTagger infoForURL:[NSURL URLWithString:[i objectAtIndex:1]]];
        if (!info) {
            [pool drain]; continue;
        }
        [info setFile:[[i objectAtIndex:0] intValue]];
        if ([info art]) {
            [info setTempArt:[[[_core db] albumArtController] saveTempArt:[info art]]];
            [info setArt:nil];
        }
        [infoArray addObject:info];
        [pool drain];
    }
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [[_core db] begin];
        // set updated attributes
        NSMutableIndexSet *updated = [NSMutableIndexSet indexSet];
        for (PRFileInfo *i in infoArray) {
            [[[_core db] library] setAttrs:[i attributes] forItem:[NSNumber numberWithInt:[i file]]];
            [updated addIndex:[i file]];
        }
        [[_core db] commit];
        // post notifications
        if ([infoArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postFilesChanged:updated];
        }
    }];
    // set art
    for (PRFileInfo *i in infoArray) {
        if ([i file] == 0) {continue;}
        if ([i tempArt] != 0) {
            [[[_core db] albumArtController] setTempArt:[i tempArt] forFile:[i file]];
        } else {
            [[[_core db] albumArtController] clearAlbumArtForFile2:[i file]];
        }
    }    [pool drain];
}

@end
