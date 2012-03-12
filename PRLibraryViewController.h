#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRInfoViewController, PRTableViewController, PRListViewController, PRDb, PRNowPlayingController, PRSmartPlaylistEditorViewController, PRStaticPlaylistEditorViewController, PRAlbumListViewController, PRGradientView, PRCore;


typedef enum {
	PRListMode,
	PRAlbumListMode,
} PRLibraryViewMode;


@interface PRLibraryViewController : NSViewController <NSMenuDelegate, NSTextFieldDelegate> {
    __weak PRCore *_core;
	__weak PRDb *_db;
	__weak PRNowPlayingController *_now;
    
	NSView *_centerSuperview;
	NSView *_paneSuperview;
    NSView *_headerView;
    NSButton *_infoButton;
    NSPopUpButton *_libraryPopUpButton;
    NSSearchField *_searchField;
	
    NSMenu *_libraryPopUpButtonMenu;
    
	PRInfoViewController *infoViewController;
	PRListViewController *listViewController;
	PRAlbumListViewController *albumListViewController;
	
	BOOL _paneIsVisible;
    PRList *_currentList;
    __weak PRTableViewController *_currentViewController;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (readonly) NSView *headerView;
@property (readonly) PRTableViewController *currentViewController;
@property (retain) PRList *currentList;
@property PRLibraryViewMode libraryViewMode;
@property BOOL infoViewVisible;
- (void)toggleInfoViewVisible;
@end
