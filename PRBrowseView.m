#import "PRBrowseView.h"
#import "PRPaneSplitView.h"


#define MAX_H_BROWSER_WIDTH         (400)
#define MIN_H_BROWSER_WIDTH         (120)
#define MIN_V_BROWSER_WIDTH         (120)
#define MIN_V_DETAIL_WIDTH          (120)


@interface PRBrowseView () <NSSplitViewDelegate>
@end

@implementation PRBrowseView {
    NSSplitView *_splitView;
    NSSplitView *_subSplitView;
    PRBrowseViewStyle _style;
    NSArray *_browseViews;
    NSView *_detailView;
    NSView *_detailSuperview;
    BOOL _refreshing;
}

- (id)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) {return nil;}
    _style = PRBrowseViewStyleNone;
    
    _detailSuperview = [[NSView alloc] init];
    [_detailSuperview setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    
    _splitView = [[PRPaneSplitView alloc] init];
    [_splitView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [_splitView setDelegate:self];
    
    _subSplitView = [[NSSplitView alloc] init];
    [_subSplitView setDividerStyle:NSSplitViewDividerStyleThin];
    [_subSplitView setVertical:YES];
    [_subSplitView setDelegate:self];
    return self;
}

#pragma mark - Accessors

@synthesize style = _style;
@synthesize browseViews = _browseViews;
@synthesize detailView = _detailView;

- (CGFloat)dividerPosition {
    return 0;
}

- (void)setDividerPosition:(CGFloat)value {
    [_splitView setPosition:value ofDividerAtIndex:0];
}

- (void)setStyle:(PRBrowseViewStyle)value {
    if (_style != value) {
        _style = value;
        
        [_splitView removeFromSuperview];
        [_subSplitView removeFromSuperview];
        [_detailSuperview removeFromSuperview];
        for (NSView *i in _browseViews) {
            [i removeFromSuperview];
        }
        
        if (_style == PRBrowseViewStyleNone) {
            [_detailSuperview setFrame:[self bounds]];
            [self addSubview:_detailSuperview];
        } else {
            [_splitView setFrame:[self bounds]];
            [self addSubview:_splitView];
            if (_style == PRBrowseViewStyleHorizontal) {
                for (NSView *i in _browseViews) {
                    [_subSplitView addSubview:i];
                }
                [self _layoutSubSplitView];
                [_splitView addSubview:_subSplitView];
                [_splitView addSubview:_detailSuperview];
                [_splitView setVertical:NO];
                [_splitView setDividerStyle:NSSplitViewDividerStyleThick];
            } else if (_style == PRBrowseViewStyleVertical) {
                if ([_browseViews count] > 0) {
                    [_splitView addSubview:_browseViews[0]];
                }
                [_splitView addSubview:_detailSuperview];
                [_splitView setVertical:YES];
                [_splitView setDividerStyle:NSSplitViewDividerStyleThin];
            }
        }
    }
}

- (void)setBrowseViews:(NSArray *)value {
    if (_browseViews != value) {
        for (NSView *i in _browseViews) {
            [i removeFromSuperview];
        }
        _browseViews = value;
        
        if (_style == PRBrowseViewStyleVertical) {
            [_detailSuperview removeFromSuperview];
            if ([_browseViews count] > 0) {
                [_splitView addSubview:_browseViews[0]];
            }
            [_splitView addSubview:_detailSuperview];
        } else if (_style == PRBrowseViewStyleHorizontal) {
            for (NSView *i in _browseViews) {
                [_subSplitView addSubview:i];
            }
            [self _layoutSubSplitView];
        }
    }
}

- (void)setDetailView:(NSView *)value {
    if (_detailView != value) {
        [_detailView removeFromSuperview];
        _detailView = value;
        [_detailView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
        [_detailView setFrame:[_detailSuperview bounds]];
        [_detailSuperview addSubview:_detailView];
    }
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    if (splitView == _subSplitView) {
        return NO;
    } else {
        return [splitView subviews][0] != subview;
    }
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if (_refreshing) {
        return;
    }
    NSSplitView *splitView = [notification object];
    if (splitView == _splitView && _style == PRBrowseViewStyleHorizontal) {
        if ([_subSplitView frame].size.height < MIN_V_BROWSER_WIDTH) {
            NSRect frame = [_subSplitView frame];
            frame.size.height = MIN_V_BROWSER_WIDTH;
            [_subSplitView setFrame:frame];
        } else if ([_detailView frame].size.height < MIN_V_BROWSER_WIDTH) {
            NSRect frame = [_subSplitView frame];
            frame.size.height = [_splitView frame].size.height - MIN_V_BROWSER_WIDTH - [_splitView dividerThickness];
            [_subSplitView setFrame:frame];
        }
    }
    // [self saveBrowser];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)idx {
    if (splitView == _splitView) {
        if (_style == PRBrowseViewStyleHorizontal) {
            if (proposedPosition < MIN_V_BROWSER_WIDTH) {
                return MIN_V_BROWSER_WIDTH;
            } else if (proposedPosition > [_splitView frame].size.height - MIN_V_DETAIL_WIDTH) {
                return [_splitView frame].size.height - MIN_V_DETAIL_WIDTH;
            }
        } else if (_style == PRBrowseViewStyleVertical) {
            if (proposedPosition > MAX_H_BROWSER_WIDTH) {
                return MAX_H_BROWSER_WIDTH;
            } else if (proposedPosition < MIN_H_BROWSER_WIDTH) {
                return MIN_H_BROWSER_WIDTH;
            }
        }
    }
    return proposedPosition;
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedRect forDrawnRect:(NSRect)rect ofDividerAtIndex:(NSInteger)idx {
    return splitView == _subSplitView ? NSZeroRect : proposedRect;
}

#pragma mark - UI

- (void)_layoutSubSplitView {
    NSInteger subviews = [[_subSplitView subviews] count];
    if (subviews == 3) {
        float width = ([_subSplitView frame].size.width - 2) / 3;
        [_subSplitView setPosition:width ofDividerAtIndex:0];
        [_subSplitView setPosition:width*2+1 ofDividerAtIndex:1];
    } else if (subviews == 2)  {
        [_subSplitView setPosition:[_subSplitView frame].size.width/2 ofDividerAtIndex:0];
    }
}

@end
