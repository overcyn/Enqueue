#import "NSTableView+Extensions.h"

@implementation NSTableView (Extensions)

- (void)scrollRowToVisiblePretty:(NSInteger)row {
    int topRow = row - 3;
    if (topRow < 0) {
        topRow = 0;
    }
    int botRow = row + 3;
    if (botRow > [self numberOfRows]) {
        botRow = [self numberOfRows] - 1;
    }
    NSRect topRect = [self rectOfRow:topRow];
    NSRect botRect = [self rectOfRow:botRow];
    [self scrollRectToVisible:NSUnionRect(topRect, botRect)];
}

- (void)PRHighlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending {
    for (NSTableColumn *i in [self tableColumns]) {
        if (i != tableColumn) {
            [[i tableView] setIndicatorImage:nil inTableColumn:i];  
        }
    }
    NSImage *indicatorImage = ascending ? [NSImage imageNamed:@"NSAscendingSortIndicator"] : [NSImage imageNamed:@"NSDescendingSortIndicator"];
    [[tableColumn tableView] setIndicatorImage:indicatorImage inTableColumn:tableColumn];   
    [[tableColumn tableView] setHighlightedTableColumn:tableColumn];
}

@end
