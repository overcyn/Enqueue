#import "PRViewController.h"
@class PRCore;

@interface PRUpNextViewController : PRViewController
- (id)initWithCore:(PRCore *)core;
- (void)higlightPlayingFile;
@property (readonly) NSView *headerView;
@end
