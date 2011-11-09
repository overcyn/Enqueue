#import "PRBackgroundView.h"
#import "NSColor+Extensions.h"


@implementation PRBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{       
    [[NSBezierPath bezierPathWithRect:dirtyRect] addClip];
    NSRect bounds = [self bounds];
    bounds.size.width -= 1;
    bounds.origin.x += 0.5;
    

    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:0.5]];
    [shadow setShadowOffset:NSMakeSize(0,-2)];
    [shadow setShadowBlurRadius:4];
//	[shadow set];
    
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:0 yRadius:0];
    [[NSColor PRForegroundColor] set];
    [bezierPath fill];
    [[NSColor PRForegroundBorderColor] set];
    [bezierPath stroke];
}

@end
