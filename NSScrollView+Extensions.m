#import "NSScrollView+Extensions.h"

@implementation NSScrollView (Extensions)

- (void)scrollToTop {
    NSPoint newScrollOrigin;
    if ([[self documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0, 0.0);
    } else {
        newScrollOrigin = NSMakePoint(0.0, NSMaxY([[self documentView] frame]) - NSHeight([[self contentView] bounds]));
    }
    [[self documentView] scrollPoint:newScrollOrigin];
    
}

- (void)scrollToBottom {
    NSPoint newScrollOrigin;
    if ([[self documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0, NSMaxY([[self documentView] frame]) - NSHeight([[self contentView] bounds]));
    } else {
        newScrollOrigin = NSMakePoint(0.0, 0.0);
    }
    [[self documentView] scrollPoint:newScrollOrigin];
}

@end
