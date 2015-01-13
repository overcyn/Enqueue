#import "PRViewController.h"
#import "PRPlaylists.h"
@class PRBridge;
@class PRLibraryDescription;

@interface PRLibraryListViewController : PRViewController
- (id)initWithBridge:(PRBridge *)bridge;
@property (nonatomic, strong) PRList *currentList;
@property (nonatomic, readonly) NSArray *selectedItems;
@property (nonatomic, readonly) NSArray *allItems;
@end
