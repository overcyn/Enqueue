#import "PRTableViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRNowPlayingController.h"
#import "PRLibraryViewSource.h"
#import "PRLibraryViewController.h"
#import "PRRuleViewController.h"
#import "PRCenteredTextFieldCell.h"
#import "PRNumberFormatter.h"
#import "PRSizeFormatter.h"
#import "PRTimeFormatter.h"
#import "PRTableHeaderCell.h"
#import "PRRatingCell.h"
#import "PRBitRateFormatter.h"
#import "PRKindFormatter.h"
#import "PRDateFormatter.h"
#import "PRUserDefaults.h"
#import "PRStringFormatter.h"
#import "PRQueue.h"
#import "PRPlaylists+Extensions.h"
#import "NSString+Extensions.h"
#import "sqlite_str.h"
#import "PRTagger.h"


@implementation PRTableViewController

// ========================================
// Initialization
// ========================================

- (id)       initWithDb:(PRDb *)db_ 
   nowPlayingController:(PRNowPlayingController *)now_
  libraryViewController:(PRLibraryViewController *)libraryViewController_
{
    // implemented in subclasses
	return nil;
}

- (void)dealloc
{
    [sizeFormatter release];
    [timeFormatter release];
    [numberFormatter release];
    [libraryMenu release];
    [headerMenu release];
    [browserHeaderMenu release];
    [db release];
    [now release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	// BrowserSplitView
	[verticalBrowserSplitView setDelegate:self];
	[horizontalBrowserSplitView setDelegate:self];
	[horizontalBrowserSubSplitview setDelegate:self];
    
	// LibraryTableView
	[libraryTableView setTarget:self];
	[libraryTableView setDoubleAction:@selector(play)];
	[libraryTableView registerForDraggedTypes:[NSArray arrayWithObject:PRFilePboardType]];
	[libraryTableView setVerticalMotionCanBeginDrag:FALSE];
	[libraryTableView setDataSource:self];
	[libraryTableView setDelegate:self];
    [self setNextResponder:[libraryTableView nextResponder]];
    [libraryTableView setNextResponder:self];
	
	// LibraryTableView TableColumns
    NSTableColumn *tableColumn;
    NSMutableArray *tableColumns = [NSMutableArray array];
    stringFormatter = [[PRStringFormatter alloc] init];
    numberFormatter = [[PRNumberFormatter alloc] init];
    sizeFormatter = [[PRSizeFormatter alloc] init];
    timeFormatter = [[PRTimeFormatter alloc] init];
    bitRateFormatter = [[PRBitRateFormatter alloc] init];
    kindFormatter = [[PRKindFormatter alloc] init];
    dateFormatter = [[PRDateFormatter alloc] init];
    
    // Playlist Index
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRPlaylistIndexSort]] autorelease];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:40];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
    [[tableColumn headerCell] setStringValue:@"#"];
    [[tableColumn headerCell] setAlignment:NSCenterTextAlignment];
    [tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setAlignment:NSCenterTextAlignment];
    [tableColumn setEditable:FALSE];
    [tableColumns addObject:tableColumn];
    
	// Path
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRPathFileAttribute]] autorelease];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Path"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// Title
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRTitleFileAttribute]] autorelease];
	[tableColumn setWidth:300];
	[tableColumn setMinWidth:50];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Title"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// Artist
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRArtistFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:50];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Artist"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// Album
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRAlbumFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:50];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Album"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// AlbumArtist
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRAlbumArtistFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:50];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Album Artist"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// Composer
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRComposerFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:50];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Composer"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// Genre
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRGenreFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:50];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Genre"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// Year
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRYearFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Year"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setFormatter:numberFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
    // Comments
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRCommentsFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:50];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Comments"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
    
	// BPM
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRBPMFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"BPM"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setFormatter:numberFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// Track
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRTrackNumberFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Track #"];
	[[tableColumn headerCell] setAlignment:NSCenterTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setFormatter:numberFormatter];
	[[tableColumn dataCell] setAlignment:NSCenterTextAlignment];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// Disc
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRDiscNumberFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Disc #"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setFormatter:numberFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:TRUE];
	[tableColumns addObject:tableColumn];
	
	// PlayCount
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRPlayCountFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Plays"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setFormatter:numberFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// DateAdded
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRDateAddedFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Date Added"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:dateFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// LastPlayed
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRLastPlayedFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Last Played"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:dateFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// Size
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRSizeFileAttribute]] autorelease];
	[tableColumn setWidth:100];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Size"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setFormatter:sizeFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// Kind
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRKindFileAttribute]] autorelease];
	[tableColumn setWidth:200];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Kind"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:kindFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// Time
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRTimeFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Time"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setFormatter:timeFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// Bitrate
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRBitrateFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Bitrate"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
    [[tableColumn dataCell] setFormatter:bitRateFormatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// Channels
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRChannelsFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Channels"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// SampleRate
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRSampleRateFileAttribute]] autorelease];
	[tableColumn setWidth:40];
	[tableColumn setMinWidth:40];
	[tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Sample Rate"];
	[[tableColumn headerCell] setAlignment:NSRightTextAlignment];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
    
    // Rating
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:[NSString stringWithInt:PRRatingFileAttribute]] autorelease];
    [tableColumn setWidth:75];
    [tableColumn setMinWidth:75];
    [tableColumn setMaxWidth:75];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
    [[tableColumn headerCell] setStringValue:@"Rating"];
    [[tableColumn headerCell] setAlignment:NSLeftTextAlignment];
    PRRatingCell *ratingCell = [[[PRRatingCell alloc] init] autorelease];
    [ratingCell setSegmentCount:6];
    [ratingCell setWidth:3 forSegment:0];
    [ratingCell setWidth:13 forSegment:1];
    [ratingCell setWidth:13 forSegment:2];
    [ratingCell setWidth:13 forSegment:3];
    [ratingCell setWidth:13 forSegment:4];
    [ratingCell setWidth:13 forSegment:5];
    [ratingCell setControlSize:NSSmallControlSize];
    [ratingCell setSegmentStyle: NSSegmentStyleTexturedRounded];
    [tableColumn setDataCell:ratingCell];
    [tableColumn setEditable:FALSE];
    [tableColumns addObject:tableColumn];
	
	for (NSTableColumn *i in tableColumns) {
		[i setHidden:TRUE];
		NSTextFieldCell *cell = [i dataCell];
		[cell setFont:[NSFont systemFontOfSize:11]];
		[cell setTruncatesLastVisibleLine:TRUE];
		[cell setWraps:FALSE];
		[cell setLineBreakMode:NSLineBreakByTruncatingTail];
		[cell setEditable:TRUE];
		[libraryTableView addTableColumn:i];
	}
	
	// LibraryTableView Context menu
	libraryMenu = [[NSMenu alloc] init];
	[libraryMenu setDelegate:self];
	[libraryTableView setMenu:libraryMenu];
	
	// LibraryTableView Header Context Menu
	headerMenu = [[NSMenu alloc] init];
	[headerMenu setDelegate:self];
	[[libraryTableView headerView] setMenu:headerMenu];
	
	// BrowserTableView Context Menu
	browserHeaderMenu = [[NSMenu alloc] init];
	[browserHeaderMenu setDelegate:self];
	[[horizontalBrowser1TableView headerView] setMenu:browserHeaderMenu];
	[[horizontalBrowser2TableView headerView] setMenu:browserHeaderMenu];
	[[horizontalBrowser3TableView headerView] setMenu:browserHeaderMenu];
    [[verticalBrowser1TableView headerView] setMenu:browserHeaderMenu];
    
    [[[horizontalBrowser1TableView superview] superview] retain];
    [[[horizontalBrowser2TableView superview] superview] retain];
    [[[horizontalBrowser3TableView superview] superview] retain];
    
	// BrowserTableView
	[horizontalBrowser1TableView setTarget:self];
	[horizontalBrowser1TableView setDoubleAction:@selector(playBrowser:)];
	[horizontalBrowser1TableView setDataSource:self];
	[horizontalBrowser1TableView setDelegate:self];
	
	[horizontalBrowser2TableView setTarget:self];
	[horizontalBrowser2TableView setDoubleAction:@selector(playBrowser:)];
	[horizontalBrowser2TableView setDataSource:self];
	[horizontalBrowser2TableView setDelegate:self];
	
	[horizontalBrowser3TableView setTarget:self];
	[horizontalBrowser3TableView setDoubleAction:@selector(playBrowser:)];
	[horizontalBrowser3TableView setDataSource:self];
	[horizontalBrowser3TableView setDelegate:self];
    
    [verticalBrowser1TableView setTarget:self];
	[verticalBrowser1TableView setDoubleAction:@selector(playBrowser:)];
	[verticalBrowser1TableView setDataSource:self];
	[verticalBrowser1TableView setDelegate:self];
	
	// Update
    [[NSNotificationCenter defaultCenter] observeLibraryChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeFilesChanged:self sel:@selector(tagsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeUseAlbumArtistChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistFilesChanged:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(playingFileChanged:)];
    
    [pool drain];
}

