#import <Cocoa/Cocoa.h>


@interface NSIndexSet (Extensions) 

- (NSUInteger)nthIndex:(NSUInteger)n;
- (NSUInteger)positionOfIndex:(NSUInteger)index;
+ (NSIndexSet *)indexSetWithArray:(NSArray *)array;

@end
