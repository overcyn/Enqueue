#import "NSArray+Extensions.h"


@implementation NSArray (Extensions)

- (id)objectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate {
    NSUInteger idx = [self indexOfObjectPassingTest:predicate];
    if (idx == NSNotFound) {
        return nil;
    }
    return [self objectAtIndex:idx];
}

- (NSMutableArray *)PRMap:(id(^)(NSInteger idx, id obj))block {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    for (NSInteger i = 0; i < [self count]; i++) {
        id obj = block(i, [self objectAtIndex:i]);
        if (obj) {
            [array addObject:obj];
        }
    }
    return array;
}

@end
