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

@end
