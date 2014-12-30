#import "PRMainWindowView.h"

@interface PRMainWindowView () <NSSplitViewDelegate>
@end

@implementation PRMainWindowView {
    NSSplitView *_splitView;
    NSViewController *_leftVC;
    NSViewController *_centerVC;
    NSView *_bottomView;
}

- (id)init {
    if ((self = [super initWithFrame:CGRectMake(0,0,100,100)])) {
        [self setWantsLayer:YES];
        
        _splitView = [[NSSplitView alloc] init];
        [_splitView setDelegate:self];
        [_splitView setDividerStyle:NSSplitViewDividerStyleThin];
        [self addSubview:_splitView];
        [_splitView setVertical:YES];
    }
    return self;
}

#pragma mark - API

@synthesize leftViewController = _leftVC;
@synthesize centerViewController = _centerVC;
@synthesize bottomView = _bottomView;

- (void)setLeftViewController:(NSViewController *)value {
    if (_leftVC != value) {
        [[_leftVC view] removeFromSuperview];
        _leftVC = value;
        [_splitView addSubview:[_leftVC view]];
        [self _layout];
    }
}

- (void)setCenterViewController:(NSViewController *)value {
    if (_centerVC != value) {
        [[_centerVC view] removeFromSuperview];
        _centerVC = value;
        [_splitView addSubview:[_centerVC view]];
        [self _layout];
    }
}

- (void)setBottomView:(NSView *)value {
    if (_bottomView != value) {
        [_bottomView removeFromSuperview];
        _bottomView = value;
        [self addSubview:_bottomView];
        [self _layout];
    }
}

#pragma mark - NSView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [self _layout];
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    return subview != [splitView subviews][0];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedPosition < 185) {
        return 185;
    } else if (proposedPosition > 500) {
        return 500;
    } else {
        return proposedPosition;
    }
}


#pragma mark - Internal

- (void)_layout {
    CGRect b = [self bounds];
    {
        CGRect f = b;
        f.origin.y += 54;
        f.size.height -= 54;
        [_splitView setFrame:f];
    }
    {
        CGRect f = b;
        f.size.height = 54;
        [_bottomView setFrame:f];
    }
}

@end
