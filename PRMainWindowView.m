#import "PRMainWindowView.h"

#define BOTTOM_HEIGHT       55

@interface PRMainWindowView () <NSSplitViewDelegate>
@end

@implementation PRMainWindowView {
    NSSplitView *_splitView;
    NSView *_sidebarView;
    NSView *_centerView;
    NSView *_bottomView;
    BOOL _sidebarVisible;
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

@synthesize sidebarView = _sidebarView;
@synthesize centerView = _centerView;
@synthesize bottomView = _bottomView;
@synthesize sidebarVisible = _sidebarVisible;

- (void)setSidebarView:(NSView *)value {
    if (_sidebarView != value) {
        [_sidebarView removeFromSuperview];
        _sidebarView = value;
        [self _layout];
    }
}

- (void)setCenterView:(NSView *)value {
    if (_centerView != value) {
        [_centerView removeFromSuperview];
        _centerView = value;
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

- (void)setSidebarVisible:(BOOL)value {
    if (_sidebarVisible != value) {
        _sidebarVisible = value;
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
    for (NSView *i in [[_splitView subviews] copy]) {
        [i removeFromSuperview];
    }
    if (_sidebarVisible && _sidebarView) {
        [_splitView addSubview:_sidebarView];
    }
    [_splitView addSubview:_centerView];
    
    CGRect b = [self bounds];
    {
        CGRect f = b;
        f.origin.y += BOTTOM_HEIGHT;
        f.size.height -= BOTTOM_HEIGHT;
        [_splitView setFrame:f];
    }
    {
        CGRect f = b;
        f.size.height = BOTTOM_HEIGHT;
        [_bottomView setFrame:f];
    }
}

@end
