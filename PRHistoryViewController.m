#import "PRHistoryViewController.h"
#import "PRDb.h"
#import "PRHistory.h"
#import "PRLibrary.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRAlbumArtController.h"
#import "PRScrollView.h"
#import "PRGradientView.h"
#import "PRRolloverTableView.h"
#import "NSScrollView+Extensions.h"
#import "PRHistoryCell.h"
#import "PRHistoryCell2.h"
#import "PRTableViewController.h"
#import "NSColor+Extensions.h"
#import "PRTabButtonCell.h"


#define HISTORY_ROW_HEIGHT              30
#define HISTORY_CELL_TITLE_KEY          @"title"
#define HISTORY_CELL_SUBTITLE_KEY       @"subtitle"
#define HISTORY_CELL_SUBSUBTITLE_KEY    @"subSubTitle"
#define HISTORY_CELL_VALUE_KEY          @"value"
#define HISTORY_CELL_MAX_VALUE_KEY      @"max"


@implementation PRHistoryViewController

@dynamic historyMode;

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db mainWindowController:(PRMainWindowController *)win {
	if (!(self = [super initWithNibName:@"PRHistoryView" bundle:nil])) {return nil;}
    _db = db;
    _win = win;
    historyMode = PRTopArtistsHistoryMode;
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMM dd" options:0 locale:[NSLocale currentLocale]]];
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    if ([[_timeFormatter AMSymbol] isEqualToString:@"AM"]) {
        [_timeFormatter setAMSymbol:@"am"];
    }
    if ([[_timeFormatter PMSymbol] isEqualToString:@"PM"]) {
        [_timeFormatter setPMSymbol:@"pm"];
    }
    [_timeFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"h mm a" options:0 locale:[NSLocale currentLocale]]];
	return self;
}

- (void)dealloc {
    [dataSource release];
    [_dateFormatter release];
    [_timeFormatter release];
    [super dealloc];
}

- (void)awakeFromNib {
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, 2267)];
    [(PRScrollView *)[self view] setDocumentView:[background superview]];
    [(NSScrollView *)[self view] scrollToTop];
        
    [topSongsButton setTag:PRTopSongsHistoryMode];
    [topArtistsButton setTag:PRTopArtistsHistoryMode];
    [recentlyAddedButton setTag:PRRecentlyAddedHistoryMode];
    [recentlyPlayedButton setTag:PRRecentlyPlayedHistoryMode];
    [topSongsButton setTarget:self];
    [topArtistsButton setTarget:self];
    [recentlyAddedButton setTarget:self];
    [recentlyPlayedButton setTarget:self];
    [topSongsButton setAction:@selector(historyModeButtonAction:)];
    [topArtistsButton setAction:@selector(historyModeButtonAction:)];
    [recentlyAddedButton setAction:@selector(historyModeButtonAction:)];
    [recentlyPlayedButton setAction:@selector(historyModeButtonAction:)];
    [(PRTabButtonCell *)[topArtistsButton cell] setRounded:TRUE];
    [(PRTabButtonCell *)[recentlyPlayedButton cell] setRounded:TRUE];
      
    [tableView setDelegate:self];
    [tableView setIntercellSpacing:NSMakeSize(0, 0)];
    [tableView setDataSource:self];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableViewAction:)];
        
    [divider2 setTopBorder:[NSColor PRGridColor]];
    [divider2 setBotBorder:[NSColor PRGridHighlightColor]];
    
    [self update];
}

#pragma mark - Accesssors

- (PRHistoryMode2)historyMode {
    return historyMode;
}

- (void)setHistoryMode:(PRHistoryMode2)historyMode_ {
    historyMode = historyMode_;
    [self update];
}

#pragma mark - Update

- (void)update {
    [dataSource release];
    switch (historyMode) {
        case PRTopArtistsHistoryMode:
            dataSource = [[[_db history] topArtists] retain];
            break;
        case PRTopSongsHistoryMode:
            dataSource = [[[_db history] topSongs] retain];
            break;
        case PRRecentlyAddedHistoryMode:
            dataSource = [[[_db history] recentlyAdded] retain];
            break;
        case PRRecentlyPlayedHistoryMode:
            dataSource = [[[_db history] recentlyPlayed] retain];
            break;
        default:
            @throw NSInternalInconsistencyException;
            break;
    }
    
    if (historyMode == PRTopArtistsHistoryMode || historyMode == PRTopSongsHistoryMode) {
        [[[tableView tableColumns] objectAtIndex:0] setDataCell:[[[PRHistoryCell2 alloc] init] autorelease]];
    } else {
        [[[tableView tableColumns] objectAtIndex:0] setDataCell:[[[PRHistoryCell alloc] init] autorelease]];
    }
    [tableView setRowHeight:HISTORY_ROW_HEIGHT];
    
    [tableView reloadData];

    int rows = [self numberOfRowsInTableView:tableView];
    if (rows < 5) {
        rows = 5;
    }
    float height = 53 + HISTORY_ROW_HEIGHT * rows + 50;
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, height)];
    
    for (NSButton *i in @[topArtistsButton, topSongsButton, recentlyAddedButton, recentlyPlayedButton]) {
        [i setState:NSOffState];
    }
    NSButton *button;
    switch (historyMode) {
        case PRTopArtistsHistoryMode:
            button = topArtistsButton;
            break;
        case PRTopSongsHistoryMode:
            button = topSongsButton;
            break;
        case PRRecentlyAddedHistoryMode:
            button = recentlyAddedButton;
            break;
        case PRRecentlyPlayedHistoryMode:
            button = recentlyPlayedButton;
            break;
        default:
            button = topArtistsButton;
            break;
    }
    [button setState:NSOnState];
    
    if (!(historyMode == PRTopArtistsHistoryMode || historyMode == PRTopSongsHistoryMode)) {
        [divider2 setTopBorder:[NSColor PRGridColor]];
        [divider2 setBotBorder:[NSColor clearColor]]; // no clue why you have to draw the top one but not the bottom.
    } else {
        [divider2 setTopBorder:[[NSColor PRGridColor] blendedColorWithFraction:0.07 ofColor:[NSColor blackColor]]];
        [divider2 setBotBorder:[NSColor clearColor]]; // no clue why you have to draw the top one but not the bottom.
    }
    [divider2 setNeedsDisplay:TRUE];
    
    [_placeholder setHidden:[dataSource count] != 0];
}

