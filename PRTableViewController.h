#import <Cocoa/Cocoa.h>
#import "PRAlbumTableView.h"
#import "PRLibrary.h"
#import "PRLibraryViewController.h"
#import "PRViewController.h"
#import "PRBrowseView.h"

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


@interface PRTableViewController : PRViewController <PRBrowseViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, PRTableViewDelegate> {
    __weak PRCore *_core;
    __weak PRDb *_db;
    __weak PRNowPlayingController *_now;
    
    PRTableView *_detailTableView;
    NSView *_detailView;
    NSScrollView *_detailScrollView;
    
    NSScrollView *_browser1ScrollView;
    NSScrollView *_browser2ScrollView;
    NSScrollView *_browser3ScrollView;
    PRTableView *_browser1TableView;
    PRTableView *_browser2TableView;
    PRTableView *_browser3TableView;
    
    NSMenu *_libraryMenu;
    NSMenu *_headerMenu;
    NSMenu *_browserHeaderMenu;
    
    PRList *_currentList;
    BOOL _updatingTableViewSelection; // YES during reloadData: so tableViewSelectionDidChange doesn't trigger
    BOOL _refreshing;
    
    BOOL _lastLibraryTypeSelectFailure; // Optimization for type select. YES if last search was unsuccessful.
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
