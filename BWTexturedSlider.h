#import <Cocoa/Cocoa.h>


@interface BWTexturedSlider : NSSlider
{
	int trackHeight, indicatorIndex;
	NSRect sliderCellRect;
	NSButton *minButton, *maxButton;
}

@property (nonatomic) int indicatorIndex;
@property (retain) NSButton *minButton;
@property (retain) NSButton *maxButton;

//- (int)trackHeight;
//- (void)setTrackHeight:(int)newTrackHeight;

@end