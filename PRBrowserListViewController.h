#import "PRViewController.h"
@class PRBrowserDescription;
@protocol PRBrowserListViewControllerDelegate;
@class PRBridge;

@interface PRBrowserListViewController : PRViewController
- (id)initWithBridge:(PRBridge *)bridge;
@property (nonatomic, strong) PRBrowserDescription *browserDescription;
@property (nonatomic, weak) id<PRBrowserListViewControllerDelegate> delegate;
@property (nonatomic, readonly) NSIndexSet *selectedIndexes;
@end

@protocol PRBrowserListViewControllerDelegate
- (void)browserListViewControllerDidChangeSelection:(PRBrowserListViewController *)browserVC;
- (NSArray *)browserListViewControllerLibraryItems:(PRBrowserListViewController *)browserVC;
- (NSMenu *)browserListViewControllerHeaderMenu:(PRBrowserListViewController *)browserVC;
@end
