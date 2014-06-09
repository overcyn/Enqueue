#import <Foundation/Foundation.h>
@protocol PROutlineViewDelegate;


@interface PROutlineView : NSOutlineView {
    int _hoverRow;
    NSTimer *autoexpand_timer;
}
- (void)reloadVisibleItems;
@end


@protocol PROutlineViewDelegate <NSObject>
@optional
- (BOOL)outlineView:(PROutlineView *)outlineView keyDown:(NSEvent *)event;
@end
