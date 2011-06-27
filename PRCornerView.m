#import "PRCornerView.h"


@implementation PRCornerView

- (void)drawRect:(NSRect)rect 
{
	[[NSImage imageNamed:@"PRCornerIcon"] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent 
{
    return YES;
}

- (void)mouseDown:(NSEvent *)event
{
	mouseDownPoint = [self convertPoint:[event locationInWindow] fromView:nil];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint originalLocation, mouseLocation;
	float deltaX, deltaY;
	
	originalLocation = [self convertPoint:mouseDownPoint toView:nil];
	mouseLocation = [theEvent locationInWindow];
	
	deltaX = -originalLocation.x + mouseLocation.x;
	deltaY = originalLocation.y - mouseLocation.y;
	
	NSWindow *window = [self window];
	NSSize minSize = [window minSize];
	NSRect frame = [window frame];
	
	if (frame.origin.y - deltaY < 0) {
		deltaY = frame.origin.y;
	}
	
	if (frame.origin.x + frame.size.width + deltaX > [[window screen] frame].size.width) {
		deltaX = [[window screen] frame].size.width - frame.origin.x - frame.size.width;
	}
	
	if (frame.size.height + deltaY < minSize.height) {
		deltaY = minSize.height - frame.size.height;
	}
	
	if (frame.size.width + deltaX < minSize.width) {
		deltaX = minSize.width - frame.size.width;
	}
	
    CGFloat newHeight = frame.size.height + deltaY;
    CGFloat newWidth  = frame.size.width  + deltaX;
    if (newHeight >= minSize.height) {
        frame.size.height = newHeight;
        frame.origin.y -= deltaY;
    }
    if (newWidth >= minSize.width)
        frame.size.width = newWidth;
    [window setFrame:frame display:TRUE animate:FALSE];
}

- (BOOL)mouseDownCanMoveWindow
{
	return FALSE;
}

@end
