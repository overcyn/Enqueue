#import "NSArray+Extensions.h"


@implementation NSArray (Extensions)

- (id)objectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate {
    NSUInteger idx = [self indexOfObjectPassingTest:predicate];
    if (idx == NSNotFound) {
        return nil;
    }
    return [self objectAtIndex:idx];
}

@end
