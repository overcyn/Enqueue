#import "PRCollectionScrollView.h"

@implementation PRCollectionScrollView


- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] set];
    [NSBezierPath fillRect:[self bounds]];
}

@end
