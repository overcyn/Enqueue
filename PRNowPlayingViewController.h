#import <Cocoa/Cocoa.h>


@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRNowPlayingViewSource,
PRGradientView, PRMainWindowController, PRNowPlayingCell, PRNowPlayingHeaderCell;

@interface PRNowPlayingViewController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate, NSTextFieldDelegate>
{
	IBOutlet NSOutlineView *nowPlayingTableView;
    IBOutlet NSPopUpButton *settingsButton;
    IBOutlet NSButton *speakerButton;
	IBOutlet NSButton *clearButton;
    IBOutlet PRGradientView *backgroundGradient;
	IBOutlet PRGradientView *barGradient;
    IBOutlet PRGradientView *divider1;
    IBOutlet PRGradientView *divider2;
    IBOutlet NSSlider *volumeSlider;
    IBOutlet NSScrollView *scrollview;
    
    NSMenu *_contextMenu;
    NSMenu *playlistMenu;
    
    // tableview delegate
    PRNowPlayingCell *_nowPlayingCell;
    PRNowPlayingHeaderCell *_nowPlayingHeaderCell;
    
    // tableview datasource
    NSArray *_albumCounts;
    NSMutableArray *_dbRowForAlbum;
    NSMutableIndexSet *_albumIndexes;
    
    NSMutableDictionary *_parentItems;
    NSMutableDictionary *_childItems;
    
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
// TableView Actions

- (void)playItem:(id)item;
- (void)playSelected;
- (void)removeSelected;
- (void)addSelectedToQueue;
- (void)removeSelectedFromQueue;
- (void)addToPlaylist:(id)sender;
- (IBAction)delete:(id)sender;
- (void)showInLibrary;
- (void)revealInFinder;

// ========================================
// PlaylistMenu Actions

- (void)mute;
- (void)clearPlaylist;
- (void)saveAsPlaylist:(id)sender;
- (void)newPlaylist:(id)sender;

// ========================================
// Update

- (void)updateTableView;
- (void)playlistDidChange:(NSNotification *)notification;
- (void)currentFileDidChange:(NSNotification *)notification;
- (void)volumeChanged:(NSNotification *)notification;

// ========================================
// Menu

- (void)contextMenuNeedsUpdate;
- (void)playlistMenuNeedsUpdate;

// ========================================
// Misc

- (int)dbRowCount;
- (NSRange)dbRangeForParentItem:(id)item;
- (int)dbRowForItem:(id)item;
- (id)itemForDbRow:(int)row;
- (id)itemForItem:(id)item;
- (NSIndexSet *)selectedDbRows;

@end