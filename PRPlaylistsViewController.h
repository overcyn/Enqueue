#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"

@class PRDb, PRPlaylists, PRMainWindowController, PRGradientView, PRRolloverTableView, PRStringFormatter;

@interface PRPlaylistsViewController : NSViewController //<NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>
{
    IBOutlet NSView *background;
    IBOutlet PRRolloverTableView *tableView;
    IBOutlet PRGradientView *divider;
    IBOutlet PRGradientView *divider2;
	IBOutlet NSButton *newPlaylistButton;
	IBOutlet NSButton *newSmartPlaylistButton;
    
    PRStringFormatter *stringFormatter;
    NSArray *datasource;
    
    PRDb *db;
//	PRPlaylists *play;
	PRMainWindowController *win;
}

// ========================================
// Initialization

- (id)      initWithDb:(PRDb *)db
  mainWindowController:(PRMainWindowController *)win_;

// ========================================
// Update

- (void)update;
- (void)playlistsDidChangeNotification:(NSNotification *)notification;
- (void)playlistDidChangeNotification:(NSNotification *)notification;

// ========================================
// Action

- (void)tableViewAction;
- (void)newSmartPlaylist;
- (void)newStaticPlaylist;

- (void)duplicatePlaylist:(PRPlaylist)playlist;
- (void)deletePlaylist:(PRPlaylist)playlist;
- (void)renamePlaylist:(PRPlaylist)playlist;

- (void)duplicatePlaylistMenuAction:(NSMenuItem *)menuItem;
- (void)renamePlaylistMenuAction:(NSMenuItem *)menuItem;
- (void)deletePlaylistMenuAction:(NSMenuItem *)menuItem;

// ========================================
// Misc

// Returns playlist for row. -1 if no row.
- (int)playlistForRow:(int)row;
// Returns row for playlist. -1 if no row.
- (int)rowForPlaylist:(PRPlaylist)playlist;

@end
