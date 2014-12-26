#import "PRViewController.h"
@class PRBrowserDescription;
@protocol PRBrowserViewControllerDelegate;

@interface PRBrowserViewController : PRViewController
@property (nonatomic, strong) PRBrowserDescription *browserDescription;
- (void)scrollToSelectedRow;
@property (nonatomic, readonly) NSIndexSet *selectedIndexes;
@property (nonatomic, weak) id<PRBrowserViewControllerDelegate> delegate;
@end

@protocol PRBrowserViewControllerDelegate
- (void)browserViewControllerDidChangeSelection:(PRBrowserViewController *)browserVC;
@end