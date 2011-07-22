#import "PRButtonCell.h"
#import "PRSegmentedCell.h"


@implementation PRButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    cellFrame.size.height = 20;
    cellFrame.origin.y += .5;
    cellFrame.size.height -= 1;
    cellFrame.origin.x += .5;
    cellFrame.size.width -= 1;
    
    // Draw border    
    [NSGraphicsContext saveGraphicsState];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.3]];
    [shadow setShadowOffset:NSMakeSize(0, -1.0)];
    [shadow setShadowBlurRadius:0];
    [shadow set];
    NSBezierPath *frame = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:3 yRadius:3];
    [[NSColor colorWithCalibratedWhite:0.55 alpha:1.0] set];
    [frame stroke];
    [NSGraphicsContext restoreGraphicsState];
    
    // Draw background
    [NSGraphicsContext saveGraphicsState];
    cellFrame.origin.y += .5;
    cellFrame.size.height -= 1;
    cellFrame.origin.x += .5;
    cellFrame.size.width -= 1;
    frame = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:3 yRadius:3];
    [frame addClip];

    if (![self isHighlighted]) {
        NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.97 alpha:1.0], 0.0, 
                                 [NSColor colorWithCalibratedWhite:0.86 alpha:1.0], 1.0,
                                 nil] autorelease];
        [gradient drawInRect:cellFrame angle:90];
    } else {
        NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.0 alpha:0.3], 0.0,
                                 [NSColor colorWithCalibratedWhite:0.0 alpha:0.2], 0.05,
                                 [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 0.2,
                                 [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 0.9,
                                 [NSColor colorWithCalibratedWhite:0.0 alpha:0.2], 1.0,
                                 nil] autorelease];
        [gradient drawInRect:cellFrame angle:90];
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 0.0,
                     [NSColor colorWithCalibratedWhite:0.0 alpha:0.0], 0.1,
                     [NSColor colorWithCalibratedWhite:0.0 alpha:0.0], 0.9,
                     [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 1.0,
                     nil] autorelease];
        [gradient drawInRect:cellFrame angle:0];
    }
    [NSGraphicsContext restoreGraphicsState];
    
    // Draw Interior
    [self drawInteriorWithFrame:cellFrame inView:controlView];    
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSImage *image = [self image];
    NSRect drawRect = NSMakeRect(round(cellFrame.origin.x + (cellFrame.size.width - [image size].width) / 2), 
                                 round(cellFrame.origin.y + (cellFrame.size.height - [image size].height) / 2), 
                                 [image size].height, [image size].width);
    [image drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:TRUE hints:nil];
}

@end