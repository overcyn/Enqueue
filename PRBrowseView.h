#import <Cocoa/Cocoa.h>

@protocol PRBrowseViewDelegate;


typedef enum {
    PRBrowseViewStyleNone,
    PRBrowseViewStyleVertical,
    PRBrowseViewStyleHorizontal,
} PRBrowseViewStyle;


@interface PRBrowseView : NSView
@property (nonatomic, weak) id<PRBrowseViewDelegate> delegate;
@property (nonatomic) PRBrowseViewStyle style;
@property (nonatomic, strong) NSArray *browseViews;
@property (nonatomic, strong) NSView *detailView;
@property (nonatomic) CGFloat dividerPosition;
@end


@protocol PRBrowseViewDelegate
@required
- (void)browseViewDidChangeDividerPosition:(PRBrowseView *)view;
@end
