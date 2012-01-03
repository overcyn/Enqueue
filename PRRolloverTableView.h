#import <Foundation/Foundation.h>
#import "PRTableView2.h"

@interface PRRolloverTableView : PRTableView2 
{
    NSTrackingArea *trackingArea;
    
    BOOL trackMouseWithinCell;
	int mouseOverRow;
    NSPoint pointInCell;
}

@property (readwrite, assign, nonatomic) BOOL trackMouseWithinCell;
@property (readonly, assign, nonatomic) int mouseOverRow;
@property (readonly, assign, nonatomic) NSPoint pointInCell;

- (void)updateTrackingArea;

@end
