#import "PRAction.h"
@class PRCore;

@interface PRBridge : NSObject
@property (nonatomic, weak) PRCore *core;
- (void)performTask:(PRTask)action;
- (void)performTaskSync:(PRTask)action;
@end
