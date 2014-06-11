#import "PRViewController.h"

@implementation PRViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {return nil;}
    _firstKeyView = [[NSView alloc] init];
    _lastKeyView = [[NSView alloc] init];
    [_firstKeyView setHidden:YES];
    [_lastKeyView setHidden:YES];
    return self;
}

- (id)init {
    if (!(self = [super init])) {return nil;}
    _firstKeyView = [[NSView alloc] init];
    _lastKeyView = [[NSView alloc] init];
    [_firstKeyView setHidden:YES];
    [_lastKeyView setHidden:YES];
    return self;
}

@synthesize firstKeyView = _firstKeyView,
lastKeyView = _lastKeyView;

@end
