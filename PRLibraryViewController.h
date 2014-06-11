#import "PRViewController.h"
#import "PRPlaylists.h"

@class PRAlbumListViewController;
@class PRCore;
@class PRDb;
@class PRGradientView;
@class PRInfoViewController;
@class PRListViewController;
@class PRSmartPlaylistEditorViewController;
@class PRStaticPlaylistEditorViewController;
@class PRTableViewController;


typedef enum {
    PRListMode,
    PRAlbumListMode,
} PRLibraryViewMode;


@interface PRLibraryViewController : PRViewController
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (readonly) NSView *headerView;
@property (readonly) PRTableViewController *currentViewController;
@property (strong) PRList *currentList;
@property PRLibraryViewMode libraryViewMode;
@property BOOL infoViewVisible;
- (void)toggleInfoViewVisible;

/* Action */
- (void)find;
@end
