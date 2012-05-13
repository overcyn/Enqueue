#import <Cocoa/Cocoa.h>
@class PRDb, PRHistory, PRLibrary, PRMainWindowController, PRGradientView, PRTableView;


typedef enum {
    PRTopSongsHistoryMode,
    PRTopArtistsHistoryMode,
    PRRecentlyAddedHistoryMode,
    PRRecentlyPlayedHistoryMode,
} PRHistoryMode2;


@interface PRHistoryViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource> {
    IBOutlet NSView *background;
    IBOutlet PRGradientView *divider2;
    IBOutlet PRTableView *tableView;
    
    IBOutlet NSButton *topSongsButton;
    IBOutlet NSButton *topArtistsButton;
    IBOutlet NSButton *recentlyAddedButton;
    IBOutlet NSButton *recentlyPlayedButton;
    
    IBOutlet NSImageView *_placeholder;
    
    NSArray *dataSource;
    
    PRHistoryMode2 historyMode;
	
    NSDateFormatter *_dateFormatter;
    NSDateFormatter *_timeFormatter;
    
	__weak PRDb *db;
	__weak PRMainWindowController *_win;
}
/* Initialization */
- (id)initWithDb:(PRDb *)db_ mainWindowController:(PRMainWindowController *)mainWindowController_;

/* Accessors */
@property (readwrite) PRHistoryMode2 historyMode;

/* Action */
- (void)historyModeButtonAction:(id)sender;
- (void)update;
- (void)tableViewAction:(id)sender;
@end