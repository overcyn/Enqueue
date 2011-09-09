#import "PRAlbumTableView.h"
#import "PRAlbumListViewController.h"

@implementation PRAlbumTableView

- (void)drawGridInClipRect:(NSRect)rect
{
	NSRange columnRange = [self rowsInRect:rect];
	[[NSColor gridColor] set];
	[NSBezierPath setDefaultLineWidth:0];
	for (int i = columnRange.location; i < NSMaxRange(columnRange); i++) {
		if ([(PRAlbumListViewController *)[self delegate] shouldDrawGridForRow:i tableView:self]) {
			NSRect colRect = [self rectOfRow:i];
			NSPoint startPoint = NSMakePoint(colRect.origin.x, colRect.origin.y + colRect.size.height - 0.5);
			NSPoint endPoint = NSMakePoint(colRect.origin.x + colRect.size.width, colRect.origin.y + colRect.size.height - 0.5);
			[NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
		}
	}
}

- (void)highlightSelectionInClipRect:(NSRect)theClipRect
{
	NSRange	visibleRowIndexes = [self rowsInRect:theClipRect];
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	
	// if the view is focused, use highlight color, otherwise use the out-of-focus highlight color
	if (self == [[self window] firstResponder]
		&& [[self window] isMainWindow]
		&& [[self window] isKeyWindow]) {
		[highlightColor set];
	} else {
		[secondaryHighlightColor set];
	}
	
	// draw highlight for the visible, selected rows
    int	row = visibleRowIndexes.location;
	int endRow = row + visibleRowIndexes.length;
    for (; row < endRow; row++) {
		int actualRow = [(PRAlbumListViewController *)[self delegate] dbRowForTableRow:row];
		if ([selectedRowIndexes containsIndex:row] && actualRow != -1) {
			NSRect rectOfRow = [self rectOfRow:row]; 
            NSRect rowRect;
			rowRect.origin = rectOfRow.origin;
			rowRect.size.width = rectOfRow.size.width;
			rowRect.origin.y = rowRect.origin.y;
			
//			actualRow = [(PRAlbumListViewController *)[self delegate] dbRowForTableRow:row + 1];
			
			rowRect.size.height = rectOfRow.size.height - 0.3;
			[[NSBezierPath bezierPathWithRect:rowRect] fill];
		}
	}
}

@end