// ========================================
// Accessors
// ========================================

- (int)sortColumn
{
    return [[db playlists] listViewSortColumnForPlaylist:currentPlaylist];
}

- (void)setSortColumn:(int)sortColumn
{
    [[db playlists] setListViewSortColumn:sortColumn forPlaylist:currentPlaylist];
}

- (BOOL)ascending
{
    return [[db playlists] listViewAscendingForPlaylist:currentPlaylist];
}

- (void)setAscending:(BOOL)ascending
{
    [[db playlists] setListViewAscending:ascending forPlaylist:currentPlaylist];
}

- (NSDictionary *)info
{
	return [[db libraryViewSource] info];
}

- (NSArray *)selection
{
	NSMutableArray *selectionArray = [NSMutableArray array];
	NSIndexSet *selectionIndexes = [self dbRowIndexesForTableRowIndexes:[libraryTableView selectedRowIndexes]];
	NSInteger index = 0;
	while ((index = [selectionIndexes indexGreaterThanOrEqualToIndex:index]) != NSNotFound) {
        PRFile file = [[db libraryViewSource] fileForRow:index];
		[selectionArray addObject:[NSNumber numberWithInt:file]];
		index++;
	}
	
	return [NSArray arrayWithArray:selectionArray];
}

- (void)setCurrentPlaylist:(int)newPlaylist
{	
	currentPlaylist = newPlaylist;
	if (currentPlaylist != -1) {        
		[self loadTableColumns];
        [self loadBrowser];
        [self reloadData:TRUE];
        [libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        
        [libraryTableView scrollPoint:NSMakePoint(0, 0)];
        [browser1TableView scrollRowToVisible:[browser1TableView selectedRow]];
        [browser2TableView scrollRowToVisible:[browser2TableView selectedRow]];
        [browser3TableView scrollRowToVisible:[browser3TableView selectedRow]];
	}
}

// ========================================
// Update
// ========================================

- (void)playingFileChanged:(NSNotification *)note
{
    NSIndexSet *rows = [NSIndexSet indexSetWithIndexesInRange:[libraryTableView rowsInRect:[libraryTableView visibleRect]]];
    NSIndexSet *columns = [NSIndexSet indexSetWithIndex:[libraryTableView columnWithIdentifier:[NSString stringWithInt:PRTrackNumberFileAttribute]]];
    [libraryTableView reloadDataForRowIndexes:rows columnIndexes:columns];
}

- (void)libraryDidChange:(NSNotification *)notification
{
    if (currentPlaylist != -1) {
        [self reloadData:TRUE];
    }
}

- (void)tagsDidChange:(NSNotification *)notification
{
    if (currentPlaylist != -1) {
		[self reloadData:TRUE];
	}
}

- (void)playlistDidChange:(NSNotification *)notification
{
	if (currentPlaylist == -1 || [[[notification userInfo] valueForKey:@"playlist"] intValue] != currentPlaylist) {
        return;
	}
    [self reloadData:TRUE];
    [libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
    [libraryTableView scrollPoint:NSMakePoint(0, 0)];
    [browser1TableView scrollRowToVisible:[browser1TableView selectedRow]];
    [browser2TableView scrollRowToVisible:[browser2TableView selectedRow]];
    [browser3TableView scrollRowToVisible:[browser3TableView selectedRow]];
}

- (void)playlistFilesChanged:(NSNotification *)note
{
    if (currentPlaylist == -1 || [[[note userInfo] valueForKey:@"playlist"] intValue] != currentPlaylist) {
        return;
	}
    [self reloadData:TRUE];
    [libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
    [libraryTableView scrollPoint:NSMakePoint(0, 0)];
    [browser1TableView scrollRowToVisible:[browser1TableView selectedRow]];
    [browser2TableView scrollRowToVisible:[browser2TableView selectedRow]];
    [browser3TableView scrollRowToVisible:[browser3TableView selectedRow]];
}

- (void)ruleDidChange:(NSNotification *)notification
{
	if (currentPlaylist != -1) {
		[self reloadData:TRUE];
	}
}

// ========================================
// Action
// ========================================

- (void)play
{
	if ([self dbRowForTableRow:[libraryTableView clickedRow]] <= 0) {
        return;
	}
    if ([[libraryTableView selectedRowIndexes] count] > 1) {
        [selectedRows release];
        selectedRows = [[libraryTableView selectedRowIndexes] retain];
        [self playSelected];
        return;
    }
    [now stop];
    [[db playlists] clearPlaylist:[now currentPlaylist]];
    [[db playlists] appendFilesFromLibraryViewSourceToPlaylist:[now currentPlaylist]];
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
    [now playItemAtIndex:[self dbRowForTableRow:[libraryTableView clickedRow]]];
}

- (void)playBrowser:(id)sender
{
    if ([sender clickedRow] == -1) {
        return;
	}
    [now stop];
    [[db playlists] clearPlaylist:[now currentPlaylist]];
    [[db playlists] appendFilesFromLibraryViewSourceToPlaylist:[now currentPlaylist]];
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
    if ([[db playlists] countForPlaylist:[now currentPlaylist]] > 0) {
        [now playItemAtIndex:1];
    }
}

- (void)playSelected
{
    [now stop];
    [[db playlists] clearPlaylist:[now currentPlaylist]];
	NSInteger currentIndex = [selectedRows firstIndex];
	while (currentIndex != NSNotFound) {
        PRFile file_ = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:currentIndex]];
        [[db playlists] appendFile:file_ toPlaylist:[now currentPlaylist]];
        currentIndex = [selectedRows indexGreaterThanIndex:currentIndex];
	}
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
	[now playItemAtIndex:1];
}

- (void)append
{
	NSInteger currentIndex = [selectedRows firstIndex];
	while (currentIndex != NSNotFound) {
        PRFile file_ = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:currentIndex]];
        [[db playlists] appendFile:file_ toPlaylist:[now currentPlaylist]];
		currentIndex = [selectedRows indexGreaterThanIndex:currentIndex];
	}
	[[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
}

- (void)playNext
{
	NSInteger currentIndex = [selectedRows firstIndex];
	while (currentIndex != NSNotFound) {
        PRFile file_ = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:currentIndex]];
        [[db playlists] appendFile:file_ toPlaylist:[now currentPlaylist]];
		currentIndex = [selectedRows indexGreaterThanIndex:currentIndex];
	}
    
    // Add to queue
    int count = [[db playlists] countForPlaylist:[now currentPlaylist]];
    for (int i = count - [selectedRows count]; i < count; i++) {
        PRPlaylistItem item = [[db playlists] playlistItemAtIndex:i+1 inPlaylist:[now currentPlaylist]];
        [[db queue] appendPlaylistItem:item];
    }
	[[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
}

- (void)addToPlaylist:(id)sender
{
	NSInteger currentIndex = 0;
	while ((currentIndex = [selectedRows indexGreaterThanOrEqualToIndex:currentIndex]) != NSNotFound) {
        PRFile file_ = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:currentIndex]];
        [[db playlists] appendFile:file_ toPlaylist:[[sender representedObject] intValue]];
        currentIndex++;
    }
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[[sender representedObject] intValue]];
}

