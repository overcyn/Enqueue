#import <Cocoa/Cocoa.h>
#import "PRAlbumTableView.h"
#import "PRLibrary.h"


@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRLibraryViewSource, PRLibraryViewController,
PRNumberFormatter, PRSizeFormatter, PRTimeFormatter, PRBitRateFormatter, PRKindFormatter, PRDateFormatter,
PRStringFormatter;


// PRTableViewController
//
@interface PRTableViewController : NSViewController <NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>
{
	IBOutlet NSTableView *libraryTableView;
    IBOutlet NSView *libraryScrollView;
    
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
	
	// Current playlist. Default -1.
	int currentPlaylist;
	
	// variable thats true when refreshing so that tableViewSelectionDid change doesnt get triggered for 
	BOOL refreshing;
	
	int columnInfoPlaylistAttribute;
	int sortColumnPlaylistAttribute;
	int ascendingPlaylistAttribute;
	
	NSMenu *libraryMenu;
	NSMenu *headerMenu;
	NSMenu *browserHeaderMenu;
	// selection for context menu
	NSIndexSet *selectedRows;
	
	PRDb *db;
	PRLibrary *lib;
	PRPlaylists *play;
	PRNowPlayingController *now;
	PRLibraryViewSource *libSrc;
	PRLibraryViewController *libraryViewController; // weak
}

// ========================================
// Initialization

- (id)       initWithDb:(PRDb *)db_ 
   nowPlayingController:(PRNowPlayingController *)now_
  libraryViewController:(PRLibraryViewController *)libraryViewController_;

// ========================================
// Accessors

// Total size, count and length of visible songs
- (NSDictionary *)info;

// Current selection
- (NSArray *)selection;

- (void)setCurrentPlaylist:(int)newPlaylist;

// ========================================
// Update

- (void)libraryDidChange:(NSNotification *)notification;
- (void)playlistDidChange:(NSNotification *)notification;
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

- (void)updateTableView;
- (void)loadTableColumns;

// Private method called by |loadTableColumns|
- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending;

- (void)updateHeaderMenu;
- (void)updateLibraryMenu;
- (void)updateBrowserHeaderMenu;

// ========================================
// UI Action

- (void)saveTableColumns;
- (void)saveBrowser;
- (void)toggleColumn:(id)sender;
- (void)toggleBrowser:(id)sender;

// Selects file. If file not visible clear browser & searches, and select file.
- (void)highlightFile:(PRFile)file;
- (void)highlightFiles:(NSIndexSet *)indexSet;

// ========================================
// UI Misc

- (NSTableColumn *)tableColumnForAttribute:(int)attribute;
- (NSData *)defaultColumnsInfoData;

- (int)dbRowForTableRow:(int)tableRow;
- (NSIndexSet *)dbRowIndexesForTableRowIndexes:(NSIndexSet *)tableRowIndexes;
- (int)tableRowForDbRow:(int)dbRow;
- (NSIndexSet *)tableRowIndexesForDbRowIndexes:(NSIndexSet *)indexSet;


@end