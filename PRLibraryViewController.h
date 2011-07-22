#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"

@class PRInfoViewController, PRListViewController, PRDb, PRNowPlayingController, 
PRSmartPlaylistEditorViewController, PRStaticPlaylistEditorViewController, 
PRAlbumListViewController, PRGradientView, PRCore;


extern NSString * const PRLibraryViewSelectionDidChangeNotification;
extern NSString * const PRLibraryViewModeDidChangeNotification;

// Various library views
typedef enum {
	PRListMode,
	PRAlbumListMode,
    PRGridMode
} PRLibraryViewMode;

@interface PRLibraryViewController : NSViewController <NSSplitViewDelegate>
{
	IBOutlet NSSplitView *editorSplitView;
	IBOutlet NSView *centerSuperview;
	IBOutlet NSView *paneSuperview;
	IBOutlet NSTextField *playlistTitle;
	IBOutlet NSTextField *libraryViewCount;
    IBOutlet PRGradientView *gradientView;
	
	// View controllers and pane view controllers.
	PRSmartPlaylistEditorViewController *smartPlaylistEditorViewController;
	PRStaticPlaylistEditorViewController *staticPlaylistEditorViewController;
	PRInfoViewController *infoViewController;
	PRListViewController *listViewController;
	PRAlbumListViewController *albumListViewController;
	
	// Bool indicating whether pane is collapsed
	BOOL edit;
	// Height of pane divider when uncollapsed
	float dividerPosition;
	
	// Current pane view controller. Default smartPlaylistEditorViewController. (weak)
	id currentPaneViewController;
	// Current view controller. Default albumListViewController. (weak)
	id currentViewController;
	
	// Current Playlist
	PRPlaylist playlist;
	
	// Database, nowPlayingController, playlists. (weak)
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

// Toggles the editor and info view
- (void)editorViewToggle;
- (void)infoViewToggle;
- (BOOL)infoViewVisible;

// Highlights file in currentViewController.
- (void)highlightFile:(PRFile)file;

@end


// Private methods for PRLibraryViewController
//
@interface PRLibraryViewController ()

// Collapses and uncollapses the splitView
- (void)paneViewCollapse;
- (void)paneViewUncollapse;

@end