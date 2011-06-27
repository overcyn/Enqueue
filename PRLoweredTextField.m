#import "PRLoweredTextField.h"


@implementation PRLoweredTextField

- (void)awakeFromNib
{
	[super awakeFromNib];
	[[self cell] setBackgroundStyle:NSBackgroundStyleRaised];
}

@end
