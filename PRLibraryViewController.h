#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
#import "PRViewController.h"
@class PRInfoViewController, PRTableViewController, PRListViewController, PRDb, PRSmartPlaylistEditorViewController, PRStaticPlaylistEditorViewController, PRAlbumListViewController, PRGradientView, PRCore;


typedef enum {
	PRListMode,
	PRAlbumListMode,
} PRLibraryViewMode;


@interface PRLibraryViewController : PRViewController <NSMenuDelegate, NSTextFieldDelegate> {
    __weak PRCore *_core;
	__weak PRDb *_db;
    
	NSView *_centerSuperview;
	NSView *_paneSuperview;
    NSView *_headerView;
    NSButton *_infoButton;
    NSPopUpButton *_libraryPopUpButton;
    NSSearchField *_searchField;
	
    NSMenu *_libraryPopUpButtonMenu;
    
	PRInfoViewController *infoViewController;
	PRListViewController *listViewController;
	PRAlbumListViewController *albumListViewController;
	
    NSDate *_searchFieldLastEdit;
    
	BOOL _infoViewVisible;
    PRList *_currentList;
    __weak PRTableViewController *_currentViewController;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (readonly) NSView *headerView;
@property (readonly) PRTableViewController *currentViewController;
@property (retain) PRList *currentList;
@property PRLibraryViewMode libraryViewMode;
@property BOOL infoViewVisible;
- (void)toggleInfoViewVisible;

/* Action */
- (void)find;
@end
