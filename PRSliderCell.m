//
//  PRSliderCell.m
//  Lyre
//
//  Created by Kevin Dang on 3/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PRSliderCell.h"


@implementation PRSliderCell

@synthesize indicator;

- (void)drawBarInside:(NSRect)cellFrame flipped:(BOOL)flipped
{	
    NSGradient *fillGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.9 alpha:1.0], 0.0,
                                 [NSColor colorWithCalibratedWhite:0.85 alpha:1.0], 0.7, 
                                 [NSColor colorWithCalibratedWhite:0.75 alpha:1.0], 1.0, 
                                 nil] autorelease];
    NSGradient *backGradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.1 alpha:1.0], 0.0,
                                 [NSColor colorWithCalibratedWhite:0.3 alpha:1.0], 0.5, 
                                 [NSColor colorWithCalibratedWhite:0.4 alpha:1.0], 1.0, 
                                 nil] autorelease];

    //draw background
	cellFrame = [[self controlView] frame];
	[backGradient drawInRect:cellFrame angle:90.0];
    
    if (indicator) {
        NSRect indicatorRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, 8, cellFrame.size.height);
        [fillGradient drawInRect:indicatorRect angle:90.0];
        cellFrame.origin.x += 8;
        cellFrame.size.width -= 8;
    }
    
    NSRect fillRect;
    NSRect remainingRect;
    float slice = [self floatValue]/([self maxValue] - [self minValue]) * cellFrame.size.width;
    NSDivideRect(cellFrame, &fillRect, &remainingRect, slice, NSMinXEdge);    
    [fillGradient drawInRect:fillRect angle:90.0];
    
    // top border
    cellFrame = [[self controlView] frame];
    NSPoint topLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+0.5);
    NSPoint topRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y+0.5);
    [[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:topLeft toPoint:topRight];
    
    // bot border
    cellFrame = [[self controlView] frame];
    NSPoint botLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y+cellFrame.size.height-0.5);
    NSPoint botRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y+cellFrame.size.height-0.5);
    [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] set];
    [NSBezierPath strokeLineFromPoint:botLeft toPoint:botRight];
}

- (void)drawKnob:(NSRect)rect
{

}

- (BOOL)_usesCustomTrackImage
{
	return YES;
}


@end
