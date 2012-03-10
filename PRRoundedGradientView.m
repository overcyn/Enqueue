#import "PRRoundedGradientView.h"


@implementation PRRoundedGradientView

- (void)drawRect:(NSRect)dirtyRect {
    NSRect clip = [self bounds];
    [[NSBezierPath bezierPathWithRoundedRect:clip xRadius:4.0 yRadius:4.0] addClip];
    [super drawRect:dirtyRect];
}

@end