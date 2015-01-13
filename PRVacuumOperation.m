#import "PRVacuumOperation.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PROperationProgress.h"
#import "PRProgressManager.h"
#import "NSOperationQueue+Extensions.h"

@implementation PRVacuumOperation

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    return self;
}

- (void)main {
    NSLog(@"begin vacuum");
    @autoreleasepool {
        _task = [PROperationProgress task];
        [_task setTitle:@"Analyzing Library..."];
        [[_core taskManager] addTask:_task];
        
        [[NSOperationQueue mainQueue] addBlockAndWait:^{
            [[_core db] execute:@"VACUUM"];
            [[_core db] execute:@"ANALYZE"];
        }];
        
        [[_core taskManager] removeTask:_task];
    }
    NSLog(@"end vacuum");
}

@end
