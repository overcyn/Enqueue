#import "PRBridge.h"
#import "PRAction.h"

@interface PRBridge ()
- (void)performTask:(PRTask)action;
- (void)performTaskSync:(PRTask)action;
@end
