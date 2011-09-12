#import "PRRatingCell.h"


@implementation PRRatingCell

- (id)init
{
	if ((self = [super init])) {
		showDots = FALSE;
		editing = FALSE;
	}
	return self;
}

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{	
	NSImage *icon;
	if (segment == 0) {
		icon = [NSImage imageNamed:@"PREmptyIcon"];
	} else if (segment <= [self selectedSegment]) {
		if (([self isHighlighted] || editing) && !showDots) {
			icon = [NSImage imageNamed:@"PRLightRatingIcon"];
		} else {
			icon = [NSImage imageNamed:@"PRRatingIcon"];
		}
	} else {
		if (([self isHighlighted] || editing) && !showDots) {
			icon = [NSImage imageNamed:@"PRLightEmptyRatingIcon"];
		} else {
			if (showDots) {
				icon = [NSImage imageNamed:@"PREmptyRatingIcon"];
			} else {
				icon = [NSImage imageNamed:@"PREmptyIcon"];
			}
		}
	}
	[icon setFlipped:TRUE];
	[icon drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect frame = NSMakeRect(cellFrame.origin.x + 2, cellFrame.origin.y + 1, 0, 15);
	for (int i = 0; i < [self segmentCount]; i++) {
		frame.size.width = [self widthForSegment:i] + 2;
		[self drawSegment:i inFrame:frame withView:controlView];
		frame.origin.x = frame.origin.x + frame.size.width - 1;
	}
}

- (BOOL)trackMouse:(NSEvent *)event_ inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
    cellFrame_ = cellFrame;
	return [super trackMouse:event_ inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{    
	editing = TRUE;
	for (int i = 0; i < [self segmentCount]; i++) {
		if (NSPointInRect(startPoint, [self frameForSegment:i])) {
			[self setSelectedSegment:i];
		}
	}
	return [super startTrackingAt:startPoint inView:controlView];
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
    currentPoint.y = [self frameForSegment:0].origin.y + 5;
    if (currentPoint.x <= [self frameForSegment:0].origin.x) {
        currentPoint.x = [self frameForSegment:0].origin.x + 1;
    }
    if (currentPoint.x >= [self frameForSegment:6].origin.x) {
        currentPoint.x = [self frameForSegment:6].origin.x - 1;
    }
    
	for (int i = 0; i < [self segmentCount]; i++) {
		if (NSPointInRect(currentPoint, [self frameForSegment:i])) {
			[self setSelectedSegment:i];
		}
	}
	
	return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
    currentPoint.y = [self frameForSegment:0].origin.y + 5;
    if (currentPoint.x <= [self frameForSegment:0].origin.x) {
        currentPoint.x = [self frameForSegment:0].origin.x + 1;
    }
    if (currentPoint.x >= [self frameForSegment:6].origin.x) {
        currentPoint.x = [self frameForSegment:6].origin.x - 1;
    }
    
	for (int i = 0; i < [self segmentCount]; i++) {
		if (NSPointInRect(currentPoint, [self frameForSegment:i])) {
            [self setObjectValue:[NSNumber numberWithInt:i]];
		}
	}
	
	editing = FALSE;
	[super stopTracking:lastPoint at:currentPoint inView:controlView mouseIsUp:flag];
}

- (NSRect)frameForSegment:(BOOL)segment
{
	NSRect frame = NSMakeRect(cellFrame_.origin.x + 2, cellFrame_.origin.y + 1, 0, 15);
	for (int i = 0; i < [self segmentCount]; i++) {
		frame.size.width = [self widthForSegment:i] + 2;
		if (i == segment) {
			break;
		}	
		frame.origin.x = frame.origin.x + frame.size.width - 1;
	}
	return frame;
}

- (void)setShowDots:(BOOL)newShowDots
{
	showDots = newShowDots;
}

@end