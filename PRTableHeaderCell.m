#import "PRTableHeaderCell.h"
#import "NSImage+FlippedDrawing.h"

@implementation PRTableHeaderCell

//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
//{
//    [[self stringValue] drawInRect:cellFrame withAttributes:nil];
//}
// 
//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
//{
//    NSGradient *gradient_ = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceWhite:0.94 alpha:1.0] 
//                                                           endingColor:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]] autorelease];
//    [gradient_ drawInRect:cellFrame angle:90.0];
//    
//    [[NSColor lightGrayColor] set];
//    [NSBezierPath strokeRect:cellFrame];
//
//    [self drawInteriorWithFrame:cellFrame inView:controlView];
//}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSTableHeaderView *tableHeaderView = (NSTableHeaderView *)controlView;
    NSImage *indicator = nil;
    
    for (NSTableColumn *i in [[tableHeaderView tableView] tableColumns]) {
        if ([i headerCell] == self) {
            indicator = [[tableHeaderView tableView] indicatorImageInTableColumn:i];
        }
    }
    
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
    [style setAlignment:[self alignment]];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont systemFontOfSize:11], NSFontAttributeName,
                                style, NSParagraphStyleAttributeName,
                                nil];
    NSRect stringRect = NSMakeRect(cellFrame.origin.x + 6, 
                                   cellFrame.origin.y, 
                                   cellFrame.size.width - 12, 
                                   cellFrame.size.height);
    if (indicator) {
        stringRect.size.width -= 15;
    }
    
    [[self stringValue] drawInRect:stringRect withAttributes:attributes];
    
    if (indicator) {
        NSRect indicatorRect = NSMakeRect(cellFrame.origin.x + cellFrame.size.width - 15, 
                                          cellFrame.origin.y + 3, 
                                          9, 
                                          9);
        [indicator drawAdjustedInRect:indicatorRect 
                             fromRect:NSZeroRect 
                            operation:NSCompositeSourceOver 
                             fraction:1.0];
    }
}

@end