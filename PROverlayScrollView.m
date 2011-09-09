#import "PROverlayScrollView.h"

@implementation PROverlayScrollView

- (void)tile
{
	[super tile];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
        [[self contentView] setFrame:[self bounds]];
    }
}

@end
