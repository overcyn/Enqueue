#import "PRSliderCell.h"


@implementation PRSliderCell

@synthesize indicator;

- (void)drawBarInside:(NSRect)cellFrame flipped:(BOOL)flipped
{	
    NSGradient *fillGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.94 alpha:1.0], 0.0,
                                 [NSColor colorWithCalibratedWhite:0.85 alpha:1.0], 0.5, 
                                 [NSColor colorWithCalibratedWhite:0.8 alpha:1.0], 1.0, 
                                 nil] autorelease];
    NSGradient *backGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.2 alpha:1.0], 0.0,
                                 [NSColor colorWithCalibratedWhite:0.5 alpha:1.0], 0.4, 
                                 [NSColor colorWithCalibratedWhite:0.5 alpha:1.0], 0.8,
                                 [NSColor colorWithCalibratedWhite:0.4 alpha:1.0], 1.0, 
                                 nil] autorelease];

    //draw background
	cellFrame = [[self controlView] frame];
	[backGradient drawInRect:cellFrame angle:90.0];

    // top border
    cellFrame = [[self controlView] frame];
    NSPoint topLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+0.5);
    NSPoint topRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y+0.5);
    [[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:topLeft toPoint:topRight];
    
    // bot border
    cellFrame = [[self controlView] frame];
    NSPoint botLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+cellFrame.size.height-0.5);
    NSPoint botRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y+cellFrame.size.height-0.5);
    [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:botLeft toPoint:botRight];
    
    cellFrame.origin.y += 1;
    cellFrame.size.height -= 2;
    
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithCalibratedWhite:0.0 alpha:0.05], 0.0, 
                             [NSColor colorWithCalibratedWhite:0.0 alpha:0], 0.3,
                             [NSColor colorWithCalibratedWhite:0.0 alpha:0], 0.7,
                             [NSColor colorWithCalibratedWhite:0.0 alpha:0.05], 1.0,
                             nil] autorelease];
    
    // Draw indicator
    if (indicator) {
        NSRect indicatorRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, 10, cellFrame.size.height);
        [fillGradient drawInRect:indicatorRect angle:90.0];
        [NSGraphicsContext saveGraphicsState];
        [NSBezierPath clipRect:indicatorRect];
        [gradient drawInRect:cellFrame angle:0.0];
        [NSGraphicsContext restoreGraphicsState];
    }
    cellFrame.origin.x += 10;
    cellFrame.size.width -= 10;
    
    // Fill
    NSRect fillRect;
    NSRect remainingRect;
    float slice = [self floatValue]/([self maxValue] - [self minValue]) * cellFrame.size.width;
    NSDivideRect(cellFrame, &fillRect, &remainingRect, slice, NSMinXEdge);    
    [fillGradient drawInRect:fillRect angle:90.0];
    
    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath clipRect:NSInsetRect(fillRect, 0, -1)];
    [gradient drawInRect:cellFrame angle:0.0];
    [NSGraphicsContext restoreGraphicsState];
    
    float width = fillRect.size.width + 10;
    // top fill border
    cellFrame = [[self controlView] frame];
    topLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+0.5);
    topRight = NSMakePoint(cellFrame.origin.x + width, cellFrame.origin.y+0.5);
    [[NSColor colorWithCalibratedWhite:0.37 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:topLeft toPoint:topRight];
    
    // bot fill border
    cellFrame = [[self controlView] frame];
    botLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+cellFrame.size.height-0.5);
    botRight = NSMakePoint(cellFrame.origin.x + width, cellFrame.origin.y+cellFrame.size.height-0.5);
    [[NSColor colorWithCalibratedWhite:0.35 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:botLeft toPoint:botRight];
    
    // gradient over
    gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0.15], 0.0, 
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0], 0.5,
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0.15], 1.0,
                 nil] autorelease];
    [gradient drawInRect:NSInsetRect(cellFrame, 0, 1) angle:0.0];
}

- (void)drawKnob:(NSRect)rect
{

}

- (BOOL)_usesCustomTrackImage
{
	return YES;
}


@end
