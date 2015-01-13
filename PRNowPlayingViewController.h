#import "PRViewController.h"
@class PRCore;

@interface PRNowPlayingViewController : PRViewController
- (id)initWithCore:(PRCore *)core;
- (void)higlightPlayingFile;
@property (readonly) NSView *headerView;
@end
