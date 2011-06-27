/*
 PRCenteredTextFieldCell.h
 
 PRCenteredTextFieldCell is a subclass of NSTextField that has padding on the left and right sides.
 */

#import <Cocoa/Cocoa.h>


@interface PRCenteredTextFieldCell : NSTextFieldCell
{
	BOOL mIsEditingOrSelecting;
}

@end
