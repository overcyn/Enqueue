#import <Cocoa/Cocoa.h>


@class PRDb, PRHistory, PRLibrary, PRMainWindowController, PRGradientView, PRTableView;

typedef enum {
    PRTopSongsHistoryMode,
    PRTopArtistsHistoryMode,
    PRRecentlyAddedHistoryMode,
    PRRecentlyPlayedHistoryMode,
} PRHistoryMode2;

// PRHistoryViewController. Controls the history view
//
@interface PRHistoryViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSView *background;
    IBOutlet PRGradientView *divider;
    IBOutlet PRGradientView *divider2;
    
    IBOutlet PRTableView *tableView;
    
    IBOutlet NSButton *topSongsButton;
    IBOutlet NSButton *topArtistsButton;
    IBOutlet NSButton *recentlyAddedButton;
    IBOutlet NSButton *recentlyPlayedButton;
    
    NSArray *dataSource;
    NSCache *artworkCache;
    
    PRHistoryMode2 historyMode;
	
	// Weak
	PRDb *db;
	PRHistory *history;
	PRLibrary *library;
	PRMainWindowController *mainWindowController;
}

@property (readwrite) PRHistoryMode2 historyMode;

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_ mainWindowController:(PRMainWindowController *)mainWindowController_;

// ========================================
// Action

- (void)historyModeButtonAction:(id)sender;

// Updates Tableviews
- (void)update;
- (void)updateUI;

// Action method for tableview
- (void)tableViewAction:(id)sender;

@end