#pragma mark - Action

- (void)historyModeButtonAction:(id)sender {
    [self setHistoryMode:[sender tag]];
}

- (void)tableViewAction:(id)sender {
	if ([sender clickedRow] == -1) {
		return;
	}
    [_win setCurrentMode:PRLibraryMode];
    [[_win libraryViewController] setCurrentList:[[_db playlists] libraryList]];
    if (historyMode == PRTopArtistsHistoryMode) {
        NSString *artist = [[dataSource objectAtIndex:[sender clickedRow]] objectForKey:@"artist"];
        [(PRTableViewController *)[[_win libraryViewController] currentViewController] highlightArtist:artist];
    } else {
        PRItem *item = [[dataSource objectAtIndex:[sender clickedRow]] objectForKey:@"file"];
        [[[_win libraryViewController] currentViewController] highlightItem:item];
    }
}

#pragma mark - NSTableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView_ {
    if (tableView_ != tableView) {
        return 0;
    }
	return [dataSource count];
}

- (id)tableView:(NSTableView *)tableView_ objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView_ != tableView) {
        return nil;
    }
    
    NSDictionary *dict = [dataSource objectAtIndex:row];
    if (historyMode == PRTopArtistsHistoryMode) {
        return @{HISTORY_CELL_TITLE_KEY:[dict objectForKey:@"artist"],
            HISTORY_CELL_SUBSUBTITLE_KEY:[[dict objectForKey:@"count"] stringValue],
            HISTORY_CELL_VALUE_KEY:[dict objectForKey:@"count"],
            HISTORY_CELL_MAX_VALUE_KEY:[dict objectForKey:@"max"]};
    } else if (historyMode == PRTopSongsHistoryMode) {
        return @{HISTORY_CELL_TITLE_KEY:[dict objectForKey:@"artist"],
            HISTORY_CELL_SUBTITLE_KEY:[dict objectForKey:@"title"],
            HISTORY_CELL_SUBSUBTITLE_KEY:[[dict objectForKey:@"count"] stringValue],
            HISTORY_CELL_VALUE_KEY:[dict objectForKey:@"count"],
            HISTORY_CELL_MAX_VALUE_KEY:[dict objectForKey:@"max"]};
    } else if (historyMode == PRRecentlyAddedHistoryMode) {
        NSString *dateStr;
        if ([[dict objectForKey:@"date"] timeIntervalSinceDate:[NSDate dateWithNaturalLanguageString:@"midnight today"]] > 0) {
            dateStr = [_timeFormatter stringFromDate:[dict objectForKey:@"date"]];
        } else {
            dateStr = [_dateFormatter stringFromDate:[dict objectForKey:@"date"]];
        }
        return @{HISTORY_CELL_TITLE_KEY:[dict objectForKey:@"artist"],
            HISTORY_CELL_SUBTITLE_KEY:[NSString stringWithFormat:@"%@  —  %@",[dict objectForKey:@"count"],[dict objectForKey:@"album"]],
            HISTORY_CELL_SUBSUBTITLE_KEY:dateStr};
    } else if (historyMode == PRRecentlyPlayedHistoryMode) {
        NSDictionary *dict = [dataSource objectAtIndex:row];
        NSString *dateStr;
        if ([[dict objectForKey:@"date"] timeIntervalSinceDate:[NSDate dateWithNaturalLanguageString:@"midnight today"]] > 0) {
            dateStr = [_timeFormatter stringFromDate:[dict objectForKey:@"date"]];
        } else {
            dateStr = [_dateFormatter stringFromDate:[dict objectForKey:@"date"]];
        }
        return @{HISTORY_CELL_TITLE_KEY:[dict objectForKey:@"artist"],
            HISTORY_CELL_SUBTITLE_KEY:[dict objectForKey:@"title"],
            HISTORY_CELL_SUBSUBTITLE_KEY:dateStr};
    } else {
        @throw NSInternalInconsistencyException;
    }
	return nil;
}

#pragma mark - NSTableView Delegate

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)rowIndex {
	return FALSE;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[cell objectValue]];
    [cell setObjectValue:dictionary];
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    return FALSE;
}

@end