- (void)getInfo
{
	[libraryViewController infoViewToggle];
}

- (void)reveal
{
	int row = [selectedRows indexGreaterThanOrEqualToIndex:0];
    PRFile file_ = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:row]];
    NSString *URLString = [[db library] valueForFile:file_ attribute:PRPathFileAttribute];
	[[NSWorkspace sharedWorkspace] selectFile:[[NSURL URLWithString:URLString] path] inFileViewerRootedAtPath:nil];
}

- (void)delete
{
    if ([selectedRows count] == 0) {
        return;
    }
    
    if (currentPlaylist != [[db playlists] libraryPlaylist]) {
        NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
        NSUInteger index = [selectedRows firstIndex];
        NSTableColumn *tableColumn = [libraryTableView tableColumnWithIdentifier:[NSString stringWithInt:PRPlaylistIndexSort]];
        while (index != NSNotFound) {
            NSNumber *playlistIndex = [self tableView:libraryTableView objectValueForTableColumn:tableColumn row:index];
            [indexesToDelete addIndex:[playlistIndex intValue]];
            index = [selectedRows indexGreaterThanIndex:index];
        }
        [[db playlists] removeFilesAtIndexes:indexesToDelete fromPlaylist:currentPlaylist];
        
        [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:currentPlaylist];
        [libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        return;
    }
    
    NSString *message;
    if ([selectedRows count] == 1) {
        message = @"Do you want to remove the selected song from your library?";
    } else {
        message = [NSString stringWithFormat:@"Do you want to remove the %d selected songs from your library?", [selectedRows count]];
    }
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Remove"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:message];
    [alert setInformativeText:@"These files will not be deleted from your computer"];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[[self view] window] 
                      modalDelegate:self 
                     didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:) 
                        contextInfo:nil];    
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
    if (returnCode == NSAlertFirstButtonReturn) {
        NSInteger row = [selectedRows firstIndex];
        NSMutableIndexSet *selectedFiles = [[[NSMutableIndexSet alloc] init] autorelease];
        while (row != NSNotFound) {
            PRFile file = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:row]];
            [selectedFiles addIndex:file];
            
            // stop if currentFile
            if (file == [now currentFile]) {
                [now stop];
            }
            row = [selectedRows indexGreaterThanIndex:row];
        }
        
        [[db library] removeFiles:selectedFiles];
        [[NSNotificationCenter defaultCenter] postLibraryChanged];
        [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
        [libraryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:FALSE];
    }    
}

- (IBAction)delete:(id)sender
{
    [selectedRows release];
    selectedRows = [[libraryTableView selectedRowIndexes] retain];
    [self delete];
}

// ========================================
// UI Update
// ========================================

