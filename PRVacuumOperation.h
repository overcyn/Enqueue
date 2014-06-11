#import <Foundation/Foundation.h>
@class PRTask, PRCore;


@interface PRVacuumOperation : NSOperation {
    __weak PRCore *_core;
    
    PRTask *_task; 
}
- (id)initWithCore:(PRCore *)core;
@end
