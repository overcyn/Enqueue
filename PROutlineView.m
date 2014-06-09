#import "PROutlineView.h"
#import "PRCore.h"
#import "PRNowPlayingController.h"
#import "PRNowPlayingViewController.h"


@interface NSOutlineView (private)
- (void)_scheduleAutoExpandTimerForItem:(id)object;
- (void)_drawContentsAtRow:(NSInteger)row column:(NSInteger)col withCellFrame:(NSRect)frame;
@end


@implementation PROutlineView

#pragma mark - Responder

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	if ([[self selectedRowIndexes] count] == 0) {
		return nil;
	}
	return [super menuForEvent:theEvent];
}

- (void)rightMouseDown:(NSEvent *)event {
    [[self window] makeFirstResponder:self];
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	int row = [self rowAtPoint:p];
	if (![[self selectedRowIndexes] containsIndex:row]) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:row];
		[self selectRowIndexes:indexes byExtendingSelection:FALSE];
	}
	[super rightMouseDown:event];
}

- (void)mouseDown:(NSEvent *)event {
    if (![[self window] isKeyWindow]) {
        [super mouseDown:event];
        return;
    }
    
	if ((([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) ||
		(([event modifierFlags] & NSControlKeyMask) == NSControlKeyMask) ||
		(([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask)) {
		[super mouseDown:event];
		return;
	}
	
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	int row = [self rowAtPoint:p];
    if (NSPointInRect(p, [self frameOfOutlineCellAtRow:row])) {
        [self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        [super mouseDown:event];
        return;
    }
    
    //	int column = [self columnAtPoint:p];
	if (![[self selectedRowIndexes] containsIndex:row]) {
        NSIndexSet *indexes;
		if ([[self delegate] respondsToSelector:@selector(outlineView:selectionIndexesForProposedSelection:)]) {
            indexes = [[self delegate] outlineView:self selectionIndexesForProposedSelection:[NSIndexSet indexSetWithIndex:row]];
		} else {
			indexes = [NSIndexSet indexSetWithIndex:row];
		}
		[self selectRowIndexes:indexes byExtendingSelection:FALSE];
	}
    
    //	if (([event modifierFlags] & NSControlKeyMask) == NSControlKeyMask &&
    //		[[self selectedRowIndexes] count] == 0) {
    //		return;
    //	}
	[super mouseDown:event];
}

- (void)keyDown:(NSEvent *)event {
    BOOL didHandle = FALSE;
    if ([self delegate] && 
        [[self delegate] conformsToProtocol:@protocol(PROutlineViewDelegate)] && 
        [[self delegate] respondsToSelector:@selector(outlineView:keyDown:)]) {
        didHandle = [(id<PROutlineViewDelegate>)[self delegate] outlineView:self keyDown:event];
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
           slideBack:FALSE];
}

// Auto Expand Delay: Cyberduck outline view
- (void)_scheduleAutoExpandTimerForItem:(id)object {
    int mouseoverRow = [self rowAtPoint:[self convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil]];
    if ([[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseDragged
        && NSPointInRect([self convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil], NSInsetRect([self rectOfRow:mouseoverRow], 0, 5))) {
        if (_hoverRow == mouseoverRow) {
            return;
        }
        _hoverRow = mouseoverRow;
        [autoexpand_timer invalidate];
        autoexpand_timer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                             target:self
                                                           selector:@selector(_scheduleAutoExpandTimerForItemDelayed:)
                                                           userInfo:nil
                                                            repeats:NO];
    }
}

- (void)_scheduleAutoExpandTimerForItemDelayed:(NSTimer *)sender {
    int mouseoverRow = [self rowAtPoint:[self convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil]];
    if ([[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseDragged) {
        if (_hoverRow == mouseoverRow) {
            if ([super respondsToSelector:@selector(_scheduleAutoExpandTimerForItem:)]) {
                [super _scheduleAutoExpandTimerForItem:[self itemAtRow:_hoverRow]];
            }
        }
    }
}

#pragma mark - Selection

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
    if ([[self delegate] respondsToSelector:@selector(outlineView:selectionIndexesForProposedSelection:)]) {
        indexes = [[self delegate] outlineView:self selectionIndexesForProposedSelection:indexes];
    }
    [super selectRowIndexes:indexes byExtendingSelection:extend];
}

#pragma mark - Drawing

// Disable default highlight color
- (id)_highlightColorForCell:(NSCell *)cell {
    return nil;
}

// Draw custom highlights
- (void)highlightSelectionInClipRect:(NSRect)theClipRect {
	// this method is asking us to draw the hightlights for 
	// all of the selected rows that are visible inside theClipRect
	NSRange	visibleRowIndexes = [self rowsInRect:theClipRect];
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	int	row = visibleRowIndexes.location;
	int endRow = row + visibleRowIndexes.length;
	// draw highlight for the visible, selected rows
    for (; row < endRow; row++) {
		if(![selectedRowIndexes containsIndex:row]) {
            continue;
        }
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

// Draw custom context menu highlight
- (void)_drawContextMenuHighlightForIndexes:(id)arg1 clipRect:(struct CGRect)arg2 {
    [self highlightSelectionInClipRect:NSRectFromCGRect(arg2)];
    NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
    NSInteger i = [selectedRowIndexes firstIndex];
    while (i != NSNotFound) {
        for (int j = 0; j < [self numberOfColumns]; j++) {
            NSRect frame = [self frameOfCellAtColumn:j row:i];
            NSCell *cell = [self preparedCellAtColumn:j row:i];
            [cell drawWithFrame:frame inView:self];
        }
        i = [selectedRowIndexes indexGreaterThanIndex:i];
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

// Disable round highlight on highlighted parent row during drag and drop
- (BOOL)_shouldHighlightParentRows {
    return FALSE;
}

#pragma mark - Layout

- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row {
    NSRect rect = [super frameOfOutlineCellAtRow:row];
    rect.origin.x = -3;
    rect.size.width = 27;
    return rect;
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row {
    NSRect superFrame = [super frameOfCellAtColumn:column row:row];
    return NSMakeRect(0, superFrame.origin.y, [self bounds].size.width, superFrame.size.height);
}

#pragma mark - Misc

- (void)reloadVisibleItems {
    NSRange range = [self rowsInRect:[self visibleRect]];
    NSIndexSet *columns = [self columnIndexesInRect:[self visibleRect]];
    [self reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:range] columnIndexes:columns];
}

@end