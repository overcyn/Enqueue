#import "PRTitleBarGradientView.h"


@implementation PRTitleBarGradientView

- (id)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) {return nil;}
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:4.0 yRadius:4.0] addClip];
    [super drawRect:dirtyRect];
}

- (NSView *)hitTest:(NSPoint)aPoint {
    return nil;
}

@end