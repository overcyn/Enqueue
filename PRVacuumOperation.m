#import "PRVacuumOperation.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRTask.h"
#import "PRTaskManager.h"

@implementation PRVacuumOperation

- (id)initWithCore:(PRCore *)core
{
    self = [super init];
    if (self) {
        _core = core;
    }
    return self;
}

- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    _task = [[[PRTask alloc] init] autorelease];
    [_task setTitle:@"Analyzing Library..."];
    [[_core taskManager] addTask:_task];
    
    [[_core db2] execute:@"VACUUM"];
    [[_core db2] execute:@"ANALYZE"];
    
    [[_core taskManager] removeTask:_task];
    [pool drain];
}

@end
