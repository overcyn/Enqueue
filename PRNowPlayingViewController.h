#import <Cocoa/Cocoa.h>


@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRNowPlayingViewSource, PRTableView, 
PRGradientView, PRMainWindowController;

@interface PRNowPlayingViewController : NSViewController //<NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate, NSTextFieldDelegate>
{
	IBOutlet PRTableView *nowPlayingTableView;
    IBOutlet NSButton *shuffle;
	IBOutlet NSButton *repeat;
	IBOutlet NSButton *clearButton;
	IBOutlet NSPopUpButton *playlistButton;
    IBOutlet NSTextField *playlistTitleEditor;
    IBOutlet PRGradientView *gradientView;
	IBOutlet PRGradientView *gradientView2;
    IBOutlet PRGradientView *gradientView3;
    IBOutlet PRGradientView *gradientView4;
    IBOutlet PRGradientView *shadowView;
    IBOutlet NSSlider *volumeSlider;
    
    NSMenu *playlistMenu;
	NSMenu *nowPlayingMenu;
	NSIndexSet *selectedRows; // indexset of selected rows used for context menu
	int tableCount;
	NSMutableIndexSet *tableIndexes;
    
    NSPoint dropPoint;
	
    PRMainWindowController *win;
	PRDb *db;
	PRNowPlayingController *now;
}

- (id)      initWithDb:(PRDb *)db_ 
  nowPlayingController:(PRNowPlayingController *)now_ 
  mainWindowController:(PRMainWindowController *)mainWindowController_;

@end


@interface PRNowPlayingViewController ()

// ========================================
// Action

- (void)play;
- (void)addSelectedToQueue;
- (void)removeSelectedFromQueue;
- (void)playSelected;
- (void)removeSelected;
- (void)addToPlaylist:(id)sender;
- (IBAction)delete:(id)sender;
- (void)clearPlaylist;
- (void)showInLibrary;
- (void)revealInFinder;
- (void)getInfo;

- (void)saveAsPlaylist:(id)sender;
- (void)newPlaylist:(id)sender;

// Converts between database row and table row. Returns -1 if row does not exist
- (int)dbRowForTableRow:(int)tableRow;
- (int)tableRowForDbRow:(int)dbRow;

// Convenience method for |dbRowForTableRow|
- (NSIndexSet *)dbRowIndexesForTableRowIndexes:(NSIndexSet *)tableRowIndexes;

// Updates table view. Refreshes nowPlayingViewSource, tableIndexes. Scrolls to current row.
- (void)updateTableView;

// Receives PRPlaylistDidChangeNotifications and calls |updateTableView|
- (void)playlistDidChange:(NSNotification *)notification;

// Receives PRCurrentFileDidChange Notification, reloads nowPlayingTableView and scrolls to current row.
- (void)currentFileDidChange:(NSNotification *)notification;

- (void)playlistMenuNeedsUpdate;

@end