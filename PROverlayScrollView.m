#import "PROverlayScrollView.h"


@implementation PROverlayScrollView

- (void)tile
{
	[super tile];	
	[[self contentView] setFrame:[self bounds]];
}

@end
