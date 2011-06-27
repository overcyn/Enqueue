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
    NSImage *trackFillImage = [NSImage imageNamed:@"TexturedSliderTrackFill.tiff"];
    NSImage *trackRightImage = [NSImage imageNamed:@"TexturedSliderTrackRight2.tiff"];
    NSImage *trackLeftImage = [NSImage imageNamed:@"TexturedSliderTrackLeft2.tiff"];
    NSImage *trackUnFillImage = [NSImage imageNamed:@"TexturedSliderTrackUnFill.tiff"];
	NSRect slideRect = cellFrame;
	
    slideRect.size.height = trackFillImage.size.height;
	slideRect.origin.y += roundf((cellFrame.size.height - slideRect.size.height) / 2);
    
    NSDrawThreePartImage(slideRect, trackLeftImage, trackFillImage, trackRightImage, NO, NSCompositeSourceOver, 1, flipped);
        
    slideRect.origin.x += 1;
    slideRect.size.width -= 2;
    
    if (indicator) {
        [[NSColor colorWithPatternImage:[NSImage imageNamed:@"TexturedSliderTrackUnFill.tif"]] set];
        NSDrawThreePartImage(NSMakeRect(slideRect.origin.x, slideRect.origin.y, 4, slideRect.size.height), trackUnFillImage, trackUnFillImage, trackUnFillImage, NO, NSCompositeSourceOver, 1, flipped);
        slideRect.origin.x += 4;
        slideRect.size.width -= 4;
    }
    
    NSRect fillRect;
    NSRect remainingRect;
    float slice = [self floatValue]/([self maxValue] - [self minValue]) * slideRect.size.width;

    NSDivideRect(slideRect, &fillRect, &remainingRect, slice, NSMinXEdge);    
    NSDrawThreePartImage(fillRect, trackUnFillImage, trackUnFillImage, trackUnFillImage, NO, NSCompositeSourceOver, 1, flipped);
}

- (void)drawKnob:(NSRect)rect
{

}

- (BOOL)_usesCustomTrackImage
{
	return YES;
}


@end
