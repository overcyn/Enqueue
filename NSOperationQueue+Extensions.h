#import <Foundation/Foundation.h>

@interface NSOperationQueue (Extensions)
+ (NSOperationQueue *)backgroundQueue;
- (void)addBlock:(void (^)(void))block;
- (void)addBlockAndWait:(void (^)(void))block;
- (void)addBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;
@end
