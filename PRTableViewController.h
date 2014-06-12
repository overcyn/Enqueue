#import <Cocoa/Cocoa.h>
#import "PRAlbumTableView.h"
#import "PRLibrary.h"
#import "PRLibraryViewController.h"
#import "PRViewController.h"

@class PRDb;
@class PRLibrary;
@class PRPlaylists;
@class PRNowPlayingController;
@class PRLibraryViewSource;
@class PRLibraryViewController;
@class PRNumberFormatter;
@class PRSizeFormatter;
@class PRTimeFormatter;
@class PRBitRateFormatter;
@class PRKindFormatter;
@class PRDateFormatter;
@class PRStringFormatter;


@interface PRTableViewController : PRViewController <NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, PRTableViewDelegate> {
    __weak PRCore *_core;
    __weak PRDb *_db;
    __weak PRNowPlayingController *_now;
    
    PRTableView *_detailTableView;
    NSView *_detailView;
    NSScrollView *_detailScrollView;
    
    NSSplitView *_horizontalBrowserSplitView;
    NSSplitView *_horizontalBrowserSubSplitView;
    PRTableView *_horizontalBrowser1TableView;
    PRTableView *_horizontalBrowser2TableView;
    PRTableView *_horizontalBrowser3TableView;
    NSView *_horizontalBrowserDetailSuperView;
    
    NSSplitView *_verticalBrowserSplitView;
    PRTableView *_verticalBrowser1TableView;
    NSView *_verticalBrowserDetailSuperView;
    
    NSScrollView *_horizontalBrowser1ScrollView;
    NSScrollView *_horizontalBrowser2ScrollView;
    NSScrollView *_horizontalBrowser3ScrollView;
    
    NSMenu *_libraryMenu;
    NSMenu *_headerMenu;
    NSMenu *_browserHeaderMenu;
    
    NSTableView *_browser1TableView;
    NSTableView *_browser2TableView;
    NSTableView *_browser3TableView;
    
    PRList *_currentList;
    BOOL _updatingTableViewSelection; // True during reloadData: so tableViewSelectionDidChange doesn't trigger
    BOOL _refreshing;
    
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
