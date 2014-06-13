#import "PRPaneSplitView.h"


@implementation PRPaneSplitView

- (CGFloat)dividerThickness {
    if ([self dividerStyle] == NSSplitViewDividerStyleThick) {
        return 10.0;
    }
    return [super dividerThickness];
}

- (void)drawDividerInRect:(NSRect)rect {
    if ([self dividerStyle] == NSSplitViewDividerStyleThick) {
        rect.size.width += 2;
        rect.origin.x -= 1;
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.93 alpha:1.0]];
        [gradient drawInRect:rect angle:90];
        
        // Only draw top border. Tableview will has its own top border.
        rect.size.height = 1;
        [[NSColor colorWithDeviceWhite:0.68 alpha:1.0] set];
        [NSBezierPath fillRect:rect];
    } else {
        [super drawDividerInRect:rect];
    }
}

@end
