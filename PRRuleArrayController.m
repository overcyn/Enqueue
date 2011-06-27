#import "PRRuleArrayController.h"


@implementation PRRuleArrayController

- (id)arrangedObjects
{
	NSArray *arrangedObjects;
	NSMutableArray *mutableArrangedObjects;
	
	mutableArrangedObjects = [NSMutableArray arrayWithArray:[super arrangedObjects]];
	[mutableArrangedObjects addObject:[NSNumber numberWithInt:0]];
	
	arrangedObjects = [NSArray arrayWithArray:mutableArrangedObjects];
	
	return arrangedObjects;
}

@end