- (void)reloadData:(BOOL)force
{
	// update libSrc & reload tables
    int tables = [[db libraryViewSource] refreshWithPlaylist:currentPlaylist force:force];
	
	// reload tables
    monitorSelection = FALSE;
    NSIndexSet *indexSet;
    if ((tables & PRLibraryView) == PRLibraryView) {
        [libraryTableView reloadData];
    }
    if ((tables & PRBrowser1View) == PRBrowser1View) {
        [browser1TableView reloadData];
        indexSet = [[db libraryViewSource] selectionForBrowser:1];
        if (![indexSet isEqualToIndexSet:[browser1TableView selectedRowIndexes]]) {
            [browser1TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }
    if ((tables & PRBrowser2View) == PRBrowser2View) {
        [browser2TableView reloadData];
        indexSet = [[db libraryViewSource] selectionForBrowser:2];
        if (![indexSet isEqualToIndexSet:[browser2TableView selectedRowIndexes]]) {
            [browser2TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }
    if ((tables & PRBrowser3View) == PRBrowser3View) {
        [browser3TableView reloadData];
        indexSet = [[db libraryViewSource] selectionForBrowser:3];
        if (![indexSet isEqualToIndexSet:[browser3TableView selectedRowIndexes]]) {
            [browser3TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }
    monitorSelection = TRUE;
	
    [[NSNotificationCenter defaultCenter] postLibraryViewChanged];
    [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
}

- (void)loadBrowser
{
    refreshing = TRUE;
    // Get Browser Info
    [verticalBrowserSplitView removeFromSuperview];
    [horizontalBrowserSplitView removeFromSuperview];
    [libraryScrollView removeFromSuperview];
    int browserPosition = [[db playlists] isVerticalForPlaylist:currentPlaylist];
	if (browserPosition == PRBrowserPositionVertical) {
        [[self view] addSubview:verticalBrowserSplitView];
        NSRect bounds = [[self view] bounds];
        bounds.size.height += 1;
        [verticalBrowserSplitView setFrame:bounds];
        [verticalBrowserLibrarySuperview addSubview:libraryScrollView];
        [libraryScrollView setFrame:[verticalBrowserLibrarySuperview bounds]];
        browser1TableView = nil;
        browser2TableView = nil;
        browser3TableView = verticalBrowser1TableView;
        [verticalBrowserSplitView setPosition:[[db playlists] verticalBrowser3WidthForPlaylist:currentPlaylist] ofDividerAtIndex:0];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [[self view] addSubview:horizontalBrowserSplitView];
        NSRect bounds = [[self view] bounds];
        bounds.size.height += 1;
        [horizontalBrowserSplitView setFrame:bounds];
        [horizontalBrowserLibrarySuperview addSubview:libraryScrollView];
        bounds = [horizontalBrowserLibrarySuperview bounds];
        bounds.size.height += 1;
        [libraryScrollView setFrame:bounds];
        
        [[[horizontalBrowser1TableView superview] superview] removeFromSuperview];
        [[[horizontalBrowser2TableView superview] superview] removeFromSuperview];
        [[[horizontalBrowser3TableView superview] superview] removeFromSuperview];
        
        if ([[db playlists] browser2AttributeForPlaylist:currentPlaylist] == 0) {
            [horizontalBrowserSubSplitview addSubview:[[horizontalBrowser3TableView superview] superview]];
        } else if ([[db playlists] browser1AttributeForPlaylist:currentPlaylist] == 0) {
            [horizontalBrowserSubSplitview addSubview:[[horizontalBrowser2TableView superview] superview]];
            [horizontalBrowserSubSplitview addSubview:[[horizontalBrowser3TableView superview] superview]];
            [horizontalBrowserSubSplitview setPosition:[horizontalBrowserSubSplitview frame].size.width*1/5 ofDividerAtIndex:0];
        } else {
            [horizontalBrowserSubSplitview addSubview:[[horizontalBrowser1TableView superview] superview]];
            [horizontalBrowserSubSplitview addSubview:[[horizontalBrowser2TableView superview] superview]];
            [horizontalBrowserSubSplitview addSubview:[[horizontalBrowser3TableView superview] superview]];
            [horizontalBrowserSubSplitview setPosition:[horizontalBrowserSubSplitview frame].size.width/3 ofDividerAtIndex:0];
            [horizontalBrowserSubSplitview setPosition:[horizontalBrowserSubSplitview frame].size.width*2/3 ofDividerAtIndex:1];
        }
        
        browser1TableView = horizontalBrowser1TableView;
        browser2TableView = horizontalBrowser2TableView;
        browser3TableView = horizontalBrowser3TableView;
        [horizontalBrowserSplitView setPosition:[[db playlists] horizontalBrowserHeightForPlaylist:currentPlaylist] ofDividerAtIndex:0];
    } else if (browserPosition == PRBrowserPositionHidden){
        [[self view] addSubview:libraryScrollView];
        NSRect bounds = [[self view] bounds];
        bounds.size.height += 1;
        [libraryScrollView setFrame:bounds];
        browser1TableView = nil;
        browser2TableView = nil;
        browser3TableView = nil;
    }
    
	int browser1Grouping = [[db playlists] browser1AttributeForPlaylist:currentPlaylist];
	int browser2Grouping = [[db playlists] browser2AttributeForPlaylist:currentPlaylist];
	int browser3Grouping = [[db playlists] browser3AttributeForPlaylist:currentPlaylist];
    NSString *browser1Title = [[PRLibrary columnNameForFileAttribute:browser1Grouping] capitalizedString];
	[[[[browser1TableView tableColumns] objectAtIndex:0] headerCell] setStringValue:browser1Title];
    NSString *browser2Title = [[PRLibrary columnNameForFileAttribute:browser2Grouping] capitalizedString];
	[[[[browser2TableView tableColumns] objectAtIndex:0] headerCell] setStringValue:browser2Title];
    NSString *browser3Title = [[PRLibrary columnNameForFileAttribute:browser3Grouping] capitalizedString];
	[[[[browser3TableView tableColumns] objectAtIndex:0] headerCell] setStringValue:browser3Title];
    refreshing = FALSE;
}

- (void)saveBrowser
{
    if (currentPlaylist == -1) {
        return;
    }
    int browserPosition = [[db playlists] isVerticalForPlaylist:currentPlaylist];
    if (browserPosition == PRBrowserPositionVertical) {
        float width = [[[browser3TableView superview] superview] bounds].size.width;
        [[db playlists] setVerticalBrowser3Width:width forPlaylist:currentPlaylist];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        float height = [horizontalBrowserSubSplitview frame].size.height;
        [[db playlists] setHorizontalBrowserHeight:height forPlaylist:currentPlaylist];
    }
}

- (void)loadTableColumns
{
    refreshing = TRUE;
	// set column attributes
    NSArray *columnsInfo = [self columnInfo];
	for (int i = 0; i < [columnsInfo count]; i++) {
        NSDictionary *columnInfo = [columnsInfo objectAtIndex:i];
        NSTableColumn *tableColumn = [libraryTableView tableColumnWithIdentifier:[NSString stringWithNumber:[columnInfo valueForKey:@"identifier"]]];
        [tableColumn setWidth:[[columnInfo valueForKey:@"width"] intValue]];
        [tableColumn setHidden:[[columnInfo valueForKey:@"hidden"] boolValue]];
        [libraryTableView moveColumn:[[libraryTableView tableColumns] indexOfObject:tableColumn] toColumn:i];
    }
    
    // playlist column
    NSTableColumn *tableColumn = [libraryTableView tableColumnWithIdentifier:[NSString stringWithInt:PRPlaylistIndexSort]];
    [libraryTableView moveColumn:[[libraryTableView tableColumns] indexOfObject:tableColumn] toColumn:0];
    [[[libraryTableView tableColumns] objectAtIndex:0] setHidden:(currentPlaylist == [[db playlists] libraryPlaylist])];
	
	// highlight sort table column
    [self highlightTableColumn:[self tableColumnForAttribute:[self sortColumn]] 
                     ascending:[self ascending]];
    refreshing = FALSE;
}

- (void)saveTableColumns
{	
	NSArray *columns = [libraryTableView tableColumns];
	NSMutableArray *columnsInfo = [NSMutableArray array];
	for (NSTableColumn *i in columns) {
        if ([[i identifier] intValue] == PRPlaylistIndexSort) {
            continue;
        }
		NSDictionary *columnInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:[[i identifier] intValue]], @"identifier",
                                    [NSNumber numberWithBool:[i isHidden]], @"hidden",
                                    [NSNumber numberWithFloat:[i width]], @"width",
                                    nil];
		[columnsInfo addObject:columnInfo];
	}
    [self setColumnInfo:columnsInfo];
}

- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending
{
    for (NSTableColumn *i in [libraryTableView tableColumns]) {
        if (i != tableColumn) {
            [[i tableView] setIndicatorImage:nil inTableColumn:i];	
            continue;
        }
        NSImage *indicatorImage;
        if (ascending) {
            indicatorImage = [NSImage imageNamed:@"NSAscendingSortIndicator"];
        } else {
            indicatorImage = [NSImage imageNamed:@"NSDescendingSortIndicator"];
        }
        [[i tableView] setIndicatorImage:indicatorImage inTableColumn:i];	
	}
	[[tableColumn tableView] setHighlightedTableColumn:tableColumn];
}

// ========================================
// UI Action
// ========================================

- (void)toggleColumn:(id)sender
{
	NSTableColumn *column = [sender representedObject];
	[column setHidden:![column isHidden]];
	[self saveTableColumns];
}

- (void)toggleBrowser:(id)sender
{
	int browserGrouping = [[sender representedObject] intValue];
	
    // if On Top or On Left
    if (browserGrouping == -1) {
        [[db playlists] setVertical:PRBrowserPositionHorizontal forPlaylist:currentPlaylist];
        [[db playlists] setBrowser1Attribute:PRGenreFileAttribute forPlaylist:currentPlaylist];
        [[db playlists] setBrowser2Attribute:PRArtistFileAttribute forPlaylist:currentPlaylist];
        [[db playlists] setBrowser3Attribute:PRAlbumFileAttribute forPlaylist:currentPlaylist];
        [self loadBrowser];
        [self reloadData:TRUE];
        return;
    } else if (browserGrouping == -2) {
        [[db playlists] setVertical:PRBrowserPositionVertical forPlaylist:currentPlaylist];
        [[db playlists] setBrowser1Attribute:0 forPlaylist:currentPlaylist];
        [[db playlists] setBrowser2Attribute:0 forPlaylist:currentPlaylist];
        [[db playlists] setBrowser3Attribute:PRArtistFileAttribute forPlaylist:currentPlaylist];
        [self loadBrowser];
        [self reloadData:TRUE];
        return;
    } else if (browserGrouping == -3) {
        [[db playlists] setVertical:PRBrowserPositionHidden forPlaylist:currentPlaylist];
        [[db playlists] setBrowser1Attribute:0 forPlaylist:currentPlaylist];
        [[db playlists] setBrowser2Attribute:0 forPlaylist:currentPlaylist];
        [[db playlists] setBrowser3Attribute:0 forPlaylist:currentPlaylist];
        [self loadBrowser];
        [self reloadData:TRUE];
        return;
    }
        
    // if is Vertical
    if ([[db playlists] isVerticalForPlaylist:currentPlaylist]) {
        [[db playlists] setBrowser1Attribute:0 forPlaylist:currentPlaylist];
        [[db playlists] setBrowser2Attribute:0 forPlaylist:currentPlaylist];
        [[db playlists] setBrowser3Attribute:browserGrouping forPlaylist:currentPlaylist];
        [self loadBrowser];
        [self reloadData:TRUE];
        return;
    }
    
	int browser1Grouping = [[db playlists] browser1AttributeForPlaylist:currentPlaylist];
	int browser2Grouping = [[db playlists] browser2AttributeForPlaylist:currentPlaylist];
	int browser3Grouping = [[db playlists] browser3AttributeForPlaylist:currentPlaylist];
	
	// filter for duplicates
	NSMutableIndexSet *indexSet = [[[NSMutableIndexSet alloc] init] autorelease];
	[indexSet addIndex:browser1Grouping];
	[indexSet addIndex:browser2Grouping];
	[indexSet addIndex:browser3Grouping];
    if ([indexSet containsIndex:browserGrouping]) {
        [indexSet removeIndex:browserGrouping];
    } else {
        [indexSet addIndex:browserGrouping];
    }
    
    [indexSet removeIndex:0];
    if ([indexSet count] == 0) {
        [indexSet addIndex:PRArtistFileAttribute];
    }
    if ([indexSet count] > 3) {
        [indexSet removeIndex:PRComposerFileAttribute];
    }
	
	// sort
	// 3,2,8,13,0,0,0
	NSMutableArray *array = [NSMutableArray array];
	if ([indexSet containsIndex:3]) {
		[array addObject:[NSNumber numberWithInt:3]];
	}
	if ([indexSet containsIndex:2]) {
		[array addObject:[NSNumber numberWithInt:2]];
	}
	if ([indexSet containsIndex:8]) {
		[array addObject:[NSNumber numberWithInt:8]];
	}
	if ([indexSet containsIndex:13]) {
		[array addObject:[NSNumber numberWithInt:13]];
	}
	[array addObject:[NSNumber numberWithInt:0]];
	[array addObject:[NSNumber numberWithInt:0]];
	[array addObject:[NSNumber numberWithInt:0]];
    
	browser1Grouping = [[array objectAtIndex:2] intValue];
	browser2Grouping = [[array objectAtIndex:1] intValue];
	browser3Grouping = [[array objectAtIndex:0] intValue];
	
	// save
    [[db playlists] setBrowser1Attribute:browser1Grouping forPlaylist:currentPlaylist];
    [[db playlists] setBrowser2Attribute:browser2Grouping forPlaylist:currentPlaylist];
    [[db playlists] setBrowser3Attribute:browser3Grouping forPlaylist:currentPlaylist];
	[self loadBrowser];
    [self reloadData:FALSE];
}

- (void)highlightFile:(PRFile)file
{
    NSString *artist;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        artist = [[db library] valueForFile:file attribute:PRArtistFileAttribute];
    } else {
        artist = [[db library] valueForFile:file attribute:PRArtistAlbumArtistFileAttribute];
    }
    [self browseToArtist:artist];
	int dbRow = [[db libraryViewSource] rowForFile:file];
	if (dbRow == -1) {
        [[db playlists] setValue:@"" forPlaylist:currentPlaylist attribute:PRSearchPlaylistAttribute];
        [[db playlists] setSelection:[NSArray array] forBrowser:1 playlist:currentPlaylist];
        [[db playlists] setSelection:[NSArray array] forBrowser:2 playlist:currentPlaylist];
        [[db playlists] setSelection:[NSArray array] forBrowser:3 playlist:currentPlaylist];
        [[NSNotificationCenter defaultCenter] postPlaylistChanged:currentPlaylist];
		dbRow = [[db libraryViewSource] rowForFile:file];
	}
	if (dbRow != -1) {
		int tableRow = [self tableRowForDbRow:dbRow];
		[libraryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tableRow] byExtendingSelection:FALSE];
		[libraryTableView scrollRowToVisible:[self numberOfRowsInTableView:libraryTableView] - 1];
        [libraryTableView scrollRowToVisible:tableRow - 5];
		[libraryTableView scrollRowToVisible:tableRow];
		[[libraryTableView window] makeFirstResponder:libraryTableView];
	}
}

- (void)highlightFiles:(NSIndexSet *)files
{
    if ([files count] == 0) {
        return;
    }
    
    BOOL clearBrowserAndSearch = FALSE;
    NSMutableIndexSet *dbRows = [NSMutableIndexSet indexSet];
    NSUInteger index = [files firstIndex];
    while (index != NSNotFound) {
        int dbRow = [[db libraryViewSource] rowForFile:index];
        if (dbRow == -1) {
            clearBrowserAndSearch = TRUE;
            [dbRows removeAllIndexes];
            break;
        }
        [dbRows addIndex:dbRow];
        index = [files indexGreaterThanIndex:index];
    }
    
    if (clearBrowserAndSearch) {
        [[db playlists] setValue:@"" forPlaylist:currentPlaylist attribute:PRSearchPlaylistAttribute];
        [[db playlists] setValue:[NSKeyedArchiver archivedDataWithRootObject:[NSArray array]] forPlaylist:currentPlaylist attribute:PRBrowser1SelectionPlaylistAttribute];
        [[db playlists] setValue:[NSKeyedArchiver archivedDataWithRootObject:[NSArray array]] forPlaylist:currentPlaylist attribute:PRBrowser2SelectionPlaylistAttribute];
        [[db playlists] setValue:[NSKeyedArchiver archivedDataWithRootObject:[NSArray array]] forPlaylist:currentPlaylist attribute:PRBrowser3SelectionPlaylistAttribute];
        [[NSNotificationCenter defaultCenter] postPlaylistChanged:currentPlaylist];
        
        index = [files firstIndex];
        while (index != NSNotFound) {
            int dbRow = [[db libraryViewSource] rowForFile:index];
            if (dbRow == -1) {
                [dbRows removeAllIndexes];
                break;
            }
            [dbRows addIndex:dbRow];
            index = [files indexGreaterThanIndex:index];
        }
    }
    if ([dbRows count] > 0) {
        NSIndexSet *tableRows = [self tableRowIndexesForDbRowIndexes:dbRows];
        [libraryTableView selectRowIndexes:tableRows byExtendingSelection:FALSE];
        [libraryTableView scrollRowToVisible:[tableRows firstIndex]];
        [[libraryTableView window] makeFirstResponder:libraryTableView];
    }
}

- (void)highlightArtist:(NSString *)artist
{
    [self browseToArtist:artist];
    PRFileAttribute attribute;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        attribute = PRArtistAlbumArtistFileAttribute;
    } else {
        attribute = PRArtistFileAttribute;
    }
    int row = [[db libraryViewSource] firstRowWithValue:artist forAttribute:attribute]; 
    if (row == -1 || row == 1) {
        return;
    }
    row--;
    [libraryTableView scrollRowToVisible:[self numberOfRowsInTableView:libraryTableView] - 1];
    [libraryTableView scrollRowToVisible:row - 5];
    [libraryTableView scrollRowToVisible:row];
    [libraryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
}

- (void)browseToArtist:(NSString *)artist
{
    [[db playlists] setValue:@"" forPlaylist:currentPlaylist attribute:PRSearchPlaylistAttribute];
    [[db playlists] setSelection:[NSArray array] forBrowser:1 playlist:currentPlaylist];
    [[db playlists] setSelection:[NSArray array] forBrowser:2 playlist:currentPlaylist];
    [[db playlists] setSelection:[NSArray array] forBrowser:3 playlist:currentPlaylist];
    [[NSNotificationCenter defaultCenter] postPlaylistChanged:currentPlaylist];
    
    for (int i = 1; i <= 3; i++) {
        if ([[db playlists] attributeForBrowser:i playlist:currentPlaylist] != PRArtistFileAttribute) {
            continue;
        }
        int count = [[db libraryViewSource] countForBrowser:i];
        for (int j = 1; j < count + 1; j++) {
            if ([artist noCaseCompare:[[db libraryViewSource] valueForRow:j browser:i]] == NSOrderedSame) {
                [[db playlists] setSelection:[NSArray arrayWithObject:[[db libraryViewSource] valueForRow:j browser:i]] forBrowser:i playlist:currentPlaylist];
                break;
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postPlaylistChanged:currentPlaylist];
    [[libraryTableView window] makeFirstResponder:libraryTableView];
}

// ========================================
// UI Misc
// ========================================

- (int)browserForTableView:(NSTableView *)tableView;
{
	if (tableView == browser1TableView) {
		return 1;
	} else if (tableView == browser2TableView) {
		return 2;
	} else if (tableView == browser3TableView) {
		return 3;
	} else {
		NSLog(@"browserForTableView: Unknown TableView");
		return 0;
	}
}

- (NSArray *)columnInfo
{
    return [[db playlists] listViewColumnInfoForPlaylist:currentPlaylist];
}

- (void)setColumnInfo:(NSArray *)columnInfo
{
    [[db playlists] setListViewColumnInfo:columnInfo forPlaylist:currentPlaylist];
}

- (NSTableColumn *)tableColumnForAttribute:(int)attribute
{
	return [libraryTableView tableColumnWithIdentifier:[NSString stringWithInt:attribute]];
}

- (int)dbRowForTableRow:(int)tableRow
{
	return tableRow + 1;
}

- (NSIndexSet *)dbRowIndexesForTableRowIndexes:(NSIndexSet *)tableRowIndexes
{
	NSInteger index = 0;
	NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
	while ((index = [tableRowIndexes indexGreaterThanOrEqualToIndex:index]) != NSNotFound) {
		if ([self dbRowForTableRow:index] != -1) {
			[rowIndexes addIndex:[self dbRowForTableRow:index]];
		}
		index++;
	}
	return [[[NSIndexSet alloc] initWithIndexSet:rowIndexes] autorelease];
}

- (int)tableRowForDbRow:(int)dbRow
{
	return dbRow - 1;
}

- (NSIndexSet *)tableRowIndexesForDbRowIndexes:(NSIndexSet *)indexSet
{
    NSMutableIndexSet *tableRowIndexes = [NSMutableIndexSet indexSet];
    NSUInteger dbRow = [indexSet firstIndex];
    while (dbRow != NSNotFound) {
        [tableRowIndexes addIndex:[self tableRowForDbRow:dbRow]];
        dbRow = [indexSet indexGreaterThanIndex:dbRow];
    }
    return tableRowIndexes;
}

// ========================================
// TableView DataSource
// ========================================

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	int count;
	if (tableView == libraryTableView) {
		count = [[db libraryViewSource] count];
	} else if (tableView == browser1TableView) {
        count = [[db libraryViewSource] countForBrowser:1] + 1;
	} else if (tableView == browser2TableView) {
		count = [[db libraryViewSource] countForBrowser:2] + 1;
	} else if (tableView == browser3TableView) {
		count = [[db libraryViewSource] countForBrowser:3] + 1;
	} else {
        count = 0;
    }
	return count;
}

- (id)            tableView:(NSTableView *)tableView 
  objectValueForTableColumn:(NSTableColumn *)tableColumn 
      			        row:(NSInteger)rowIndex
{
	if (tableView == libraryTableView) {
		rowIndex = [self dbRowForTableRow:rowIndex];
        if (rowIndex == -1) {
            return nil;
        }
        
        PRFileAttribute attr = [[tableColumn identifier] intValue];
		if (attr == PRPlaylistIndexSort) {
            PRFile file_ = [[db libraryViewSource] fileForRow:rowIndex];
            int sortAttribute = [self sortColumn];
            int ascending = [self ascending];
            if (sortAttribute == PRPlaylistIndexSort && ascending) {
                return [NSNumber numberWithInt:rowIndex];
            } else if (sortAttribute == PRPlaylistIndexSort && !ascending) {
                int blah = [self numberOfRowsInTableView:libraryTableView] - rowIndex + 1;
                return [NSNumber numberWithInt:blah];
            } else {
                NSIndexSet *rows;
                [[db playlists] playlistIndexes:&rows forPlaylist:currentPlaylist file:file_ _error:nil];
                return [NSNumber numberWithInt:[rows firstIndex]];
            }
		} else {
            NSMutableArray *cachedAttributes = [NSMutableArray array];
            for (NSTableColumn *i in [libraryTableView tableColumns]) {
                if (![i isHidden] && [[i identifier] intValue] != PRPlaylistIndexSort) {
                    [cachedAttributes addObject:[NSNumber numberWithInt:[[i identifier] intValue]]];
                }
            }
            if (![cachedAttributes containsObject:[NSNumber numberWithInt:attr]]) {
                [cachedAttributes addObject:[NSNumber numberWithInt:attr]];
            }
            id value = [[db libraryViewSource] valueForRow:rowIndex attribute:attr andCacheAttributes:cachedAttributes];
            if (attr == PRRatingFileAttribute) {
                value = [NSNumber numberWithInt:floor([value intValue] / 20)];
            } else if (attr == PRPathFileAttribute) {
                value = [[NSURL URLWithString:value] path];
            } else if (attr == PRTrackNumberFileAttribute) {
                PRFile file_ = [[db libraryViewSource] fileForRow:rowIndex];
                if (file_ == [now currentFile]) {
                    value = [NSString stringWithFormat:@"◈"]; // @"◈◉«⁕»❯❮●◆ ";
                }
            }
            return value;
		}
	} else if (tableView == browser1TableView ||
			   tableView == browser2TableView ||
			   tableView == browser3TableView) {		
		int browser = [self browserForTableView:tableView];
		if (rowIndex == 0) {
            int grouping = [[db playlists] attributeForBrowser:browser playlist:currentPlaylist];
			int count = [[db libraryViewSource] countForBrowser:browser];
			return [NSString stringWithFormat:@"All (%d %@s)", count, [PRLibrary columnNameForFileAttribute:grouping]];
		} else {
            return [[db libraryViewSource] valueForRow:rowIndex browser:browser];
		}
	}
    return nil;
}

- (void)tableView:(NSTableView *)tableView 
   setObjectValue:(id)object
   forTableColumn:(NSTableColumn *)tableColumn 
			  row:(NSInteger)rowIndex
{
	int row = [self dbRowForTableRow:rowIndex];
	PRFileAttribute attribute = [[tableColumn identifier] intValue];
	
	if (row != -1) {
        PRFile file = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:rowIndex]];
		if (attribute == PRTitleFileAttribute ||
			attribute == PRArtistFileAttribute ||
			attribute == PRAlbumFileAttribute ||
			attribute == PRComposerFileAttribute ||
			attribute == PRAlbumArtistFileAttribute ||
			attribute == PRBPMFileAttribute ||
			attribute == PRYearFileAttribute ||
			attribute == PRTrackNumberFileAttribute ||
			attribute == PRTrackCountFileAttribute ||
			attribute == PRDiscNumberFileAttribute ||
			attribute == PRDiscCountFileAttribute ||
			attribute == PRCommentsFileAttribute ||
			attribute == PRGenreFileAttribute) {
            NSURL *URL = [NSURL URLWithString:[[db library] valueForFile:file attribute:PRPathFileAttribute]];
            [PRTagger setTag:object forAttribute:attribute URL:URL];
            [[db library] updateTagsForFile:file];
		} else if (attribute == PRRatingFileAttribute) {
            int rating = [object intValue] * 20;
            [[db library] setValue:[NSNumber numberWithInt:rating] forFile:file attribute:PRRatingFileAttribute];
		}
        [[NSNotificationCenter defaultCenter] postFilesChanged:[NSIndexSet indexSetWithIndex:file]];
	}
}

// ========================================
// TableView DragAndDrop
// ========================================

- (BOOL)     tableView:(NSTableView *)tableView
  writeRowsWithIndexes:(NSIndexSet *)rowIndexes
		  toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:[NSArray arrayWithObjects:PRFilePboardType, PRIndexesPboardType, nil] owner:self];
    
    // PRFilePboardType
	NSInteger currentIndex = 0;
	NSMutableArray *files = [NSMutableArray array];
	if (tableView == browser1TableView ||
		tableView == browser2TableView ||
		tableView == browser3TableView) {
		// If dragging from browser, get all files
		while (currentIndex < [self numberOfRowsInTableView:libraryTableView]) {
			if ([self dbRowForTableRow:currentIndex] != -1) {
				PRFile file = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:currentIndex]];
				[files addObject:[NSNumber numberWithInt:file]];
			}
			currentIndex++;
		}
	} else if (tableView == libraryTableView) {
		// If dragging from library, get selected files
		while ((currentIndex = [rowIndexes indexGreaterThanOrEqualToIndex:currentIndex]) != NSNotFound) {
			if ([self dbRowForTableRow:currentIndex] != -1) {
				PRFile file = [[db libraryViewSource] fileForRow:[self dbRowForTableRow:currentIndex]];
				[files addObject:[NSNumber numberWithInt:file]];
			}
			currentIndex++;
		}
	} else {
		return FALSE;
	}
    
    // PRIndexesPboardType
    NSIndexSet *indexes = [NSIndexSet indexSet];
    if (tableView == libraryTableView && [self sortColumn] == PRPlaylistIndexSort) {
        indexes = [[[NSIndexSet alloc] initWithIndexSet:[self dbRowIndexesForTableRowIndexes:rowIndexes]] autorelease];
    }
    
    // Write to Pboard
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:files]
            forType:PRFilePboardType];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:indexes]
            forType:PRIndexesPboardType];
	return TRUE;
}

