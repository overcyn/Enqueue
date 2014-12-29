#import <Foundation/Foundation.h>
@class PRCore, PROperationProgress;


@interface PRFullRescanOperation : NSOperation {
    __weak PRCore *_core;
}
/* Initialization */
+ (id)operationWithCore:(PRCore *)core;
- (id)initWithCore:(PRCore *)core;

/* Action */
- (void)updateFiles:(NSArray *)array;
@end
