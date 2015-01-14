#import "PRViewController.h"
#import "PRPlaylists.h"
@class PRBridge;
@class PRBrowserViewController;

typedef NS_ENUM(NSInteger, PRLibraryViewMode) {
    PRLibraryViewModeList,
    PRLibraryViewModeAlbumList,
};

@interface PRLibraryViewController : PRViewController
- (id)initWithBridge:(PRBridge *)bridge;
@property (nonatomic, readonly) PRBrowserViewController *currentViewController;
@property (nonatomic, strong) PRListID *currentList;
@property (nonatomic) PRLibraryViewMode libraryViewMode;
@property (nonatomic) BOOL infoViewVisible;
- (void)toggleInfoViewVisible;
- (void)find;
@end
