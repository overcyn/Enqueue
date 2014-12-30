#import "PRBridge.h"
#import "PRAction.h"

@implementation PRBridge {
    __weak PRCore *_core;
}

@synthesize core = _core;

- (void)performTask:(PRTask)action {
    dispatch_async(dispatch_get_main_queue(), ^{
        action(_core);
    });
}

- (void)performTaskSync:(PRTask)action {
    action(_core);
}

@end
