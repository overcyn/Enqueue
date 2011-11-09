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


@interface PRMainWindowController : NSWindowController <NSWindowDelegate>
{
    IBOutlet NSView *centerSuperview;
    IBOutlet NSView *controlsSuperview;
    IBOutlet NSView *nowPlayingSuperview;
    IBOutlet NSButton *libraryButton;
    IBOutlet NSButton *playlistsButton; 
    IBOutlet NSButton *historyButton;
    IBOutlet NSButton *preferencesButton;
    IBOutlet NSSearchField *searchField;
    
    IBOutlet NSTextField *progressTextField;
    IBOutlet NSButton *cancelButton;
    
    IBOutlet NSButton *infoButton;
    IBOutlet NSSegmentedControl *libraryModeButton;
    
    IBOutlet PRGradientView *toolbarView;
    IBOutlet PRGradientView *mainDivider;
    IBOutlet PRGradientView *divider;
    IBOutlet PRGradientView *divider5;
    
    IBOutlet NSTextField *playlistTitle;
    	
    PRMode currentMode;
    int currentPlaylist;
    id currentViewController;
    
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

@property (readwrite) BOOL progressHidden;
@property (readwrite, retain) NSString *progressTitle;

// ========================================
// UI

- (void)updateUI;
- (void)find;

@end


@interface PRMainWindowController ()

// ========================================
// Update

// Updates searchField
- (void)playlistDidChange:(NSNotification *)notification;

// update subBar
- (void)libraryViewDidChange:(NSNotification *)notification;

- (void)playlistsDidChange:(NSNotification *)notification;

- (void)windowWillEnterFullScreen:(NSNotification *)notification;
- (void)windowWillExitFullScreen:(NSNotification *)notification;

// ========================================
// Accessors

// Accessors for search field and segmented control bindings
- (NSString *)search;
- (void)setSearch:(NSString *)newSearch;
- (int)libraryViewMode;
- (void)setLibraryViewMode:(int)libraryViewMode;

@end