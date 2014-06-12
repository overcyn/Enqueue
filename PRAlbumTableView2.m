#import "PRAlbumTableView2.h"


@implementation PRAlbumTableView2 {
    __weak NSResponder *_actualResponder;
}

@synthesize actualResponder = _actualResponder;

- (BOOL)becomeFirstResponder {
    if (_actualResponder != self && _actualResponder != nil) {
        [[self window] makeFirstResponder:_actualResponder];
    }
    return YES;
}

@end
