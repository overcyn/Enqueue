#import "PRAlbumTableView2.h"


@implementation PRAlbumTableView2

@synthesize nextResponder__;

- (BOOL)becomeFirstResponder
{
	if ([self nextResponder__] != self && [self nextResponder__] != nil) {
		[[self window] makeFirstResponder:nextResponder__];
	}
	return TRUE;
}

@end
