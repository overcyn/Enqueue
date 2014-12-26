#import <AppKit/AppKit.h>


@interface NSTableView (Extensions)
- (void)scrollRowToVisiblePretty:(NSInteger)row;
- (void)PRHighlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending;
@end
