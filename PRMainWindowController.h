#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRCore, PRDb, PRPlaylists, PRNowPlayingController, PRFolderMonitor,PRNowPlayingViewController, PRControlsViewController, PRLibraryViewController, PRPreferencesViewController, PRPlaylistsViewController, PRHistoryViewController, PRGradientView, PRMainMenuController;


typedef enum {
    PRLibraryMode,
    PRPlaylistsMode,
    PRPreferencesMode,
    PRHistoryMode,
    PRSongMode,
} PRMode;


@interface PRMainWindowController : NSWindowController <NSWindowDelegate, NSMenuDelegate, NSSplitViewDelegate> {
    __weak PRCore *_core;
    __weak PRDb *_db;
    
    IBOutlet NSView *centerSuperview;
    IBOutlet NSView *controlsSuperview;
    IBOutlet NSView *nowPlayingSuperview;
    IBOutlet NSButton *libraryButton;
    IBOutlet NSButton *playlistsButton; 
    IBOutlet NSButton *historyButton;
    IBOutlet NSButton *preferencesButton;
    IBOutlet NSSplitView *_splitView;
    
    IBOutlet NSView *_sidebarHeaderView;
    IBOutlet NSView *_headerView;
    
    IBOutlet PRGradientView *toolbarView;
    IBOutlet NSView *_toolbarSubview;
    IBOutlet PRGradientView *_verticalDivider;
    
    PRMainMenuController *mainMenuController;
    PRLibraryViewController *libraryViewController;	
    PRHistoryViewController *historyViewController;
    PRPlaylistsViewController *playlistsViewController;
    PRPreferencesViewController *preferencesViewController;	
    PRNowPlayingViewController *nowPlayingViewController;
    PRControlsViewController *controlsViewController;
        
    PRMode _currentMode;
    id _currentViewController;
    
    BOOL _resizingSplitView;
    BOOL _windowWillResize;
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

@property (readwrite) PRMode currentMode;
@property (readwrite) BOOL showsArtwork;
@property (readwrite) BOOL miniPlayer;

/* UI */
- (void)toggleMiniPlayer;
- (void)updateLayoutWithFrame:(NSRect)frame;
- (void)updateSplitView;
- (void)updateUI;
- (void)updateWindowButtons;
@end
