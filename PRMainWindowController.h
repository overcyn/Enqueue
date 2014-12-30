#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRCore; 
@class PRNowPlayingViewController; 
@class PRControlsViewController; 
@class PRLibraryViewController; 
@class PRPreferencesViewController; 
@class PRPlaylistsViewController; 
@class PRHistoryViewController; 
@class PRMainMenuController; 

typedef NS_ENUM(NSInteger, PRWindowMode) {
    PRWindowModeLibrary,
    PRWindowModePlaylists,
    PRWindowModeHistory,
    PRWindowModePreferences,
};

@interface PRMainWindowController : NSWindowController
- (id)initWithCore:(PRCore *)core;

@property (readonly) PRMainMenuController *mainMenuController;
@property (readonly) PRLibraryViewController *libraryViewController;
@property (readonly) PRHistoryViewController *historyViewController;
@property (readonly) PRPlaylistsViewController *playlistsViewController;
@property (readonly) PRPreferencesViewController *preferencesViewController;
@property (readonly) PRNowPlayingViewController *nowPlayingViewController;
@property (readonly) PRControlsViewController *controlsViewController;

@property (readwrite) PRWindowMode currentMode;
@property (readwrite) BOOL showsArtwork;
@property (readwrite) BOOL miniPlayer;

- (void)toggleMiniPlayer;
- (void)updateLayoutWithFrame:(NSRect)frame;
- (void)updateSplitView;
- (void)updateUI;
- (void)updateWindowButtons;
@end
