#import "PRBackgroundView.h"
#import "NSColor+Extensions.h"


@implementation PRBackgroundView

- (void)drawRect:(NSRect)dirtyRect {
    [[NSBezierPath bezierPathWithRect:dirtyRect] addClip];
    NSRect bounds = [self bounds];
    bounds.size.width -= 1;
    bounds.origin.x += 0.5;
    bounds.size.height += 2;
    bounds.origin.y -= 1;
    
        
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:0 yRadius:0];
    [[NSColor PRForegroundColor] set];
    [bezierPath fill];
    [[NSColor PRForegroundBorderColor] set];
    [bezierPath stroke];
}

@end
