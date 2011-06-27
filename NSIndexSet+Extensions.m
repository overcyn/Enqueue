#import "NSIndexSet+Extensions.h"


@implementation NSIndexSet (Extensions)

- (NSUInteger)nthIndex:(NSUInteger)n
{
	NSUInteger count = 0;
	NSUInteger index = 0;
	
	while ((index = [self indexGreaterThanOrEqualToIndex:index]) != NSNotFound) {
		count++;		
		if (count == n) {
			return index;
		}
		index++;
	}
	
	return NSNotFound;
}

+ (NSIndexSet *)indexSetWithArray:(NSArray *)array
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSNumber *i in array) {
        [indexes addIndex:[i intValue]];
    }
    return indexes;    
}

@end
