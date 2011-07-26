#import "PRRuleArrayController.h"


@implementation PRRuleArrayController

- (id)arrangedObjects
{	
	NSMutableArray *mutableArrangedObjects = [NSMutableArray arrayWithArray:[super arrangedObjects]];
	[mutableArrangedObjects addObject:[NSNumber numberWithInt:0]];

	return [NSArray arrayWithArray:mutableArrangedObjects];
}

@end
