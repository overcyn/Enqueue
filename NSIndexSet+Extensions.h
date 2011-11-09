#import <Cocoa/Cocoa.h>


@interface NSIndexSet (Extensions) 

- (NSUInteger)indexAtPosition:(NSUInteger)position;
- (NSUInteger)positionOfIndex:(NSUInteger)index;
+ (NSIndexSet *)indexSetWithArray:(NSArray *)array;
- (NSIndexSet *)intersectionWithIndexSet:(NSIndexSet *)indexSet;

@end
