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
#import "PRLog.h"


@implementation PRHistoryViewController

@dynamic historyMode;

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_ mainWindowController:(PRMainWindowController *)mainWindowController_
{
    self = [super initWithNibName:@"PRHistoryView" bundle:nil];
	if (self) {
		db = db_;
		mainWindowController = mainWindowController_;
        historyMode = PRTopArtistsHistoryMode;
	}
	return self;
}

- (void)dealloc
{
    [db release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, 2267)];
    [(PRScrollView *)[self view] setDocumentView:[background superview]];
    [(NSScrollView *)[self view] scrollToTop];
    
    [divider setColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    
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
      
    [tableView setDelegate:self];
    [tableView setRowHeight:42];
    [tableView setIntercellSpacing:NSMakeSize(0, 0)];
    [tableView setDataSource:self];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableViewAction:)];
    
    [[topSongsButton cell] setHighlightsBy:NSContentsCellMask];
    [[topArtistsButton cell] setHighlightsBy:NSContentsCellMask];
    [[recentlyAddedButton cell] setHighlightsBy:NSContentsCellMask];
    [[recentlyPlayedButton cell] setHighlightsBy:NSContentsCellMask];
    
    [self updateUI];
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
            [[PRLog sharedLog] presentFatalError:nil];
            break;
    }
    [tableView reloadData];
    [self updateUI];
}

- (void)updateUI
{
    int rows = [self numberOfRowsInTableView:tableView];
    float height = 235 + 42 * (rows-2);
    if (height < 400) {
        height = 400;
    }
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, height)];
    [background setFrame:NSMakeRect([background frame].origin.x, [[background superview] frame].size.height - height, 650, height)];
    
    NSColor *color = [NSColor colorWithDeviceWhite:0.7 alpha:1.0];
    NSColor *alternateColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    
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
    [topSongsButton setTextColor:color];
    [topArtistsButton setTextColor:color];
    [recentlyAddedButton setTextColor:color];
    [recentlyPlayedButton setTextColor:color];
    [button setTextColor:alternateColor];
    
    NSTextFieldCell *cell = [[tableView tableColumnWithIdentifier:@"column2"] dataCell];
    [cell setBackgroundStyle:NSBackgroundStyleLight];
    [cell setTextColor:[NSColor colorWithCalibratedWhite:0.3 alpha:1.0]];
    switch (historyMode) {
        case PRTopArtistsHistoryMode:
            [cell setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:18]];
            break;
        case PRTopSongsHistoryMode:
            [cell setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:18]];
            break;
        case PRRecentlyAddedHistoryMode:
            [cell setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:12]];
            break;
        case PRRecentlyPlayedHistoryMode:
            [cell setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:12]];
            break;
        default:
            [cell setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:14]];
            break;
    }
    
    bool hidden = !(historyMode == PRTopArtistsHistoryMode || historyMode == PRTopSongsHistoryMode);
    if (hidden) {
//        [tableView setBordered:0];
        [tableView setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
    } else {
//        [tableView setBordered:0];
        [tableView setGridStyleMask:NSTableViewGridNone];
    }
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
	
    PRFile file = [[[dataSource objectAtIndex:[sender clickedRow]] objectForKey:@"file"] intValue];
    [mainWindowController setCurrentMode:PRLibraryMode];
    [mainWindowController setCurrentPlaylist:[[db playlists] libraryPlaylist]];
    [[mainWindowController libraryViewController] highlightFile:file];
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
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [[dataSource objectAtIndex:row] objectForKey:@"artist"], @"title",
                [[dataSource objectAtIndex:row] objectForKey:@"icon"], @"icon",
                [[dataSource objectAtIndex:row] objectForKey:@"count"], @"value",
                [[dataSource objectAtIndex:row] objectForKey:@"max"], @"max",
                [[[dataSource objectAtIndex:row] objectForKey:@"count"] stringValue], @"subSubTitle",
                [NSNumber numberWithInt:0], @"kind",
                nil];
    } else if (historyMode == PRTopSongsHistoryMode) {
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [[dataSource objectAtIndex:row] objectForKey:@"title"], @"title",
                [[dataSource objectAtIndex:row] objectForKey:@"artist"], @"subtitle",
                [[dataSource objectAtIndex:row] objectForKey:@"icon"], @"icon",
                [[dataSource objectAtIndex:row] objectForKey:@"count"], @"value",
                [[dataSource objectAtIndex:row] objectForKey:@"max"] , @"max",
                [[[dataSource objectAtIndex:row] objectForKey:@"count"] stringValue], @"subSubTitle",
                [NSNumber numberWithInt:0], @"kind",
                nil];
    } else if (historyMode == PRRecentlyAddedHistoryMode) {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"M/dd  h:mm a"];
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [[dataSource objectAtIndex:row] objectForKey:@"title"], @"title",
                [[dataSource objectAtIndex:row] objectForKey:@"artist"], @"subtitle",
                [[dataSource objectAtIndex:row] objectForKey:@"icon"], @"icon",
                [dateFormatter stringFromDate:[[dataSource objectAtIndex:row] objectForKey:@"date"]], @"subSubTitle",
                [NSNumber numberWithInt:1], @"kind",
                nil];
    } else if (historyMode == PRRecentlyPlayedHistoryMode) {
        PRFile file = [[[dataSource objectAtIndex:row] objectForKey:@"file"] intValue];
        NSImage *icon;
        [[db albumArtController] albumArt:&icon forFile:file _error:nil];
        if (!icon) {
            icon = [NSImage imageNamed:@"PRLightAlbumArt"];
        }
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"M/dd  h:mm a"];
        NSDate *date = [[dataSource objectAtIndex:row] objectForKey:@"date"];
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [[dataSource objectAtIndex:row] objectForKey:@"title"], @"title",
                [[dataSource objectAtIndex:row] objectForKey:@"artist"], @"subtitle",
                icon, @"icon",
                [dateFormatter stringFromDate:date], @"subSubTitle",
                [NSNumber numberWithInt:1], @"kind",
                nil];
    } else {
        [[PRLog sharedLog] presentFatalError:nil];
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