#import "PRUpdate060Operation.h"
#import "PRTask.h"
#import "PRCore.h"
#import "PRTaskManager.h"
#import "PRDb.h"
#import "PRTagger.h"


@implementation PRUpdate060Operation

#pragma mark - Initialization

+ (id)operationWithCore:(PRCore *)core {
    return [[[PRUpdate060Operation alloc] initWithCore:core] autorelease];
}

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
	return self;
}

#pragma mark - Action

- (void)main {
    NSLog(@"begin update060");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PRTask *task = [PRTask task];
    [task setTitle:@"Updating Library..."];
    [[_core taskManager] addTask:task];
    
    int count = [[[[[_core db] execute:@"SELECT count(file_id) FROM library" 
                              bindings:nil 
                               columns:@[PRColInteger]] objectAtIndex:0] objectAtIndex:0] intValue];
    if (count == 0) {
        count = 1;
    }
    
    int offset = 0;
    while (TRUE) {
        [task setPercent:((float)offset*90)/count];
        
        __block NSArray *rlt;
        [[NSOperationQueue mainQueue] addBlockAndWait:^{
            rlt = [[_core db] execute:@"SELECT file_id, path FROM library ORDER BY file_id LIMIT 200 OFFSET ?1"
                             bindings:@{@1:[NSNumber numberWithInt:offset]}
                              columns:@[PRColInteger, PRColString]];
            [rlt retain];
        }];
        if ([rlt count] == 0) {
            break;
        }
        [self updateFiles:rlt];
        [rlt release];
        offset += 200;
        if ([task shouldCancel]) {
            goto end;
        }
    }
    
end:;
    [[_core taskManager] removeTask:task];
    [pool drain];
    NSLog(@"end update060");
}

- (void)updateFiles:(NSArray *)array {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableArray *infoArray = [NSMutableArray array];
    for (NSArray *i in array) {
        NSDictionary *tags = [PRTagger tagsForURL:[NSURL URLWithString:[i objectAtIndex:1]]];
        if (!tags || ([[tags objectForKey:PRItemAttrCompilation] intValue] == 0 &&
                      [[tags objectForKey:PRItemAttrLyrics] length] == 0)) {
            continue;
        }
        [infoArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              [i objectAtIndex:0], @"file",
                              [tags objectForKey:PRItemAttrCompilation], @"compilation",
                              [tags objectForKey:PRItemAttrLyrics], @"lyrics",
                              nil]];
    }
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [[_core db] begin];
        // set updated attributes
        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *i in infoArray) {
            [[[_core db] library] setValue:[i objectForKey:@"lyrics"] forItem:[i objectForKey:@"file"] attr:PRItemAttrLyrics];
            [[[_core db] library] setValue:[i objectForKey:@"compilation"] forItem:[i objectForKey:@"file"] attr:PRItemAttrCompilation];
            [items addObject:[i objectForKey:@"file"]];
        }
        [[_core db] commit];
        // post notifications
        if ([infoArray count] > 0) {
            [[NSNotificationCenter defaultCenter] postItemsChanged:items];
        }
    }];
    [pool drain];
}

@end
