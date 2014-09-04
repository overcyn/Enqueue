#import "NSIndexSet+Extensions.h"


@implementation NSIndexSet (Extensions)

- (NSUInteger)positionOfIndex:(NSUInteger)index {
    return [self countOfIndexesInRange:NSMakeRange(0, index+1)];
}

- (NSUInteger)indexAtPosition:(NSUInteger)position {
    NSUInteger count = 0;
    NSUInteger index = [self firstIndex];
    while (index != NSNotFound) {
        if (count == position) {
            return index;
        }
        index = [self indexGreaterThanIndex:index];
        count++;
    }
    return NSNotFound;
}

+ (NSIndexSet *)indexSetWithArray:(NSArray *)array {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (NSNumber *i in array) {
        [indexes addIndex:[i intValue]];
    }
    return indexes;    
}

- (NSIndexSet *)intersectionWithIndexSet:(NSIndexSet *)indexSet {
    NSMutableIndexSet *intersection = [NSMutableIndexSet indexSet];
    NSUInteger index = [self firstIndex];
    while (index != NSNotFound) {
        if ([indexSet containsIndex:index]) {
            [intersection addIndex:index];
        }
        index = [self indexGreaterThanIndex:index];
    }
    return intersection;
}

@end
