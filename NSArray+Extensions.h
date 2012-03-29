#import <Foundation/Foundation.h>


@interface NSArray (Extensions)
- (id)objectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
@end
