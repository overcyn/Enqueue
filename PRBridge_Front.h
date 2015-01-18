#import "PRBridge.h"
#import "PRTask.h"

@interface PRBridge ()
- (void)performTask:(PRTask)action;
- (void)performTaskSync:(PRTask)action;
@end
