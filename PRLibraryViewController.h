#import "PRViewController.h"
#import "PRPlaylists.h"
@class PRCore;
@class PRBrowserViewController;

typedef enum {
    PRListMode,
    PRAlbumListMode,
} PRLibraryViewMode;

@interface PRLibraryViewController : PRViewController
- (id)initWithCore:(PRCore *)core;
@property (readonly) NSView *headerView;
@property (readonly) PRBrowserViewController *currentViewController;
@property (strong) PRList *currentList;
@property PRLibraryViewMode libraryViewMode;
@property BOOL infoViewVisible;
- (void)toggleInfoViewVisible;
- (void)find;
@end
