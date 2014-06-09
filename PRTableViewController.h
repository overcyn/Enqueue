#import <Cocoa/Cocoa.h>
#import "PRAlbumTableView.h"
#import "PRLibrary.h"
#import "PRLibraryViewController.h"
#import "PRViewController.h"
@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRLibraryViewSource, PRLibraryViewController, PRNumberFormatter, PRSizeFormatter, PRTimeFormatter, PRBitRateFormatter, PRKindFormatter, PRDateFormatter, PRStringFormatter;


@interface PRTableViewController : PRViewController <NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, PRTableViewDelegate> {
    __weak PRCore *_core;
	__weak PRDb *db;
	__weak PRNowPlayingController *now;
    
	IBOutlet PRTableView *libraryTableView;
    IBOutlet NSView *libraryScrollView;
    IBOutlet NSScrollView *libraryScrollView2;
    
    IBOutlet NSSplitView *horizontalBrowserSplitView;
    IBOutlet NSSplitView *horizontalBrowserSubSplitview;
    IBOutlet PRTableView *horizontalBrowser1TableView;
    IBOutlet PRTableView *horizontalBrowser2TableView;
    IBOutlet PRTableView *horizontalBrowser3TableView;
    IBOutlet NSView *horizontalBrowserLibrarySuperview;
    
    IBOutlet NSSplitView *verticalBrowserSplitView;
    IBOutlet PRTableView *verticalBrowser1TableView;
    IBOutlet NSView *verticalBrowserLibrarySuperview;
	
    NSMenu *libraryMenu;
	NSMenu *headerMenu;
	NSMenu *browserHeaderMenu;
    
    NSTableView *browser1TableView;
    NSTableView *browser2TableView;
    NSTableView *browser3TableView;
    
    PRList *_currentList;
    BOOL _updatingTableViewSelection; // True during reloadData: so tableViewSelectionDidChange doesn't trigger
	BOOL refreshing;
    
    BOOL _lastLibraryTypeSelectFailure; // Optimization for type select. TRUE if last search was unsuccessful.
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (nonatomic, weak) PRList *currentList;
@property (weak, readonly) NSDictionary *info;
@property (weak, readonly) NSArray *selection;

/* Action */
// These methods will change the browser selection but not the currentList.
- (void)highlightItem:(PRItem *)item;
- (void)highlightFiles:(NSArray *)items;
- (void)highlightArtist:(NSString *)artist;
- (void)browseToArtist:(NSString *)artist;

/* Menu */
- (NSMenu *)browserHeaderMenu;
@end
