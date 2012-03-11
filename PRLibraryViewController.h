#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRInfoViewController, PRTableViewController, PRListViewController, PRDb, PRNowPlayingController, PRSmartPlaylistEditorViewController, PRStaticPlaylistEditorViewController, PRAlbumListViewController, PRGradientView, PRCore;


typedef enum {
	PRListMode,
	PRAlbumListMode,
    PRGridMode
} PRLibraryViewMode;


@interface PRLibraryViewController : NSViewController {
	IBOutlet NSView *centerSuperview;
	IBOutlet NSView *paneSuperview;
    
    NSView *_headerView;
    NSButton *_infoButton;
    NSPopUpButton *_libraryPopUpButton;
    NSSearchField *_searchField;
	
	PRInfoViewController *infoViewController;
	PRListViewController *listViewController;
	PRAlbumListViewController *albumListViewController;
	
	BOOL _edit; // pane is collapsed
    PRList *_currentList;
    
    __weak id currentPaneViewController;
	__weak PRTableViewController *currentViewController;
	
    __weak PRCore *_core;
	__weak PRDb *_db;
	__weak PRNowPlayingController *_now;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (readonly) NSView *headerView;
@property (readonly) PRTableViewController *currentViewController;
@property (readwrite, retain) PRList *currentList;
@property (readwrite) PRLibraryViewMode libraryViewMode; // -1 if invalid playlist
- (void)infoViewToggle;
- (BOOL)infoViewVisible;

/* Menu */
- (NSMenu *)libraryViewMenu;
@end