- (NSDragOperation)tableView:(NSTableView*)tableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSData *indexesData = [pasteboard dataForType:PRIndexesPboardType];
    NSIndexSet *indexes;
    if (indexesData) {
        indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexesData];
    } else {
        indexes = [NSIndexSet indexSet];
    }
    
    NSIndexSet *indexSet1 = [[db libraryViewSource] selectionForBrowser:1];
    NSIndexSet *indexSet2 = [[db libraryViewSource] selectionForBrowser:2];
    NSIndexSet *indexSet3 = [[db libraryViewSource] selectionForBrowser:3];
    
    if (tableView == libraryTableView && 
        op == NSTableViewDropAbove && 
        currentPlaylist != 0 && 
        [indexes count] != 0 && 
        [indexSet1 firstIndex] == 0 &&
        [indexSet2 firstIndex] == 0 &&
        [indexSet3 firstIndex] == 0) {
		return NSDragOperationEvery;
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView 
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row 
	dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard = [info draggingPasteboard];    
    if ([info draggingSource] != libraryTableView) {
        return FALSE;
	}
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:PRIndexesPboardType]];
    
    // get move row
    PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:[indexes firstIndex] inPlaylist:currentPlaylist];
                   
    int row2 = [self dbRowForTableRow:row];
    [[db playlists] moveItemsAtIndexes:indexes toIndex:row2 inPlaylist:currentPlaylist];
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:currentPlaylist];
    
    // select
    int index = [[db playlists] indexForPlaylistItem:playlistItem];
    NSIndexSet *indexesToSelect = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self tableRowForDbRow:index], [indexes count])];
    [libraryTableView selectRowIndexes:indexesToSelect byExtendingSelection:FALSE];
    return TRUE;
}

