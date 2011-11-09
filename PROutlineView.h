#import <Foundation/Foundation.h>

@interface PROutlineView : NSOutlineView
{
    int _hoverRow;
    NSTimer *autoexpand_timer;
}

- (void)reloadVisibleItems;

@end
