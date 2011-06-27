#import "PRButtonCell.h"


@implementation PRButtonCell

- (NSRect)drawTitle:(NSAttributedString *)title 
		  withFrame:(NSRect)frame 
			 inView:(NSView *)controlView
{
	NSRect newFrame = NSMakeRect(frame.origin.x, 
								 frame.origin.y + 1, 
								 frame.size.width, 
								 frame.size.height);
	[title drawInRect:newFrame];
	return frame;
}

@end