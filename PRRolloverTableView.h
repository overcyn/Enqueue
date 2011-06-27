#import <Foundation/Foundation.h>
#import "PRTableView.h"

@interface PRRolloverTableView : PRTableView 
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
