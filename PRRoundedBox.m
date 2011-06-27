#import "PRRoundedBox.h"


@implementation PRRoundedBox

- (void)drawRect:(NSRect)dirtyRect
{
	NSBezierPath *bezierPath;
	NSRect frame;
	NSRect rect;
	
	frame = [self bounds];
	rect = NSMakeRect(frame.origin.x, 
					  frame.origin.y + 1, 
					  frame.size.width, 
					  frame.size.height - 1);
	
	// draw background
	bezierPath = [NSBezierPath bezierPathWithRoundedRect:rect
												 xRadius:5.0 
												 yRadius:0.0];
	[[NSColor colorWithDeviceRed:0.184 
						   green:0.217 
							blue:0.246
						   alpha:1.0] set];
	[bezierPath fill];
	
	// draw border
	[[NSColor blackColor] set];
	[bezierPath stroke];
	
	// draw highlight
	[[NSColor colorWithDeviceWhite:1 alpha:0.75] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(frame.origin.x, frame.origin.y)
							  toPoint:NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y)];

}

@end