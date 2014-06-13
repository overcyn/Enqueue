#import <Cocoa/Cocoa.h>


typedef enum {
    PRBrowseViewStyleNone,
    PRBrowseViewStyleVertical,
    PRBrowseViewStyleHorizontal,
} PRBrowseViewStyle;


@interface PRBrowseView : NSView
@property (nonatomic) PRBrowseViewStyle style;
@property (nonatomic, strong) NSArray *browseViews;
@property (nonatomic, strong) NSView *detailView;
@property (nonatomic) CGFloat dividerPosition;
@end
