#import "PRSliderCell.h"
#import "NSBezierPath+Extensions.h"


@implementation PRSliderCell

@synthesize indicator;

- (void)drawBarInside:(NSRect)cellFrame flipped:(BOOL)flipped
{	
    NSRect frame = cellFrame;
    frame.size.height -= 15;
    frame.origin.y += 7;
    frame.size.width -= 20;
    frame.origin.x += 10;
    
    NSGradient *fillGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [[NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0] blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]], 0.0,
                                 [[NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0] blendedColorWithFraction:0.1 ofColor:[NSColor blackColor]], 0.5, 
                                 [[NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0] blendedColorWithFraction:0.15 ofColor:[NSColor blackColor]], 1.0, 
                                 nil] autorelease];
    NSGradient *backGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.35 alpha:1.0], 0.0,
                                 [NSColor colorWithCalibratedWhite:0.55 alpha:1.0], 0.4, 
                                 [NSColor colorWithCalibratedWhite:0.6 alpha:1.0], 0.8,
                                 [NSColor colorWithCalibratedWhite:0.45 alpha:1.0], 1.0, 
                                 nil] autorelease];

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:3 yRadius:3];
    [path addClip];
    
    //draw background
	cellFrame = frame;
	[backGradient drawInRect:cellFrame angle:90.0];

//    // top border
//    cellFrame = frame;
//    NSPoint topLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+0.5);
//    NSPoint topRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y+0.5);
//    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
//    [NSBezierPath strokeLineFromPoint:topLeft toPoint:topRight];
//    
//    // bot border
//    cellFrame = frame;
//    NSPoint botLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+cellFrame.size.height-0.5);
//    NSPoint botRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y+cellFrame.size.height-0.5);
//    [NSBezierPath strokeLineFromPoint:botLeft toPoint:botRight];
//    
//    // left border
//    [NSBezierPath fillRect:[NSBezierPath rightBorderOfRect:frame]];
//    [NSBezierPath fillRect:[NSBezierPath leftBorderOfRect:frame]];
    
//    frame.origin.y += 1;
//    frame.size.height -= 2;
//    frame.origin.x += 1;
//    frame.size.width -= 2;
//    // Draw indicator
//    if (indicator) {
//        NSRect indicatorRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, 10, cellFrame.size.height);
//        [fillGradient drawInRect:indicatorRect angle:90.0];
//    }
//    cellFrame.origin.x += 10;
//    cellFrame.size.width -= 10;
    
    
//    [NSGraphicsContext saveGraphicsState];
//    [NSBezierPath clipRect:frame];
    //Fill
    NSRect fillRect;
    NSRect remainingRect;
    float slice = [self floatValue]/([self maxValue] - [self minValue]) * cellFrame.size.width;
    NSDivideRect(cellFrame, &fillRect, &remainingRect, slice, NSMinXEdge);    
    [fillGradient drawInRect:fillRect angle:90.0];
    
//    [NSGraphicsContext restoreGraphicsState];
//    
//    float width = fillRect.size.width + 10;
//    // top border
//    cellFrame = [[self controlView] frame];
//    topLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+0.5);
//    topRight = NSMakePoint(cellFrame.origin.x + width, cellFrame.origin.y+0.5);
//    [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] set];
//    [NSBezierPath strokeLineFromPoint:topLeft toPoint:topRight];
//    
//    // bot border
//    cellFrame = [[self controlView] frame];
//    botLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+cellFrame.size.height-0.5);
//    botRight = NSMakePoint(cellFrame.origin.x + width, cellFrame.origin.y+cellFrame.size.height-0.5);
//    [[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] set];
//    [NSBezierPath strokeLineFromPoint:botLeft toPoint:botRight];
    
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] set];
    [path stroke];
}

- (void)drawKnob:(NSRect)rect
{

}

- (BOOL)_usesCustomTrackImage
{
	return YES;
}

@end
