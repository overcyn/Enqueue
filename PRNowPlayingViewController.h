#import "PRViewController.h"

@class PRCore;


@interface PRNowPlayingViewController : PRViewController
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Action */
- (void)clearPlaylist;
- (void)higlightPlayingFile;
- (void)addItems:(NSArray *)items atIndex:(int)index;

/* Accessors */
@property (readonly) NSView *headerView;
@end