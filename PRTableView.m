#import "PRTableView.h"
#import "PRNowPlayingController.h"
#import "PRCore.h"
#import "PRNowPlayingViewController.h"


@implementation PRTableView

@synthesize highlightColor;
@synthesize secondaryHighlightColor;
@synthesize slideback;
@synthesize bordered;

- (void)awakeFromNib
{
    [self setHighlightColor:[NSColor colorWithCalibratedRed:59./255 green:128./255 blue:223./255 alpha:1.0]];
    [self setSecondaryHighlightColor:[NSColor secondarySelectedControlColor]];
    [self setSlideback:TRUE];
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend
{
    if ([[self delegate] respondsToSelector:@selector(tableView:selectionIndexesForProposedSelection:)]) {
        indexes = [[self delegate] tableView:self selectionIndexesForProposedSelection:indexes];
    }
    [super selectRowIndexes:indexes byExtendingSelection:extend];
}

- (void)rightMouseDown:(NSEvent *)event
{
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	int row = [self rowAtPoint:p];
	
	if (![[self selectedRowIndexes] containsIndex:row]) {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
	}
	[super rightMouseDown:event];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	if ([[self selectedRowIndexes] count] == 0) {
		return nil;
	}
	return [super menuForEvent:theEvent];
}

- (void)mouseDown:(NSEvent *)event
{
    if (![[self window] isKeyWindow] ||
        (([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask) ||
//		(([event modifierFlags] & NSControlKeyMask) == NSControlKeyMask) ||
		(([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask)) {
		[super mouseDown:event];
		return;
	}
	
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
	int row = [self rowAtPoint:p];
	if (![[self selectedRowIndexes] containsIndex:row]) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
	}
	[super mouseDown:event];
}


- (id)_highlightColorForCell:(NSCell *)cell
{
	// we need to override this to return nil
	// or we'll see the default selection rectangle when the app is running 
	// in any OS before leopard
	
	// you can also return a color if you simply want to change the table's default selection color
    return nil;
}

- (void)highlightSelectionInClipRect:(NSRect)theClipRect
{	
	// this method is asking us to draw the hightlights for 
	// all of the selected rows that are visible inside theClipRect
	
	// 1. get the range of row indexes that are currently visible
	// 2. get a list of selected rows
	// 3. iterate over the visible rows and if their index is selected
	// 4. draw our custom highlight in the rect of that row.
	
	NSRange	visibleRowIndexes = [self rowsInRect:theClipRect];
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	int	row = visibleRowIndexes.location;
	int endRow = row + visibleRowIndexes.length;
	// draw highlight for the visible, selected rows
    for (; row < endRow; row++) {
		if([selectedRowIndexes containsIndex:row]) {
            NSColor *color;
            if (self == [[self window] firstResponder] && [[self window] isKeyWindow]) {
                color = highlightColor;
            } else {
                color = secondaryHighlightColor;
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

+ (id)_dropHighlightBackgroundColor
{
	// Called in Leopard
	// don't want a background color for drop highlights
	return [NSColor clearColor];
}

- (void)_drawDropHighlightBetweenUpperRow:(int)theUpperRowIndex 
							  andLowerRow:(int)theLowerRowIndex 
									onRow:(int)theRow 
								 atOffset:(float)theOffset
{
	// Called in Leopard
	[self performDrawDropHighlightBetweenUpperRow:theUpperRowIndex
									  andLowerRow:theLowerRowIndex
										 atOffset:theOffset];
}

- (void)_drawDropHighlightBetweenUpperRow:(int)theUpperRowIndex 
							  andLowerRow:(int)theLowerRowIndex 
								 atOffset:(float)theOffset
{
	// Called in Tiger
	[self performDrawDropHighlightBetweenUpperRow:theUpperRowIndex
									  andLowerRow:theLowerRowIndex
										 atOffset:theOffset];
}

- (void)performDrawDropHighlightBetweenUpperRow:(int)theUpperRowIndex 
									andLowerRow:(int)theLowerRowIndex 
									   atOffset:(float)theOffset
{
	// if you don't want a drop highlight between rows, leave this method blank
	
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

- (void)keyDown:(NSEvent *)event
{
	PRNowPlayingController *now = [(PRCore *)[NSApp delegate] now];
    
    if ([[event characters] length] != 1) {
        [super keyDown:event];
        return;
    }
	
	if ([[event characters] characterAtIndex:0] == 0xf703) {
		[now playNext];
	} else if ([[event characters] characterAtIndex:0] == 0xf702) {
		[now playPrevious];
	} else if ([[event characters] characterAtIndex:0] == 0x20) {
		[now playPause];
	} else if ([[event characters] characterAtIndex:0] == 0x7F) {
		[[NSApplication sharedApplication] sendAction:@selector(delete:) to:nil from:self];
	} else if ([[event characters] characterAtIndex:0] == 0xf728) {
		[[NSApplication sharedApplication] sendAction:@selector(delete:) to:nil from:self];
    }
    else {
		[super keyDown:event];
	}
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)point operation:(NSDragOperation)operation
{
    if ([self dataSource] && [[self dataSource] respondsToSelector:@selector(draggedImage:endedAt:operation:)]) {
        [(PRNowPlayingViewController *)[self dataSource] draggedImage:image endedAt:point operation:operation];
    }
    [super draggedImage:image endedAt:point operation:operation];
}

- (void)draggedImage:(NSImage *)image movedTo:(NSPoint)point
{
    if ([self dataSource] && [[self dataSource] respondsToSelector:@selector(draggedImage:movedTo:)]) {
         [(PRNowPlayingViewController *)[self dataSource] draggedImage:image movedTo:point];
    }
    [super draggedImage:image movedTo:point];
}

- (void)dragImage:(NSImage *)anImage 
               at:(NSPoint)imageLoc 
           offset:(NSSize)mouseOffset
            event:(NSEvent *)theEvent 
       pasteboard:(NSPasteboard *)pboard 
           source:(id)sourceObject
        slideBack:(BOOL)slideBack
{
    [super dragImage:anImage 
                  at:imageLoc 
              offset:mouseOffset 
               event:theEvent 
          pasteboard:pboard 
              source:sourceObject 
           slideBack:slideback];
}

- (void)cancelOperation:(id)sender
{
    if ([self currentEditor] != nil) {
        [self abortEditing];
        
        // We lose focus so re-establish
        [[self window] makeFirstResponder:self];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    if ([self bordered] == 1) {
        [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
        [NSBezierPath strokeLineFromPoint:[self frame].origin toPoint:NSMakePoint([self frame].origin.x + [self frame].size.width, [self frame].origin.y)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint([self frame].origin.x, [self frame].origin.y + [self frame].size.height)
                                  toPoint:NSMakePoint([self frame].origin.x + [self frame].size.width, [self frame].origin.y + [self frame].size.height)];
    } else if ([self bordered] == 2) {
        NSBezierPath *bezierPath2 = [NSBezierPath bezierPathWithRoundedRect:[self frame] xRadius:5.0 yRadius:5.0];
        [bezierPath2 stroke];        
    }
}

- (void)_drawContextMenuHighlightForIndexes:(id)arg1 clipRect:(struct CGRect)arg2
{
    [self highlightSelectionInClipRect:NSRectFromCGRect(arg2)];
    NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
    NSInteger i = [selectedRowIndexes firstIndex];
    while (i != NSNotFound) {
        for (int j = 0; j < [self numberOfColumns]; j++) {
            NSRect intersection = [self frameOfCellAtColumn:j row:i];
            [self _drawContentsAtRow:i column:j withCellFrame:intersection];
        }
        i = [selectedRowIndexes indexGreaterThanIndex:i];
    }
}

@end
