#import "PRHistoryViewController.h"
#import "PRDb.h"
#import "PRHistory.h"
#import "PRLibrary.h"
#import "NSButtonTextColor.h"
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


@implementation PRHistoryViewController

@dynamic historyMode;

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_ mainWindowController:(PRMainWindowController *)mainWindowController_
{
	if (!(self = [super initWithNibName:@"PRHistoryView" bundle:nil])) {return nil;}
    db = db_;
    mainWindowController = mainWindowController_;
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

- (void)dealloc
{
    [dataSource release];
    [_dateFormatter release];
    [_timeFormatter release];
    [super dealloc];
}

- (void)awakeFromNib
{
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
    
    // Tabs
    [divider setBotBorder2:[NSColor PRTabBorderColor]];
    [divider setBotBorder:[NSColor PRTabBorderHighlightColor]];
    [divider setColor:[NSColor PRTabBackgroundColor]];
    
    [divider2 setTopBorder:[NSColor PRGridColor]];
    [divider2 setBotBorder:[NSColor PRGridHighlightColor]];
    
    [self update];
}

// ========================================
// Accesssors
// ========================================

- (PRHistoryMode2)historyMode
{
    return historyMode;
}

- (void)setHistoryMode:(PRHistoryMode2)historyMode_
{
    historyMode = historyMode_;
    [self update];
}

// ========================================
// Update
// ========================================

- (void)update
{
    [dataSource release];
    switch (historyMode) {
        case PRTopArtistsHistoryMode:
            dataSource = [[[db history] topArtists] retain];
            break;
        case PRTopSongsHistoryMode:
            dataSource = [[[db history] topSongs] retain];
            break;
        case PRRecentlyAddedHistoryMode:
            dataSource = [[[db history] recentlyAdded] retain];
            break;
        case PRRecentlyPlayedHistoryMode:
            dataSource = [[[db history] recentlyPlayed] retain];
            break;
        default:
            [PRException raise:NSInternalInconsistencyException format:@"Invalid History Mode"];
            break;
    }
    
    if (historyMode == PRTopArtistsHistoryMode || historyMode == PRTopSongsHistoryMode) {
        _rowHeight = 30;
        [[[tableView tableColumns] objectAtIndex:0] setDataCell:[[[PRHistoryCell2 alloc] init] autorelease]];
    } else {
        _rowHeight = 30;
        [[[tableView tableColumns] objectAtIndex:0] setDataCell:[[[PRHistoryCell alloc] init] autorelease]];
    }
    [tableView setRowHeight:_rowHeight];
    
    [tableView reloadData];

    int rows = [self numberOfRowsInTableView:tableView];
    if (rows < 5) {
        rows = 5;
    }
    float height = 53 + _rowHeight * rows + 50;
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, height)];
//    [background setFrame:NSMakeRect([background frame].origin.x, [[background superview] frame].size.height - height, 650, height)];
    
    for (NSButton *i in [NSArray arrayWithObjects:topArtistsButton, topSongsButton, recentlyAddedButton, recentlyPlayedButton, nil]) {
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
}

// ========================================
// Action
// ========================================

- (void)historyModeButtonAction:(id)sender
{
    [self setHistoryMode:[sender tag]];
}

- (void)tableViewAction:(id)sender
{
	if ([sender clickedRow] == -1) {
		return;
	}
    [mainWindowController setCurrentMode:PRLibraryMode];
    [mainWindowController setCurrentPlaylist:[[db playlists] libraryPlaylist]];
    if (historyMode == PRTopArtistsHistoryMode) {
        NSString *artist = [[dataSource objectAtIndex:[sender clickedRow]] objectForKey:@"artist"];
        [(PRTableViewController *)[[mainWindowController libraryViewController] currentViewController] highlightArtist:artist];
    } else {
        PRFile file = [[[dataSource objectAtIndex:[sender clickedRow]] objectForKey:@"file"] intValue];
        [[mainWindowController libraryViewController] highlightFile:file];
    }
}

// ========================================
// NSTableView DataSource
// ========================================

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView_
{
    if (tableView_ == tableView) {
        return [dataSource count];
    }
	return 0;
}

- (id)            tableView:(NSTableView *)tableView_
  objectValueForTableColumn:(NSTableColumn *)tableColumn 
						row:(NSInteger)row
{
    if (tableView_ != tableView) {
        return nil;
    }
    
    if (historyMode == PRTopArtistsHistoryMode) {
        NSDictionary *dict = [dataSource objectAtIndex:row];
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [dict objectForKey:@"artist"], @"title",
                [dict objectForKey:@"count"], @"value",
                [dict objectForKey:@"max"], @"max",
                [[dict objectForKey:@"count"] stringValue], @"subSubTitle",
                nil];
    } else if (historyMode == PRTopSongsHistoryMode) {
        NSDictionary *dict = [dataSource objectAtIndex:row];
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [dict objectForKey:@"artist"], @"title",
                [dict objectForKey:@"title"], @"subtitle",
                [dict objectForKey:@"count"], @"value",
                [dict objectForKey:@"max"] , @"max",
                [[dict objectForKey:@"count"] stringValue], @"subSubTitle",
                nil];
    } else if (historyMode == PRRecentlyAddedHistoryMode) {
        NSDictionary *dict = [dataSource objectAtIndex:row];
        NSString *dateStr;
        if ([[dict objectForKey:@"date"] timeIntervalSinceDate:[NSDate dateWithNaturalLanguageString:@"midnight today"]] > 0) {
            dateStr = [_timeFormatter stringFromDate:[dict objectForKey:@"date"]];
        } else {
            dateStr = [_dateFormatter stringFromDate:[dict objectForKey:@"date"]];
        }
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSString stringWithFormat:@"%@  —  %@",[dict objectForKey:@"count"],[dict objectForKey:@"album"]], @"subtitle",
                [dict objectForKey:@"artist"], @"title",
                dateStr, @"subSubTitle",
                nil];
    } else if (historyMode == PRRecentlyPlayedHistoryMode) {
        NSDictionary *dict = [dataSource objectAtIndex:row];
        NSString *dateStr;
        if ([[dict objectForKey:@"date"] timeIntervalSinceDate:[NSDate dateWithNaturalLanguageString:@"midnight today"]] > 0) {
            dateStr = [_timeFormatter stringFromDate:[dict objectForKey:@"date"]];
        } else {
            dateStr = [_dateFormatter stringFromDate:[dict objectForKey:@"date"]];
        }
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [dict objectForKey:@"artist"], @"title",
                [dict objectForKey:@"title"], @"subtitle",
                dateStr, @"subSubTitle",
                nil];
    } else {
        [PRException raise:NSInternalInconsistencyException format:@"Invalid History Mode"];
    }
	return nil;
}

// ========================================
// NSTableView Delegate
// ========================================

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return FALSE;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[aCell objectValue]];
//	if ([(PRRolloverTableView *)aTableView mouseOverRow] == rowIndex) {
//        [dictionary setObject:[NSNumber numberWithBool:TRUE] forKey:@"mouseOver"];
//    } else {
//        [dictionary setObject:[NSNumber numberWithBool:FALSE] forKey:@"mouseOver"];
//    }
    
    [aCell setObjectValue:dictionary];
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return FALSE;
}

@end