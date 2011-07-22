#import "PROverlayScrollView.h"

#ifndef NSAppKitVersionNumber10_6
#define NSAppKitVersionNumber10_6 1038
#endif


@implementation PROverlayScrollView

- (void)tile
{
	[super tile];
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {

    } else {
        [[self contentView] setFrame:[self bounds]];
    }
}

@end
