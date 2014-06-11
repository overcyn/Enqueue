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


typedef enum {
    PRLibraryMode,
    PRPlaylistsMode,
    PRPreferencesMode,
    PRHistoryMode,
    PRSongMode,
} PRMode;


@interface PRMainWindowController : NSWindowController
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
