#import <Cocoa/Cocoa.h>


@interface NSIndexSet (Extensions) 

- (NSUInteger)nthIndex:(NSUInteger)n;
+ (NSIndexSet *)indexSetWithArray:(NSArray *)array;

@end
