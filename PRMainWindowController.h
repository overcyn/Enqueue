#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRCore, PRDb, PRPlaylists, PRNowPlayingController, PRFolderMonitor, PRTaskManagerViewController,
PRNowPlayingViewController, PRControlsViewController, PRLibraryViewController, PRPreferencesViewController, 
PRPlaylistsViewController, PRHistoryViewController, PRGradientView, PRMainMenuController;


typedef enum {
    PRLibraryMode,
    PRPlaylistsMode,
    PRPreferencesMode,
    PRHistoryMode,
    PRSongMode,
} PRMode;


@interface PRMainWindowController : NSWindowController <NSWindowDelegate, NSMenuDelegate, NSSplitViewDelegate> {
    IBOutlet NSView *centerSuperview;
    IBOutlet NSView *controlsSuperview;
    IBOutlet NSView *nowPlayingSuperview;
    IBOutlet NSButton *libraryButton;
    IBOutlet NSButton *playlistsButton; 
    IBOutlet NSButton *historyButton;
    IBOutlet NSButton *preferencesButton;
    IBOutlet NSSearchField *searchField;
    IBOutlet NSSplitView *_splitView;
        
    IBOutlet NSButton *infoButton;
    IBOutlet NSPopUpButton *_libraryViewPopupButton;
    
    IBOutlet PRGradientView *toolbarView;
    IBOutlet NSView *_toolbarSubview;
    IBOutlet PRGradientView *_verticalDivider;
    
    IBOutlet NSButton *_clearPlaylistButton;
    IBOutlet NSPopUpButton *_playlistPopupButton;
    
    NSMenu *_libraryViewMenu;
    NSMenu *_playlistMenu;
        
    PRMode _currentMode;
    PRList *_currentList;
    int currentPlaylist;
    id _currentViewController;
    
    BOOL _resizingSplitView;
    BOOL _windowWillResize;
    
    // View controllers
    PRMainMenuController *mainMenuController;
    PRTaskManagerViewController *taskManagerViewController;
    PRLibraryViewController *libraryViewController;	
    PRHistoryViewController *historyViewController;
    PRPlaylistsViewController *playlistsViewController;
    PRPreferencesViewController *preferencesViewController;	
    PRNowPlayingViewController *nowPlayingViewController;
    PRControlsViewController *controlsViewController;
	
    __weak PRCore *_core;
    __weak PRDb *_db;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (readonly) PRMainMenuController *mainMenuController;
@property (readonly) PRLibraryViewController *libraryViewController;
@property (readonly) PRHistoryViewController *historyViewController;
@property (readonly) PRPlaylistsViewController *playlistsViewController;
@property (readonly) PRPreferencesViewController *preferencesViewController;
@property (readonly) PRNowPlayingViewController *nowPlayingViewController;
@property (readonly) PRControlsViewController *controlsViewController;
@property (readonly) PRTaskManagerViewController *taskManagerViewController;

@property (readwrite) PRMode currentMode;
@property (readwrite) PRPlaylist currentPlaylist;
@property (readwrite, retain) PRList *currentList;
@property (readwrite) BOOL showsArtwork;
@property (readwrite) BOOL miniPlayer;

/* UI */
- (void)toggleMiniPlayer;
- (void)updateLayoutWithFrame:(NSRect)frame;
- (void)updateSplitView;
- (void)updateUI;
- (void)updateWindowButtons;
- (void)find;
@end
