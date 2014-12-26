#import "PRViewController.h"
@class PRBrowserDescription;
@protocol PRBrowserListViewController;

@interface PRBrowserListViewController : PRViewController
@property (nonatomic, strong) PRBrowserDescription *browserDescription;
- (void)scrollToSelectedRow;
@property (nonatomic, readonly) NSIndexSet *selectedIndexes;
@property (nonatomic, weak) id<PRBrowserListViewController> delegate;
@end

@protocol PRBrowserListViewController
- (void)browserViewControllerDidChangeSelection:(PRBrowserListViewController *)browserVC;
@end