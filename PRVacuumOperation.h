#import <Foundation/Foundation.h>
@class PROperationProgress, PRCore;


@interface PRVacuumOperation : NSOperation {
    __weak PRCore *_core;
    
    PROperationProgress *_task; 
}
- (id)initWithCore:(PRCore *)core;
@end
