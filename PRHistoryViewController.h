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
    
    IBOutlet NSButton *weekButton;
    IBOutlet NSButton *monthButton;
    IBOutlet NSButton *sixMonthButton;
    IBOutlet NSButton *yearButton;
    IBOutlet NSButton *allTimeButton;
    
    NSArray *dataSource;
    
    PRHistoryMode2 historyMode;
	
	// Database, history, library, main window controller. (weak)
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