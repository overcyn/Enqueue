#import "NSOperationQueue+Extensions.h"

static NSOperationQueue* cw_sharedOperationQueue = nil;

@implementation NSOperationQueue (Extensions)

+ (NSOperationQueue *)backgroundQueue {
    if (cw_sharedOperationQueue == nil) {
        cw_sharedOperationQueue = [[NSOperationQueue alloc] init];
        [cw_sharedOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    }
    return cw_sharedOperationQueue;
}

- (void)addBlock:(void (^)(void))block {
    [self addOperationWithBlock:block];
}

- (void)addBlockAndWait:(void (^)(void))block {
    NSArray *operations = [NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:block]];
    [self addOperations:operations waitUntilFinished:TRUE];
}

@end
