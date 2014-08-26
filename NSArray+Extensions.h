#import <Foundation/Foundation.h>


@interface NSArray (Extensions)
- (id)objectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
- (NSMutableArray *)PRMap:(id(^)(NSInteger idx, id obj))block;
@end
