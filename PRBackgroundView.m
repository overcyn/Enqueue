#import "PRBackgroundView.h"


@implementation PRBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{       
    [[NSBezierPath bezierPathWithRect:dirtyRect] addClip];
    NSRect bounds = [self bounds];
    bounds.size.width -= 20;
    bounds.origin.x += 10;
    bounds.size.height -= 50;
    bounds.origin.y += 30;
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:0.5]];
    [shadow setShadowOffset:NSMakeSize(0,-2)];
    [shadow setShadowBlurRadius:5];
	[shadow set];
    
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4 yRadius:4];
    [[NSColor colorWithDeviceWhite:1.0 alpha:1.0] set];
    [bezierPath fill];
}

@end
