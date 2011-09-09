#import <Cocoa/Cocoa.h>


@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRNowPlayingViewSource,
PRGradientView, PRMainWindowController, PRNowPlayingCell, PRNowPlayingHeaderCell;

@interface PRNowPlayingViewController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate, NSTextFieldDelegate>
{
	IBOutlet NSOutlineView *nowPlayingTableView;
	IBOutlet NSButton *clearButton;
    IBOutlet PRGradientView *backgroundGradient;
	IBOutlet PRGradientView *barGradient;
    IBOutlet NSSlider *volumeSlider;
    IBOutlet NSScrollView *scrollview;
    IBOutlet NSTextField *_dragLabel;
    
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
    
    int _prevRow;    
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

- (void)playItem:(id)item;
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

// ========================================
// Update

- (void)updateTableView;
- (void)playlistDidChange:(NSNotification *)notification;
- (void)currentFileDidChange:(NSNotification *)notification;

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