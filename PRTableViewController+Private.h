#import "PRTableViewController.h"


@interface PRTableViewController ()

// Action
- (void)playIndexes:(NSIndexSet *)indexes;
- (void)appendIndexes:(NSIndexSet *)indexes;
- (void)appendNextIndexes:(NSIndexSet *)indexes;
- (void)deleteIndexes:(NSIndexSet *)indexes;
- (void)appendIndexes:(NSIndexSet *)indexes toList:(PRList *)list;
- (void)revealIndexes:(NSIndexSet *)indexes;
- (void)appendAll;
- (void)appendNextAll;

// Action Mouse
- (void)play;
- (void)playBrowser:(id)sender;

// Setup
- (void)reloadData:(BOOL)force;

// Update
- (void)playingFileChanged:(NSNotification *)note;
- (void)libraryDidChange:(NSNotification *)notification;
- (void)playlistDidChange:(NSNotification *)notification;
- (void)playlistFilesChanged:(NSNotification *)note;
- (void)tagsDidChange:(NSNotification *)notification;
- (void)ruleDidChange:(NSNotification *)notification;

// UI
@property (nonatomic) BOOL ascending;
@property (nonatomic, assign) PRItemAttr *sortAttr;
@property (nonatomic, assign) NSArray *columnInfo;

- (void)toggleColumn:(NSTableColumn *)column;
- (void)toggleBrowser:(PRItemAttr *)attr;
- (void)setBrowserPosition:(PRBrowserPosition)position;

- (void)loadBrowser;
- (void)saveBrowser;
- (void)loadTableColumns;
- (void)saveTableColumns;

// UI Misc
- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending;
- (NSTableColumn *)tableColumnForAttr:(PRItemAttr *)attr;

// Menu
- (void)updateHeaderMenu;
- (void)updateLibraryMenu;
- (void)updateBrowserHeaderMenu;
- (void)executeMenu:(id)sender;

// Misc
- (int)dbRowForTableRow:(int)tableRow;
- (NSIndexSet *)dbRowIndexesForTableRowIndexes:(NSIndexSet *)tableRowIndexes;
- (int)tableRowForDbRow:(int)dbRow;
- (NSIndexSet *)tableRowIndexesForDbRowIndexes:(NSIndexSet *)indexSet;
- (int)browserForTableView:(NSTableView *)tableView;
- (NSTableView *)tableViewForBrowser:(int)browser;

// TableViewDataSource Misc
- (NSArray *)attributesToCache;

@end
