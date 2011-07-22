#import "PRSegmentedCell.h"

#ifndef NSAppKitVersionNumber10_6
#define NSAppKitVersionNumber10_6 1038
#endif

@implementation PRSegmentedCell

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
    [[NSColor colorWithCalibratedWhite:COLOR_2 alpha:1.0] set];
    [frame stroke];
    [NSGraphicsContext restoreGraphicsState];
    NSRect cellFrame2 = cellFrame;
        
    // Draw background
    [NSGraphicsContext saveGraphicsState];
    cellFrame.origin.y += .5;
    cellFrame.size.height -= 1;
    cellFrame.origin.x += .5;
    cellFrame.size.width -= 1;
    frame = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:3 yRadius:3];
    [frame addClip];
    NSGradient *gradientAlt = [[[NSGradient alloc] initWithColorsAndLocations:
                                [NSColor colorWithCalibratedWhite:0.0 alpha:0.3], 0.0,
                                [NSColor colorWithCalibratedWhite:0.0 alpha:0.2], 0.05,
                                [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 0.2,
                                [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 0.9,
                                [NSColor colorWithCalibratedWhite:0.0 alpha:0.2], 1.0,
                                nil] autorelease];
    [gradientAlt drawInRect:cellFrame angle:90];
    gradientAlt = [[[NSGradient alloc] initWithColorsAndLocations:
                    [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 0.0,
                    [NSColor colorWithCalibratedWhite:0.0 alpha:0.0], 0.05,
                    [NSColor colorWithCalibratedWhite:0.0 alpha:0.0], 0.95,
                    [NSColor colorWithCalibratedWhite:0.0 alpha:0.1], 1.0,
                    nil] autorelease];
    [gradientAlt drawInRect:cellFrame angle:0];
    [NSGraphicsContext restoreGraphicsState];
    
    // Draw selected
    [NSGraphicsContext saveGraphicsState];
    [frame addClip];
    float xOrigin = cellFrame2.origin.x;
    for (int i = 0; i < [self segmentCount]; i++) {
        NSRect segmentRect = NSMakeRect(xOrigin, cellFrame2.origin.y - 2, round(cellFrame2.size.width / [self segmentCount])+0.5, cellFrame2.size.height + 4);
        xOrigin += round(cellFrame2.size.width / [self segmentCount])- 0.5;
        
        if (![self isSelectedForSegment:i]) {
            NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                     [NSColor colorWithCalibratedWhite:0.97 alpha:1.0], 0.0, 
                                     [NSColor colorWithCalibratedWhite:0.86 alpha:1.0], 1.0,
                                     nil] autorelease];
            NSBezierPath *segmentBezierPath = [NSBezierPath bezierPathWithRoundedRect:segmentRect xRadius:0 yRadius:0];
            [[NSColor colorWithCalibratedWhite:0.45 alpha:1.0] set];
            [segmentBezierPath stroke];
            [segmentBezierPath addClip];
            [gradient drawInRect:segmentRect angle:90];
        }
    }
    [NSGraphicsContext restoreGraphicsState];
    
    // Draw Interior
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect cellFrame2 = cellFrame;
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
        cellFrame2.origin.y -= 2;
    }
    for (int i = 0; i < [self segmentCount]; i++) {
        [[self imageForSegment:i] setTemplate:FALSE];
    }
    [super drawInteriorWithFrame:cellFrame2 inView:controlView];
}

@end