// ========================================
// TableView Delegate
// ========================================

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
    [cell setHighlighted:[[tableView selectedRowIndexes] containsIndex:row]];
}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn
{
    if (tableView == libraryTableView && [[tableColumn identifier] intValue] == PRPlaylistIndexSort) {
        [tableView setAllowsColumnReordering:NO];
    } else {
        [tableView setAllowsColumnReordering:YES];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex
{
    if (tableView == libraryTableView && currentPlaylist > 0 && newColumnIndex == 0) {
        return FALSE;
    } else {
        return TRUE;
    }
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if (tableView != libraryTableView) {
		return;
	}
    if ([[tableColumn identifier] intValue] == [self sortColumn]) {
		[self setAscending:![self ascending]];
	} else {
        [self setSortColumn:[[tableColumn identifier] intValue]];
        [self setAscending:TRUE];
    }
	[self loadTableColumns];
    [self reloadData:FALSE];
    [tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	id object = [notification object];
	if (object == libraryTableView) {
        [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
	} else if (currentPlaylist != -1 && (object == browser1TableView || object == browser2TableView || object == browser3TableView)) {
        if (!monitorSelection) {
            return;
        }
        BOOL browser = [self browserForTableView:object];
		NSMutableArray *selection = [NSMutableArray array];
        [[object selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            if (idx == 0) {
            } else {
                [selection addObject:[self tableView:object objectValueForTableColumn:nil row:idx]];
            }
        }];
        [[db playlists] setSelection:selection forBrowser:browser playlist:currentPlaylist];
		
		// update tableviews
		[libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        [self reloadData:FALSE];
        [libraryTableView scrollPoint:NSMakePoint(0, 0)];
        [browser1TableView scrollRowToVisible:[browser1TableView selectedRow]];
        [browser2TableView scrollRowToVisible:[browser2TableView selectedRow]];
        [browser3TableView scrollRowToVisible:[browser3TableView selectedRow]];
	}
}

- (NSIndexSet *)             tableView:(NSTableView *)tableView
  selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	NSIndexSet *selectionIndexes = proposedSelectionIndexes;
	if (tableView == browser1TableView || tableView == browser2TableView || tableView == browser3TableView) {
		if ([selectionIndexes containsIndex:0]) {
			selectionIndexes = [NSIndexSet indexSetWithIndex:0];
		}
	}
	return selectionIndexes;
}

- (void)tableViewColumnDidMove:(NSNotification *)notification
{
	if (!refreshing) {
		[self saveTableColumns];
	}
}

- (void)tableViewColumnDidResize:(NSNotification *)notification
{
	if (!refreshing && [notification object] == libraryTableView) {
		[self saveTableColumns];
	}
}

// ========================================
// Split View Delegate
// ========================================

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
    if (splitView == horizontalBrowserSplitView) {
        return subview != horizontalBrowserSubSplitview;
    } else if (splitView == verticalBrowserSplitView) {
        return subview == verticalBrowserLibrarySuperview;
    }
    return TRUE;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	return TRUE;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    if (refreshing) {return;}
    if ([notification object] == horizontalBrowserSplitView) {
        if ([horizontalBrowserSubSplitview frame].size.height < 120) {
            NSRect frame = [horizontalBrowserSubSplitview frame];
            frame.size.height = 120;
            [horizontalBrowserSubSplitview setFrame:frame];
        } else if ([horizontalBrowserLibrarySuperview frame].size.height < 120) {
            NSRect frame = [horizontalBrowserSubSplitview frame];
            frame.size.height = [horizontalBrowserSplitView frame].size.height - 120 - [horizontalBrowserSplitView dividerThickness];
            [horizontalBrowserSubSplitview setFrame:frame];
        }
    }
    [self saveBrowser];
}

- (CGFloat)    splitView:(NSSplitView *)splitView 
  constrainSplitPosition:(CGFloat)proposedPosition 
		     ofSubviewAt:(NSInteger)dividerIndex
{	
	if (splitView == verticalBrowserSplitView) {
		if (proposedPosition > 400) {
			return 400;
		} else if (proposedPosition < 120) {
			return 120;
		}
	} else if (splitView == horizontalBrowserSubSplitview) {
        if ([[horizontalBrowserSubSplitview subviews] count] == 3) {
            float width = ([horizontalBrowserSubSplitview frame].size.width - 2) / 3;
            if (dividerIndex == 0) {
                return width;
            } else if (dividerIndex == 1) {
                return width * 2 + 1;
            }
        } else if ([[horizontalBrowserSubSplitview subviews] count] == 2)  {
            float width = [horizontalBrowserSubSplitview frame].size.width / 2;
            return width;
        } else {
            return [horizontalBrowserSubSplitview frame].size.width;
        }
    } else if (splitView == horizontalBrowserSplitView) {
        if (proposedPosition < 120) {
            return 120;
        } else if (proposedPosition > [horizontalBrowserSplitView frame].size.height - 120) {
            return [horizontalBrowserSplitView frame].size.height - 120;
        }
    }
	
	return proposedPosition;
}

- (NSRect)splitView:(NSSplitView *)splitView 
      effectiveRect:(NSRect)proposedEffectiveRect 
       forDrawnRect:(NSRect)drawnRect 
   ofDividerAtIndex:(NSInteger)dividerIndex
{
    if (splitView == horizontalBrowserSubSplitview) {
        return NSZeroRect;
    }
    
    return proposedEffectiveRect;
}

// ========================================
// Menu Delegate
// ========================================

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu == libraryMenu) {
		[self updateLibraryMenu];
	} else if (menu == headerMenu) {
		[self updateHeaderMenu];
	} else if (menu == browserHeaderMenu) {
		[self updateBrowserHeaderMenu];
	}
}

- (void)updateLibraryMenu
{
	NSInteger clickedRow = [libraryTableView clickedRow];
	// save selected rows to be used by context menu actions
    [selectedRows release];
	if (clickedRow == -1) {
		selectedRows = [[NSIndexSet indexSet] retain];
	} else if ([libraryTableView isRowSelected:clickedRow]) {
		selectedRows = [[libraryTableView selectedRowIndexes] retain];
	} else {
		selectedRows = [[NSIndexSet indexSetWithIndex:clickedRow] retain];
	}
	// clear menu
	for (NSMenuItem *i in [libraryMenu itemArray]) {
		[libraryMenu removeItem:i];
	}
	// populate context menu if clicked on row
	if (clickedRow != -1) {
		// Play
		[libraryMenu addItemWithTitle:@"Play" action:@selector(playSelected) keyEquivalent:@""];
		[libraryMenu addItemWithTitle:@"Append" action:@selector(append) keyEquivalent:@""];
        [libraryMenu addItem:[NSMenuItem separatorItem]];
        
		// Add to Playlist
        NSMenu *playlistMenu = [[[NSMenu alloc] init] autorelease];
		NSMenuItem *playlistMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Add to Playlist" action:nil keyEquivalent:@""] autorelease];
		[libraryMenu addItem:playlistMenuItem];
		[playlistMenuItem setSubmenu:playlistMenu];
        
        NSArray *playlistArray = [[db playlists] playlists];
		for (NSNumber *i in playlistArray) {
            int playlistType = [[db playlists] typeForPlaylist:[i intValue]];
            if (playlistType != PRStaticPlaylistType) {
                continue;
            }
            NSString *playlistTitle = [NSString stringWithFormat:@" %@",[[db playlists] titleForPlaylist:[i intValue]]];
			NSMenuItem *tempMenuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(addToPlaylist:) keyEquivalent:@""] autorelease];
            [tempMenuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
			[tempMenuItem setRepresentedObject:i];
			[tempMenuItem setTarget:self];
			[playlistMenu addItem:tempMenuItem];
        }
        [libraryMenu addItem:[NSMenuItem separatorItem]];
		
		// Misc
        if ([libraryViewController infoViewVisible]) {
            [libraryMenu addItemWithTitle:@"Hide Info Pane" action:@selector(getInfo) keyEquivalent:@""];
        } else {
            [libraryMenu addItemWithTitle:@"Show Info Pane" action:@selector(getInfo) keyEquivalent:@""];
        }
        [libraryMenu addItemWithTitle:@"Reveal in Finder" action:@selector(reveal) keyEquivalent:@""];        
        [libraryMenu addItem:[NSMenuItem separatorItem]];
        
        // Delete
        if ([[db playlists] libraryPlaylist]) {
            [libraryMenu addItemWithTitle:@"Delete" action:@selector(delete) keyEquivalent:@""];
        } else {
            [libraryMenu addItemWithTitle:@"Remove" action:@selector(delete) keyEquivalent:@""];
        }
	}
	// set target for menu items.
	for (NSMenuItem *i in [libraryMenu itemArray]) {
		[i setTarget:self];
	}
}

