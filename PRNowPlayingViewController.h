#import <Cocoa/Cocoa.h>
#import "PROutlineView.h"
@class PRDb, PRLibrary, PRPlaylists, PRNowPlayingController, PRNowPlayingViewSource, PRGradientView, PRMainWindowController, PRNowPlayingCell, PRNowPlayingHeaderCell, PROutlineView, PRCore;


@interface PRNowPlayingViewController : NSViewController <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate, NSTextFieldDelegate, PROutlineViewDelegate> {
	IBOutlet PROutlineView *nowPlayingTableView;
    IBOutlet PRGradientView *backgroundGradient;
    IBOutlet NSScrollView *scrollview;
    
    NSMenu *_contextMenu;
    
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
	
    __weak PRCore *_core;
    __weak PRMainWindowController *win;
	__weak PRDb *db;
	__weak PRNowPlayingController *now;
}
// Initialization
- (id)initWithCore:(PRCore *)core;

// Action
- (void)higlightPlayingFile;
- (void)addItems:(NSArray *)items atIndex:(int)index;

// Menu
- (NSMenu *)playlistMenu;
@end