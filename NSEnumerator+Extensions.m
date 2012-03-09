#import "NSEnumerator+Extensions.h"

@implementation NSEnumerator (NSEnumerator_Extensions)

- (NSArray *)nextXObjects:(int)x {
    id object;
    NSMutableArray *objects = [NSMutableArray array];
    while ((object = [self nextObject])) {
        [objects addObject:object];
        if ([objects count] > x) {
            break;
        }
    }
    if ([objects count] == 0) {
        return nil;
    }
    return objects;
}

@end
