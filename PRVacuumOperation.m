#import "PRVacuumOperation.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRTask.h"
#import "PRTaskManager.h"

@implementation PRVacuumOperation

- (id)initWithCore:(PRCore *)core
{
    if (!(self = [super init])) {return nil;}
    _core = core;
    return self;
}

- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    _task = [PRTask task];
    [_task setTitle:@"Analyzing Library..."];
    [[_core taskManager] addTask:_task];
    
    [[NSOperationQueue mainQueue] addBlockAndWait:^{
        [[_core db] execute:@"VACUUM"];
        [[_core db] execute:@"ANALYZE"];
    }];
    
    [[_core taskManager] removeTask:_task];
    [pool drain];
}

@end
