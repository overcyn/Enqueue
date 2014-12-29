#import "PRProgressManager.h"
#import "PROperationProgress.h"


@interface PRProgressManager ()
- (void)updateTasks;
@end


@implementation PRProgressManager

@synthesize tasks = _tasks;

- (id)init {
    if (!(self = [super init])) {return nil;}
    _tasks = [[NSMutableArray alloc] init];
    [self updateTasks];
    return self;
}


- (void)addTask:(PROperationProgress *)task {
    if (![_tasks containsObject:task]) {
        [task addObserver:self forKeyPath:@"title" options:0 context:nil];
        [task addObserver:self forKeyPath:@"percent" options:0 context:nil];
        [_tasks addObject:task];
        [self updateTasks];
    }
}

- (void)removeTask:(PROperationProgress *)task {
    if ([_tasks containsObject:task]) {
        [task removeObserver:self forKeyPath:@"title"];
        [task removeObserver:self forKeyPath:@"percent"];
        [_tasks removeObject:task];
        [self updateTasks];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self updateTasks];
}

- (void)updateTasks {
    [[NSOperationQueue mainQueue] addBlock:^{
        [self willChangeValueForKey:@"tasks"];
        [self didChangeValueForKey:@"tasks"];
    }];
}

- (void)cancel {
    PROperationProgress *task = [_tasks objectAtIndex:0];
    [task setShouldCancel:YES];
}

@end
