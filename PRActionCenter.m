#import "PRActionCenter.h"
#import "PRAction.h"


@implementation PRActionCenter {
    NSOperationQueue *_opQueue;
    __weak PRCore *_core;
}

@synthesize core = _core;

+ (instancetype)defaultCenter {
    static PRActionCenter *sDefaultCenter;
    static dispatch_once_t sOnce = 0;
    dispatch_once(&sOnce, ^{
        sDefaultCenter = [[PRActionCenter alloc] init];
        sDefaultCenter->_opQueue = [[NSOperationQueue alloc] init];
    });
    return sDefaultCenter;
}

+ (void)performAction:(PRAction2 *)action {
    [(PRActionCenter *)[self defaultCenter] performAction:action];
}

- (void)performAction:(PRAction2 *)action {
    [action setCore:_core];
    [_opQueue addOperation:action];
}

+ (void)performTask:(PRAction)action {
    [(PRActionCenter *)[self defaultCenter] performTask:action];
}

- (void)performTask:(PRAction)action {
    action(_core);
}

@end
