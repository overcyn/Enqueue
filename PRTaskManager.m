#import "PRTaskManager.h"
#import "PRTask.h"


@implementation PRTaskManager

@synthesize tasks;

- (id)init
{
    self = [super init];
    if (self) {
        tasks = [[NSMutableArray alloc] init];
        [self updateTasksOnMain];
    }
    return self;
}

- (void)dealloc
{
    [tasks release];
    [super dealloc];
}

- (void)addTask:(PRTask *)task
{   
    if (![tasks containsObject:task]) {
        [task addObserver:self forKeyPath:@"title" options:0 context:nil];
        [task addObserver:self forKeyPath:@"value" options:0 context:nil];
        [tasks addObject:task];
        [self updateTasksOnMain];
    }
}

- (void)removeTask:(PRTask *)task
{
    if ([tasks containsObject:task]) {
        [task removeObserver:self forKeyPath:@"title"];
        [task removeObserver:self forKeyPath:@"value"];
        [tasks removeObject:task];
        [self updateTasksOnMain];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    [self updateTasksOnMain];
}

- (void)updateTasksOnMain
{
    [self performSelectorOnMainThread:@selector(updateTasks) withObject:nil waitUntilDone:TRUE];
}

- (void)updateTasks
{
    [self willChangeValueForKey:@"tasks"];
    [self didChangeValueForKey:@"tasks"];
}

@end
