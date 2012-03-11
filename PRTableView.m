#import "PRTableView.h"
#import "PRNowPlayingController.h"
#import "PRCore.h"
#import "PRNowPlayingViewController.h"


@implementation PRTableView

// ========================================
// Responder

// Make first responder with right click
- (NSMenu *)menuForEvent:(NSEvent *)event {
    [[self window] makeFirstResponder:self];
	int row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
	if (![[self selectedRowIndexes] containsIndex:row]) {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
	}
	return [super menuForEvent:event];
}

// Highlight clicked row when beginning drag.
- (void)mouseDown:(NSEvent *)event {
    if (![[self window] isKeyWindow] || 
        [[self window] firstResponder] != self ||
        (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) ||
		(([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask)) {
		[super mouseDown:event];
		return;
    }
	int row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
	if (![[self selectedRowIndexes] containsIndex:row]) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
	}
	[super mouseDown:event];
}

// sends keyDown to PRDelegate
- (void)keyDown:(NSEvent *)event {
    BOOL didHandle = FALSE;
    if ([self delegate] && 
        [[self delegate] conformsToProtocol:@protocol(PRTableViewDelegate)] && 
        [[self delegate] respondsToSelector:@selector(tableView:keyDown:)]) {
        didHandle = [(id<PRTableViewDelegate>)[self delegate] tableView:self keyDown:event];
    }
    if (!didHandle) {
        [super keyDown:event];
    }
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)point operation:(NSDragOperation)operation {
    if ([self dataSource] && [[self dataSource] respondsToSelector:@selector(draggedImage:endedAt:operation:)]) {
        [(PRNowPlayingViewController *)[self dataSource] draggedImage:image endedAt:point operation:operation];
    }
    [super draggedImage:image endedAt:point operation:operation];
}

- (void)draggedImage:(NSImage *)image movedTo:(NSPoint)point {
    if ([self dataSource] && [[self dataSource] respondsToSelector:@selector(draggedImage:movedTo:)]) {
         [(PRNowPlayingViewController *)[self dataSource] draggedImage:image movedTo:point];
    }
    [super draggedImage:image movedTo:point];
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack {
    [super dragImage:anImage 
                  at:imageLoc 
              offset:mouseOffset 
               event:theEvent 
          pasteboard:pboard 
              source:sourceObject 
           slideBack:TRUE];
}

// ========================================
// Editing

- (void)cancelOperation:(id)sender {
    if ([self currentEditor] != nil) {
        [self abortEditing];
        // We lose focus so re-establish
        [[self window] makeFirstResponder:self];
    }
}

// ========================================
// Selection

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
    if ([[self delegate] respondsToSelector:@selector(tableView:selectionIndexesForProposedSelection:)]) {
        indexes = [[self delegate] tableView:self selectionIndexesForProposedSelection:indexes];
    }
    [super selectRowIndexes:indexes byExtendingSelection:extend];
}

// ========================================
// Drawing

// Disable default highlight color
- (id)_highlightColorForCell:(NSCell *)cell {
    return nil;
}

// Draw custom higlights
- (void)highlightSelectionInClipRect:(NSRect)theClipRect {	
	// this method is asking us to draw the hightlights for 
	// all of the selected rows that are visible inside theClipRect
	NSRange	visibleRowIndexes = [self rowsInRect:theClipRect];
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	int	row = visibleRowIndexes.location;
	int endRow = row + visibleRowIndexes.length;
	// draw highlight for the visible, selected rows
    for (; row < endRow; row++) {
		if([selectedRowIndexes containsIndex:row]) {
            NSColor *color;
            if (self == [[self window] firstResponder] && [[self window] isKeyWindow]) {
                color = [NSColor colorWithCalibratedRed:59./255 green:128./255 blue:223./255 alpha:1.0];
            } else {
                color = [NSColor secondarySelectedControlColor];
            }
            [color set];
            
			NSRect rectOfRow = [self rectOfRow:row];
            NSRect rowRect = rectOfRow;
            rowRect.size.height -= 1;
			[[NSBezierPath bezierPathWithRect:rowRect] fill];
            rowRect.origin.y += rowRect.size.height;
            rowRect.size.height = 1;
            [[color blendedColorWithFraction:0.3 ofColor:[NSColor whiteColor]] set];
            [[NSBezierPath bezierPathWithRect:rowRect] fill];
		}
	}
}

// Disable context menu higlight
- (void)_drawContextMenuHighlightForIndexes:(id)arg1 clipRect:(struct CGRect)arg2 {
    [self highlightSelectionInClipRect:NSRectFromCGRect(arg2)];
    NSIndexSet *visibleRows = [NSIndexSet indexSetWithIndexesInRange:[self rowsInRect:NSRectFromCGRect(arg2)]];
    NSIndexSet *selectedRows = [[self selectedRowIndexes] indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop){
        return [visibleRows containsIndex:idx];
    }];
    NSInteger i = [selectedRows firstIndex];
    while (i != NSNotFound) {
        for (int j = 0; j < [self numberOfColumns]; j++) {
            NSRect frame = [self frameOfCellAtColumn:j row:i];
            NSCell *cell = [self preparedCellAtColumn:j row:i];
            [cell drawWithFrame:frame inView:self];
        }
        i = [selectedRows indexGreaterThanIndex:i];
    }
}

// Draw custom drop highlights
- (void)_drawDropHighlightBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex onRow:(int)theRow atOffset:(float)theOffset {
	NSRect aHighlightRect;
	float aYPosition = 0;
	
	// if the lower row index is the first row
	// get the rect of the lowerRowIndex and draw above it
	if(theUpperRowIndex < 0) {
		aHighlightRect = [self rectOfRow:theLowerRowIndex];
		aYPosition = aHighlightRect.origin.y;
	}
	// in all other cases draw below theUpperRowIndex
	else {
		aHighlightRect = [self rectOfRow:theUpperRowIndex];
		aYPosition = aHighlightRect.origin.y + aHighlightRect.size.height;
	}
	
	// accent rect will be where we draw the little circle
	float anAccentRectSize = 6;
	float anAccentRectXOffset = 2;
	NSRect anAccentRect = NSMakeRect(aHighlightRect.origin.x + anAccentRectXOffset, 
									 aYPosition - anAccentRectSize*.5, 
									 anAccentRectSize, 
									 anAccentRectSize);
	
	// make points to define the line starting after the accent circle, extending the width of the row
	NSPoint aStartPoint = NSMakePoint(aHighlightRect.origin.x + anAccentRect.origin.x + anAccentRect.size.width, aYPosition);
	NSPoint anEndPoint = NSMakePoint(aHighlightRect.origin.x + aHighlightRect.size.width, aYPosition);
	
	// lock focus for drawing
	[self lockFocus];
	
	// make a bezier path, add the circle and line
	NSBezierPath *aHighlightPath = [NSBezierPath bezierPath];
	[aHighlightPath appendBezierPathWithOvalInRect:anAccentRect];
	[aHighlightPath moveToPoint:aStartPoint];
	[aHighlightPath lineToPoint:anEndPoint];
	
	// fill with white for the accent circle and stroke the path with black
	[[NSColor whiteColor] set];
	[aHighlightPath fill];
	[aHighlightPath setLineWidth:2.0];
	[[NSColor blackColor] set];
	[aHighlightPath stroke];
	
	// unlock focus
	[self unlockFocus];
}

@end
