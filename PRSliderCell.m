#import "PRSliderCell.h"
#import "NSBezierPath+Extensions.h"


@implementation PRSliderCell

- (void)drawBarInside:(NSRect)cellFrame flipped:(BOOL)flipped {
    NSRect frame = cellFrame;
    frame.size.height -= 15;
    frame.origin.y += 7;
    frame.size.width -= 20;
    frame.origin.x += 10;
    NSColor *color = [NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0];
    NSGradient *fillGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                 [color blendedColorWithFraction:0.1 ofColor:[NSColor blackColor]], 0.0,
                                 [color blendedColorWithFraction:0.3 ofColor:[NSColor blackColor]], 0.5, 
                                 [color blendedColorWithFraction:0.25 ofColor:[NSColor blackColor]], 1.0, 
                                 nil];
    NSGradient *backGradient = [[NSGradient alloc] initWithColorsAndLocations:
                                 [color blendedColorWithFraction:0.1 ofColor:[NSColor blackColor]], 0.0,
                                 nil];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:3 yRadius:3];
    
    // background
    cellFrame = frame;
    [backGradient drawInRect:cellFrame angle:90.0];

    // fill
    NSRect fillRect;
    NSRect remainingRect;
    float slice = [self floatValue]/([self maxValue] - [self minValue]) * cellFrame.size.width;
    NSDivideRect(cellFrame, &fillRect, &remainingRect, slice, NSMinXEdge);    
    [fillGradient drawInRect:fillRect angle:90.0];
    
    // border
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.80] set];
    [path stroke];
    [[self controlView] setNeedsDisplay:TRUE];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView {
    cellFrame = [self drawingRectForBounds:cellFrame];
    [self drawBarInside:cellFrame flipped:[controlView isFlipped]];
    [self drawKnob];
}

- (void)drawKnob:(NSRect)rect {
    // no-op
}

- (BOOL)_usesCustomTrackImage {
    return YES;
}

@end