- (void)updateHeaderMenu
{
	for (NSMenuItem *i in [headerMenu itemArray]) {
		[headerMenu removeItem:i];
	}
	
    NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
	[menuItem setTitle:@"Browser"];
    [menuItem setSubmenu:[self browserHeaderMenu]];
	[headerMenu addItem:menuItem];
    
    [headerMenu addItem:[NSMenuItem separatorItem]];
	
	// Columns	
	NSSortDescriptor *sortDescriptor = 
    [[[NSSortDescriptor alloc] initWithKey:@"headerCell.stringValue" ascending:TRUE] autorelease];
	NSArray *sortedTableColumns = 
    [[libraryTableView tableColumns] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	for (NSTableColumn *i in sortedTableColumns) {
        if ([[i identifier] intValue] == PRPlaylistIndexSort) {
            continue;
        }
        
		menuItem = [[[NSMenuItem alloc] init] autorelease];
		[menuItem setTitle:[[i headerCell] stringValue]];
		[menuItem setAction:@selector(toggleColumn:)];
		if (![i isHidden]) {
			[menuItem setState:NSOnState];
		}
		[menuItem setRepresentedObject:i];
		[headerMenu addItem:menuItem];
	}
	
	for (NSMenuItem *i in [headerMenu itemArray]) {
		[i setTarget:self];
	}
}

- (NSMenu *)browserHeaderMenu
{
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];
    
    // Browser position
    int browserPosition = [[db playlists] isVerticalForPlaylist:currentPlaylist];
    
    NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"Hidden"];
    [item setRepresentedObject:[NSNumber numberWithInt:-3]];
    if (browserPosition == PRBrowserPositionHidden) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"On Top"];
    [item setRepresentedObject:[NSNumber numberWithInt:-1]];
    if (browserPosition == PRBrowserPositionHorizontal) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"On Left"];
    [item setRepresentedObject:[NSNumber numberWithInt:-2]];
    if (browserPosition == PRBrowserPositionVertical) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    if (browserPosition != PRBrowserPositionHidden) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        // Get browser groupings
        int browser1Grouping = [[db playlists] browser1AttributeForPlaylist:currentPlaylist];
        int browser2Grouping = [[db playlists] browser2AttributeForPlaylist:currentPlaylist];
        int browser3Grouping = [[db playlists] browser3AttributeForPlaylist:currentPlaylist];
        
        // Genre
        item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:@"Genre"];
        [item setRepresentedObject:[NSNumber numberWithInt:-2]];
        [item setRepresentedObject:[NSNumber numberWithInt:13]];
        if (browser1Grouping == 13 || browser2Grouping == 13 || browser3Grouping == 13) {
            [item setState:NSOnState];
        }
        [menu addItem:item];
        
        // Composer
        item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:@"Composer"];
        [item setRepresentedObject:[NSNumber numberWithInt:8]];
        if (browser1Grouping == 8 || browser2Grouping == 8 || browser3Grouping == 8) {
            [item setState:NSOnState];
        }
        [menu addItem:item];
        
        // Artist
        item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:@"Artist"];
        [item setRepresentedObject:[NSNumber numberWithInt:2]];	
        if (browser1Grouping == 2 || browser2Grouping == 2 || browser3Grouping == 2) {
            [item setState:NSOnState];
        }
        [menu addItem:item];
        
        // Album
        item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:@"Album"];
        [item setRepresentedObject:[NSNumber numberWithInt:3]];	
        if (browser1Grouping == 3 || browser2Grouping == 3 || browser3Grouping == 3) {
            [item setState:NSOnState];
        }
        [menu addItem:item];
    }
	
	for (NSMenuItem *i in [menu itemArray]) {
		[i setTarget:self];
		[i setAction:@selector(toggleBrowser:)];
	}
    
    return menu;
}

- (void)updateBrowserHeaderMenu
{
	// Clear menu
    [browserHeaderMenu removeAllItems];
	
    NSMenu *menu = [self browserHeaderMenu];
    NSArray *items = [menu itemArray];
    [menu removeAllItems];
    for (NSMenuItem *i in items) {
        [browserHeaderMenu addItem:i];
    }
}

@end