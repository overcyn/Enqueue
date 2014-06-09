#import <Foundation/Foundation.h>
@class PRTask;


@interface PRTaskManager : NSObject {
    NSMutableArray *_tasks;
}
@property (readonly) NSMutableArray *tasks;
- (void)addTask:(PRTask *)task;
- (void)removeTask:(PRTask *)task;
- (void)cancel;
@end
