#import <Foundation/Foundation.h>
@class PRTask, PRCore;


@interface PRVacuumOperation : NSOperation {
    PRTask *_task;
    PRCore *_core;
}
- (id)initWithCore:(PRCore *)core;
@end
