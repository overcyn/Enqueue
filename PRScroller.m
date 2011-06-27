#import "PRScroller.h"


@implementation PRScroller

- (void)drawRect:(NSRect)dirtyRect
{
	[self drawKnobSlotInRect:dirtyRect highlight:FALSE];
	[self drawKnob];
}

- (void)drawKnob {
	NSRect position = [self rectForPart:NSScrollerKnob];
	
	if (position.size.height == 0) {
		return;
	}
	
	NSImage *topImg = [NSImage imageNamed:@"PRVerticalScrollerThinTop"];
	NSImage *centerImg = [NSImage imageNamed:@"PRVerticalScrollerThinCenter"];
	NSImage *bottomImg = [NSImage imageNamed:@"PRVerticalScrollerThinBottom"];
	
	NSSize topImgSize = [topImg size];
	NSSize centerImgSize = [centerImg size];
	NSSize bottomImgSize = [bottomImg size];
	
	
	[topImg setFlipped:YES];
	[topImg drawInRect:NSMakeRect(position.origin.x, position.origin.y,
								  topImgSize.width, topImgSize.height)
			  fromRect:NSMakeRect(0, 0, topImgSize.width, topImgSize.height)
			 operation:NSCompositeSourceOver
			  fraction:1.0];
	
	int i = 0;
	for (i = (position.origin.y+topImgSize.height); i < (position.origin.y +
														 (position.size.height-bottomImgSize.height)); i += centerImgSize.height) {
		[centerImg drawInRect:NSMakeRect(position.origin.x, i,
										 centerImgSize.width, centerImgSize.height)
					 fromRect:NSMakeRect(0, 0, centerImgSize.width,
										 centerImgSize.height)
					operation:NSCompositeSourceOver
					 fraction:1.0];
	}
	
	[bottomImg setFlipped:YES];
	[bottomImg drawInRect:NSMakeRect(position.origin.x, position.origin.y+
									 (position.size.height-bottomImgSize.height), bottomImgSize.width, bottomImgSize.height)
				 fromRect:NSMakeRect(0, 0, bottomImgSize.width,
									 bottomImgSize.height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
}

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{

}

- (void)drawParts
{
	for (int i = 0; i < 7; i++) {
		[[NSColor colorWithDeviceRed:218./255 green:223./255 blue:230./255 alpha:1.0] set];
		[NSBezierPath fillRect:[self rectForPart:i]];
	}
}

- (void)drawArrow:(NSScrollerArrow)arrow highlight:(BOOL)flag
{
	
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint p;
	NSPoint q;
	
	p = [event locationInWindow];
	q = [self convertPoint:p fromView:nil];
	
	if (NSPointInRect(q, [self rectForPart:NSScrollerKnob])) {
		[super mouseDown:event];
	} else {
		[[(NSScrollView *)[self superview] documentView] mouseDown:event];
	}

}

@end
