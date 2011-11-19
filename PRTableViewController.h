#import <Cocoa/Cocoa.h>
#import "PRAlbumTableView.h"
#import "PRLibrary.h"


@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRLibraryViewSource, PRLibraryViewController,
PRNumberFormatter, PRSizeFormatter, PRTimeFormatter, PRBitRateFormatter, PRKindFormatter, PRDateFormatter,
PRStringFormatter;

@interface PRTableViewController : NSViewController <NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>
{
	IBOutlet NSTableView *libraryTableView;
    IBOutlet NSView *libraryScrollView;
    IBOutlet NSScrollView *libraryScrollView2;
    
    IBOutlet NSSplitView *horizontalBrowserSplitView;
    IBOutlet NSSplitView *horizontalBrowserSubSplitview;
    IBOutlet NSTableView *horizontalBrowser1TableView;
    IBOutlet NSTableView *horizontalBrowser2TableView;
    IBOutlet NSTableView *horizontalBrowser3TableView;
    IBOutlet NSView *horizontalBrowserLibrarySuperview;
    
    IBOutlet NSSplitView *verticalBrowserSplitView;
    IBOutlet NSTableView *verticalBrowser1TableView;
    IBOutlet NSView *verticalBrowserLibrarySuperview;
	
    NSTableView *browser1TableView;
    NSTableView *browser2TableView;
    NSTableView *browser3TableView;
    
    PRStringFormatter *stringFormatter;
	PRSizeFormatter *sizeFormatter;
	PRTimeFormatter *timeFormatter;
	PRNumberFormatter *numberFormatter;
    PRBitRateFormatter *bitRateFormatter;
    PRKindFormatter *kindFormatter;
    PRDateFormatter *dateFormatter;
	
	// Default -1
	int currentPlaylist;
	
	// True when updating so that tableViewSelectionDidChange doesnt get triggered
    BOOL monitorSelection;
	BOOL refreshing;
	
	NSMenu *libraryMenu;
	NSMenu *headerMenu;
	NSMenu *browserHeaderMenu;
	// selection for context menu
	NSIndexSet *selectedRows;
	
	PRDb *db;
	PRNowPlayingController *now;
	PRLibraryViewController *libraryViewController; // weak
}

// ========================================
// Initialization

- (id)       initWithDb:(PRDb *)db_ 
   nowPlayingController:(PRNowPlayingController *)now_
  libraryViewController:(PRLibraryViewController *)libraryViewController_;

// ========================================
// Accessors

- (int)sortColumn;
- (void)setSortColumn:(int)sortColumn;
- (BOOL)ascending;
- (void)setAscending:(BOOL)ascending;

- (NSDictionary *)info;
- (NSArray *)selection;

- (void)setCurrentPlaylist:(int)newPlaylist;

// ========================================
// Update

- (void)libraryDidChange:(NSNotification *)notification;
- (void)playlistDidChange:(NSNotification *)notification;
- (void)playlistFilesChanged:(NSNotification *)note;
- (void)tagsDidChange:(NSNotification *)notification;
- (void)ruleDidChange:(NSNotification *)notification;

// ========================================
// Action

- (void)play;
- (void)playBrowser:(id)sender;
- (void)playSelected;
- (void)append;
- (void)addToPlaylist:(id)sender;
- (void)playNext;
- (void)getInfo;
- (void)reveal;
- (void)delete;

- (IBAction)delete:(id)sender;

// ========================================
// UI Update

- (void)reloadData:(BOOL)force;

- (void)loadBrowser;
- (void)saveBrowser;
- (void)loadTableColumns;
- (void)saveTableColumns;

- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending;

- (NSMenu *)browserHeaderMenu;
- (void)updateHeaderMenu;
- (void)updateLibraryMenu;
- (void)updateBrowserHeaderMenu;

// ========================================
// UI Action

- (void)toggleColumn:(id)sender;
- (void)toggleBrowser:(id)sender;

- (void)browseToArtist:(NSString *)artist;
- (void)highlightFile:(PRFile)file;
- (void)highlightFiles:(NSIndexSet *)indexSet;
- (void)highlightArtist:(NSString *)artist;

// ========================================
// UI Misc

- (int)browserForTableView:(NSTableView *)tableView;

- (NSArray *)columnInfo;
- (void)setColumnInfo:(NSArray *)columnInfo;

- (NSTableColumn *)tableColumnForAttribute:(int)attribute;

- (int)dbRowForTableRow:(int)tableRow;
- (NSIndexSet *)dbRowIndexesForTableRowIndexes:(NSIndexSet *)tableRowIndexes;
- (int)tableRowForDbRow:(int)dbRow;
- (NSIndexSet *)tableRowIndexesForDbRowIndexes:(NSIndexSet *)indexSet;

@end
