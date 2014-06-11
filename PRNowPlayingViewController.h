#import <Cocoa/Cocoa.h>
#import "PROutlineView.h"
#import "PRViewController.h"
@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRNowPlayingViewSource, PRGradientView, PRMainWindowController, PRNowPlayingCell, PRNowPlayingHeaderCell, PROutlineView, PRCore;


@interface PRNowPlayingViewController : PRViewController <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate, NSTextFieldDelegate, PROutlineViewDelegate> {
    __weak PRCore *_core;
    __weak PRMainWindowController *win;
    __weak PRDb *db;
    __weak PRNowPlayingController *now;
    
    PROutlineView *nowPlayingTableView;
    NSScrollView *scrollview;
    
    NSView *_headerView;
    NSButton *_clearButton;
    NSPopUpButton *_menuButton;
    
    NSMenu *_playlistMenu;
    NSMenu *_contextMenu;
    
    // tableview datasource
    NSArray *_albumCounts;
    NSMutableArray *_dbRowForAlbum;
    NSMutableIndexSet *_albumIndexes;
    
    NSMutableDictionary *_parentItems;
    NSMutableDictionary *_childItems;
    
    NSPoint dropPoint;
    
    NSCell *_cachedNowPlayingCell;
    NSCell *_cachedNowPlayingHeaderCell;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Action */
- (void)clearPlaylist;
- (void)higlightPlayingFile;
- (void)addItems:(NSArray *)items atIndex:(int)index;

/* Accessors */
@property (readonly) NSView *headerView;
@end