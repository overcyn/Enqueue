#import <Foundation/Foundation.h>


@class PRTask;

@interface PRTaskManager : NSObject 
{
    NSMutableArray *tasks;
}

@property (readonly) NSMutableArray *tasks;

- (void)addTask:(PRTask *)task;
- (void)removeTask:(PRTask *)task;
- (void)updateTasksOnMain;
- (void)updateTasks;

@end
