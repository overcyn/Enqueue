#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"

@class PRCore, PRDb, PRPlaylists, PRNowPlayingController, PRFolderMonitor, PRTaskManagerViewController,
PRNowPlayingViewController, PRControlsViewController, PRLibraryViewController, PRPreferencesViewController, 
PRPlaylistsViewController, PRHistoryViewController, PRGradientView, 
MAAttachedWindow, PRMainMenuController, YRKSpinningProgressIndicator, PRStringFormatter;

typedef enum {
    PRLibraryMode,
    PRPlaylistsMode,
    PRPreferencesMode,
    PRHistoryMode,
    PRSongMode,
} PRMode;


@interface PRMainWindowController : NSWindowController <NSWindowDelegate, NSMenuDelegate, NSSplitViewDelegate>
{
    IBOutlet NSView *_windowSuperView;
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
    IBOutlet NSPopUpButton *modeButton;
    
    IBOutlet PRGradientView *toolbarView;
    IBOutlet NSView *_toolbarSubview;
    IBOutlet PRGradientView *_verticalDivider;
    
    IBOutlet NSButton *_clearPlaylistButton;
    IBOutlet NSPopUpButton *_playlistPopupButton;
    
    IBOutlet NSPopUpButton *_libraryViewPopupButton;
    
    IBOutlet NSTextField *playlistTitle;
    
    NSMenu *_libraryViewMenu;
    NSMenu *_playlistMenu;
        
    PRMode _mode;
    int currentPlaylist;
    id currentViewController;
    
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
	
    // weak
    PRCore *_core;
    PRDb *_db;
}

// ========================================
// Initializer

- (id)initWithCore:(PRCore *)core_;

// ========================================
// Accessors

@property (readonly) PRMainMenuController *mainMenuController;
@property (readonly) PRLibraryViewController *libraryViewController;
@property (readonly) PRHistoryViewController *historyViewController;
@property (readonly) PRPlaylistsViewController *playlistsViewController;
@property (readonly) PRPreferencesViewController *preferencesViewController;
@property (readonly) PRNowPlayingViewController *nowPlayingViewController;
@property (readonly) PRControlsViewController *controlsViewController;
@property (readonly) PRTaskManagerViewController *taskManagerViewController;

// Sets the current mode and playlist. Propogates changes to view controllers.
@property (readwrite) PRMode currentMode;
@property (readwrite) PRPlaylist currentPlaylist;
@property (readwrite) BOOL showsArtwork;
@property (readwrite) BOOL miniPlayer;

// ========================================
// UI

- (void)toggleMiniPlayer;

- (void)updateLayoutWithFrame:(NSRect)frame;
- (void)updateSplitView;
- (void)updateUI;
- (void)updateWindowButtons;
- (void)find;

@end
