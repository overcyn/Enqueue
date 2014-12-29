#import <Foundation/Foundation.h>
@class PROperationProgress;


@interface PRProgressManager : NSObject {
    NSMutableArray *_tasks;
}
@property (readonly) NSMutableArray *tasks;
- (void)addTask:(PROperationProgress *)task;
- (void)removeTask:(PROperationProgress *)task;
- (void)cancel;
@end
