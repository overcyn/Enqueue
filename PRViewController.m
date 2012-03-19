#import "PRViewController.h"

@implementation PRViewController

- (id)init {
    if (!(self = [super init])) {return nil;}
    _firstKeyView = [[NSView alloc] init];
    _lastKeyView = [[NSView alloc] init];
    return self;
}

@synthesize firstKeyView = _firstKeyView,
lastKeyView = _lastKeyView;

@end
