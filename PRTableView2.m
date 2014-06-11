#import "PRTableView2.h"
#import "PRNowPlayingController.h"
#import "PRCore.h"

@implementation PRTableView2

- (BOOL)acceptsFirstResponder
{
    return FALSE;
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
    } else {
        [super keyDown:event];
    }
}

// Disable default highlight color
- (id)_highlightColorForCell:(NSCell *)cell
{
    return nil;
}

// Draw custom higlights
- (void)highlightSelectionInClipRect:(NSRect)theClipRect
{    
    
}

@end
