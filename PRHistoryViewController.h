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
    
    IBOutlet NSImageView *_placeholder;
    
    NSArray *dataSource;
    
    PRHistoryMode2 historyMode;
    
    float _rowHeight;
	
    NSDateFormatter *_dateFormatter;
    NSDateFormatter *_timeFormatter;
    
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

// Action method for tableview
- (void)tableViewAction:(id)sender;

@end