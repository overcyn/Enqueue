#import <Foundation/Foundation.h>


@interface NSOperationQueue (Extensions)

+ (NSOperationQueue *)backgroundQueue;
- (void)addBlock:(void (^)(void))block;
- (void)addBlockAndWait:(void (^)(void))block;

@end
