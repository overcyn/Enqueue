#import "PRRoundedGradientView.h"

@implementation PRRoundedGradientView

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect clip = [self bounds];
    clip.origin.x -= 7;
    clip.origin.y -= 7;
    clip.size.width += 7;
    clip.size.height += 7;
    [[NSBezierPath bezierPathWithRoundedRect:clip xRadius:4.0 yRadius:4.0] addClip];
    [super drawRect:dirtyRect];
}

@end