#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"

@class PRInfoViewController, PRListViewController, PRDb, PRNowPlayingController, 
PRSmartPlaylistEditorViewController, PRStaticPlaylistEditorViewController, 
PRAlbumListViewController, PRGradientView, PRCore;


// Various library views
typedef enum {
	PRListMode,
	PRAlbumListMode,
    PRGridMode
} PRLibraryViewMode;

@interface PRLibraryViewController : NSViewController
{
	IBOutlet NSView *centerSuperview;
	IBOutlet NSView *paneSuperview;
	
	PRInfoViewController *infoViewController;
	PRListViewController *listViewController;
	PRAlbumListViewController *albumListViewController;
	
	// Bool indicating whether pane is collapsed
	BOOL _edit;
	
	// Current pane view controller. Default smartPlaylistEditorViewController. (weak)
	id currentPaneViewController;
	// Current view controller. Default albumListViewController. (weak)
	id currentViewController;
	
	// Current Playlist
	PRPlaylist playlist;
	
    PRCore *core;
	PRDb *db;
	PRNowPlayingController *now;
}

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core_;

// ========================================
// Accessors

@property (readonly) id currentViewController;

// Sets the current playlist
- (void)setPlaylist:(PRPlaylist)playlist_;

// Gets and sets the current mode from PRPlaylists. Returns -1 if invalid playlist
- (PRLibraryViewMode)libraryViewMode;
- (void)setLibraryViewMode:(PRLibraryViewMode)newLibraryMode;
- (void)setListMode;
- (void)setAlbumListMode;

// ========================================
// UI

- (void)updateLayout;

- (void)infoViewToggle;
- (BOOL)infoViewVisible;

// Highlights file in currentViewController.
- (void)highlightFile:(PRFile)file;

- (NSMenu *)libraryViewMenu;

@end
