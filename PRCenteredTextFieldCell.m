#import "PRCenteredTextFieldCell.h"


@implementation PRCenteredTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect 
{
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
	titleFrame = NSInsetRect(titleFrame, 3, 1);
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

//- (void)editWithFrame:(NSRect)aRect 
//			   inView:(NSView *)controlView 
//			   editor:(NSText *)textObj 
//			 delegate:(id)anObject 
//				event:(NSEvent *)theEvent
//{
//	NSLog(@"%@",NSStringFromRect(aRect));
//	aRect = [self titleRectForBounds:aRect];
//	NSLog(@"%@",NSStringFromRect(aRect));
//	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
//}
//
//- (void)selectWithFrame:(NSRect)aRect 
//				 inView:(NSView *)controlView 
//				 editor:(NSText *)textObj 
//			   delegate:(id)anObject 
//				  start:(NSInteger)selStart 
//				 length:(NSInteger)selLength
//{
//	aRect = [self titleRectForBounds:aRect];
//	
//	aRect.size.width = [self cellSizeForBounds:aRect].width;
//	NSLog(@"%@",NSStringFromRect(aRect));
//	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
//	
//}

@end
