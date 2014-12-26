#import "PRViewController.h"
@class PRLibraryDescription;

@interface PRLibraryListViewController : PRViewController
@property (nonatomic, strong) PRLibraryDescription *libraryDescription;

@property (nonatomic, readonly) NSArray *selectedItems;
- (void)scrollToSelectedRow;
@end
