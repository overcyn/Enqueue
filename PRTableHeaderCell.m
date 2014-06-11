#import "PRTableHeaderCell.h"


@implementation PRTableHeaderCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSTableHeaderView *tableHeaderView = (NSTableHeaderView *)controlView;
    NSImage *indicator = nil;
    for (NSTableColumn *i in [[tableHeaderView tableView] tableColumns]) {
        if ([i headerCell] == self) {
            indicator = [[tableHeaderView tableView] indicatorImageInTableColumn:i];
        }
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    [style setAlignment:[self alignment]];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont systemFontOfSize:11], NSFontAttributeName,
                                style, NSParagraphStyleAttributeName, nil];
    NSRect stringRect = NSMakeRect(cellFrame.origin.x + 6, 
                                   cellFrame.origin.y, 
                                   cellFrame.size.width - 12, 
                                   cellFrame.size.height);
    if (indicator) {
        stringRect.size.width -= 15;
    } 
    
    [[self stringValue] drawInRect:stringRect withAttributes:attributes];
    
    if (indicator) {
        [indicator drawInRect:NSMakeRect(cellFrame.origin.x + cellFrame.size.width - 15, cellFrame.origin.y + 3, 9, 9)
                     fromRect:NSZeroRect 
                    operation:NSCompositeSourceOver 
                     fraction:1.0 
               respectFlipped:TRUE 
                        hints:nil];
    }
}

@end