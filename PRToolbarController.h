#import "PRMainWindowController.h"
@protocol PRToolbarControllerDelegate;

@interface PRToolbarController : NSObject
@property (nonatomic, readonly) NSToolbar *toolbar;
@property (nonatomic, weak) id<PRToolbarControllerDelegate> delegate;
@property (nonatomic) PRWindowMode windowMode;
@property (nonatomic, strong) NSString *searchText;
@end

@protocol PRToolbarControllerDelegate <NSObject>
- (void)toolbarControllerSidebarButtonPressed:(PRToolbarController *)toolbar;
- (void)toolbarControllerInfoButtonPressed:(PRToolbarController *)toolbar;
- (void)toolbarControllerSelectedSegmentChanged:(PRToolbarController *)toolbar;
- (void)toolbarControllerSearchTextChanged:(PRToolbarController *)toolbar;
@end
