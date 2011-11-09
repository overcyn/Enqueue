#import "PRPaneSplitView.h"


@implementation PRPaneSplitView

- (CGFloat)dividerThickness
{
    return 10.0;
}

- (void)drawDividerInRect:(NSRect)rect
{
    if ([self dividerStyle] == NSSplitViewDividerStyleThick) {
        rect.size.width += 2;
        rect.origin.x -= 1;
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]
                                                              endingColor:[NSColor colorWithCalibratedWhite:0.93 alpha:1.0]] autorelease];
        [gradient drawInRect:rect angle:90];
        [[NSColor colorWithDeviceWhite:0.40 alpha:1.0] set];
        [NSBezierPath strokeRect:rect];
    } else {
        [super drawDividerInRect:rect];
    }

}

@end
