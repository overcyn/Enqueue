#import "PRRolloverTableView.h"


@implementation PRRolloverTableView

// ========================================
// Initialization

- (void)awakeFromNib {
	[[self window] setAcceptsMouseMovedEvents:YES];
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self frame] 
                                                options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp | NSTrackingEnabledDuringMouseDrag
                                                  owner:self 
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
	mouseOverRow = -1;
    trackMouseWithinCell = FALSE;
}

- (void)dealloc {
	[self removeTrackingArea:trackingArea];
    [trackingArea release];
	[super dealloc];
}

// ========================================
// Accessors

@synthesize trackMouseWithinCell;
@synthesize pointInCell;
@synthesize mouseOverRow;

// ========================================
// Update

- (void)mouseEntered:(NSEvent *)theEvent {
	
}

- (void)mouseMoved:(NSEvent *)theEvent {
	id myDelegate = [self delegate];
	if (!myDelegate)
		return; // No delegate, no need to track the mouse.
	if (![myDelegate respondsToSelector:@selector(tableView:willDisplayCell:forTableColumn:row:)])
		return; // If the delegate doesn't modify the drawing, don't track.
    
	NSPoint point = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    int lastMouseOverRow = mouseOverRow;
	mouseOverRow = [self rowAtPoint:point];
    pointInCell = point;
    
    if (!NSPointInRect(point, [self rectOfRow:mouseOverRow])) {
        mouseOverRow = -1;
    }
    
    if (mouseOverRow != lastMouseOverRow) {
        [self setNeedsDisplayInRect:[self rectOfRow:lastMouseOverRow]];
        [self setNeedsDisplayInRect:[self rectOfRow:mouseOverRow]];
    } else {
        if (trackMouseWithinCell) {
            [self setNeedsDisplayInRect:[self rectOfRow:mouseOverRow]];
        }
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
	[self setNeedsDisplayInRect:[self rectOfRow:mouseOverRow]];
	mouseOverRow = -1;
}

- (void)updateTrackingArea {
    [self removeTrackingArea:trackingArea];
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self frame] 
                                                options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow
                                                  owner:self 
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)viewDidEndLiveResize {
    [super viewDidEndLiveResize];
    [self updateTrackingArea];
}

- (void)resetCursorRects {
    [super resetCursorRects];
    [self mouseMoved:nil];
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    
    if ([[self window] isKeyWindow]) {
        NSPoint point = [self convertPointFromBase:[theEvent locationInWindow]];
        NSCell *cell = [self preparedCellAtColumn:[self columnAtPoint:point] row:[self rowAtPoint:point]];
        NSMenu *menu = [cell menuForEvent:theEvent 
                                   inRect:[self frameOfCellAtColumn:[self columnAtPoint:point] row:[self rowAtPoint:point]] 
                                   ofView:self];
        [NSMenu popUpContextMenu:menu withEvent:theEvent forView:self];
    }
}

// ========================================
// Drawing

// Disable default highlight color
- (id)_highlightColorForCell:(NSCell *)cell {
    return nil;
}

// Draw custom higlights
- (void)highlightSelectionInClipRect:(NSRect)theClipRect {	
	
}

@end
