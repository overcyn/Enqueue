#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"

@class PRDb, PRCore, PRPlaylists, PRMainWindowController, PRGradientView, PRRolloverTableView, 
PRStringFormatter, PRSmartPlaylistEditorViewController;

@interface PRPlaylistsViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>
{
    IBOutlet NSView *background;
    IBOutlet PRRolloverTableView *tableView;
    IBOutlet PRGradientView *divider;
    IBOutlet PRGradientView *divider2;
	IBOutlet NSButton *newPlaylistButton;
	IBOutlet NSButton *newSmartPlaylistButton;
    IBOutlet NSButton *tabButton0;
    IBOutlet NSImageView *_placeholder;
    
    PRStringFormatter *stringFormatter;
    NSArray *_datasource;
    
    PRCore *_core;
    PRDb *db;
	PRMainWindowController *win;
    PRSmartPlaylistEditorViewController *smartPlaylistEditorViewController;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Update */
- (void)update;

/* Action */
- (void)tableViewAction;
- (void)newSmartPlaylist;
- (void)newStaticPlaylist;

- (void)duplicatePlaylist:(PRPlaylist)playlist;
- (void)deletePlaylist:(PRPlaylist)playlist;
- (void)renamePlaylist:(PRPlaylist)playlist;
- (void)editPlaylist:(PRPlaylist)playlist;

- (void)duplicatePlaylistMenuAction:(NSMenuItem *)menuItem;
- (void)renamePlaylistMenuAction:(NSMenuItem *)menuItem;
- (void)deletePlaylistMenuAction:(NSMenuItem *)menuItem;
- (void)editPlaylistMenuAction:(NSMenuItem *)menuItem;

/* Misc */
// Returns playlist for row. -1 if no row.
- (int)playlistForRow:(int)row;
// Returns row for playlist. -1 if no row.
- (int)rowForPlaylist:(PRPlaylist)playlist;
@end
