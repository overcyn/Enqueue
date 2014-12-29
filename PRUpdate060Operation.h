#import <Foundation/Foundation.h>
@class PRCore, PROperationProgress;


@interface PRUpdate060Operation : NSOperation {
    __weak PRCore *_core;
}
/* Initialization */
+ (id)operationWithCore:(PRCore *)core;
- (id)initWithCore:(PRCore *)core;

/* Action */
- (void)updateFiles:(NSArray *)array;
@end
