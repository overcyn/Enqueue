#import "PRTableViewController.h"
#import "PRTableViewController+Private.h"
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
#import "NSString+Extensions.h"
#import "sqlite_str.h"
#import "PRTagger.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "MAZeroingWeakRef.h"
#import "NSMenuItem+Extensions.h"
#import "PRMainWindowController.h"
#import "PRNowPlayingViewController.h"
#import "NSTableView+Extensions.h"


@implementation PRTableViewController

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    return self;
}

- (void)dealloc {
    [libraryMenu release];
    [headerMenu release];
    [browserHeaderMenu release];
    [db release];
    [now release];   
    [super dealloc];
}

- (void)awakeFromNib {
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
    PRStringFormatter *stringFormatter = [[PRStringFormatter alloc] init];
    PRNumberFormatter *numberFormatter = [[PRNumberFormatter alloc] init];
    PRSizeFormatter *sizeFormatter = [[PRSizeFormatter alloc] init];
    PRTimeFormatter *timeFormatter = [[PRTimeFormatter alloc] init];
    PRBitRateFormatter *bitRateFormatter = [[PRBitRateFormatter alloc] init];
    PRKindFormatter *kindFormatter = [[PRKindFormatter alloc] init];
    PRDateFormatter *dateFormatter = [[PRDateFormatter alloc] init];
    
    // Playlist Index
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRListSortIndex] autorelease];
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
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrPath] autorelease];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[[PRTableHeaderCell alloc] init] autorelease]];
	[[tableColumn headerCell] setStringValue:@"Path"];
	[tableColumn setDataCell:[[[PRCenteredTextFieldCell alloc] init] autorelease]];
	[tableColumn setEditable:FALSE];
	[tableColumns addObject:tableColumn];
	
	// Title
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrTitle] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrArtist] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrAlbum] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrAlbumArtist] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrComposer] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrGenre] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrYear] autorelease];
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
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrComments] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrBPM] autorelease];
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
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrTrackNumber] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrDiscNumber] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrPlayCount] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrDateAdded] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrLastPlayed] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrSize] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrKind] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrTime] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrBitrate] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrChannels] autorelease];
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
	tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrSampleRate] autorelease];
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
    tableColumn = [[[NSTableColumn alloc] initWithIdentifier:PRItemAttrRating] autorelease];
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
	
    // Key Views
    [[self firstKeyView] setNextKeyView:horizontalBrowser1TableView];
    [horizontalBrowser1TableView setNextKeyView:horizontalBrowser2TableView];
    [horizontalBrowser2TableView setNextKeyView:horizontalBrowser3TableView];
    [horizontalBrowser3TableView setNextKeyView:verticalBrowser1TableView];
    [verticalBrowser1TableView setNextKeyView:libraryTableView];
    [libraryTableView setNextKeyView:[self lastKeyView]];
    
	// Update
    [[NSNotificationCenter defaultCenter] observeLibraryChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(tagsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeUseAlbumArtistChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistFilesChanged:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(playingFileChanged:)];
    
    [pool drain];
}

// ========================================
// Accessors

@dynamic currentList, info, selection, selectedIndexes;

- (PRList *)list {
    return _currentList;
}

- (void)setCurrentList:(PRList *)list {
    [list retain];
    [_currentList release];
    _currentList = list;
    
	if (list) {        
		[self loadTableColumns];
        [self loadBrowser];
        [self reloadData:TRUE];
        [libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        [libraryTableView scrollRowToVisiblePretty:0];
        [browser1TableView scrollRowToVisiblePretty:[browser1TableView selectedRow]];
        [browser2TableView scrollRowToVisiblePretty:[browser2TableView selectedRow]];
        [browser3TableView scrollRowToVisiblePretty:[browser3TableView selectedRow]];
	}
}

- (NSDictionary *)info {
	return [[db libraryViewSource] info];
}

- (NSArray *)selection {
	NSMutableArray *selectionArray = [NSMutableArray array];
    [[self dbRowIndexesForTableRowIndexes:[libraryTableView selectedRowIndexes]] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [selectionArray addObject:[[db libraryViewSource] itemForRow:idx]];
    }];
	return selectionArray;
}

// ========================================
// accessors

- (NSIndexSet *)selectedIndexes {
    return [libraryTableView selectedRowIndexes];
}

// ========================================
// Action

- (void)highlightFile:(PRFile)file {
    PRItem *item = [PRItem numberWithInt:file];
    NSString *artist;
    if ([[PRUserDefaults userDefaults] useCompilation] && [[[db library] valueForItem:item attr:PRItemAttrCompilation] boolValue]) {
        artist = compilationString;
    } else {
        artist = [[db library] artistValueForItem:item];
    }
    [self browseToArtist:artist];
    
	int dbRow = [[db libraryViewSource] rowForItem:[NSNumber numberWithInt:file]];
	if (dbRow != -1) {
		int tableRow = [self tableRowForDbRow:dbRow];
		[libraryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tableRow] byExtendingSelection:FALSE];
		[libraryTableView scrollRowToVisiblePretty:tableRow];
	}
}

- (void)highlightFiles:(NSArray *)items {
    if ([items count] == 0) {
        return;
    }
    NSMutableIndexSet *dbRows = [NSMutableIndexSet indexSet];
    for (NSNumber *i in items) {
        int dbRow = [[db libraryViewSource] rowForItem:i];
        if (dbRow == -1) {
            [dbRows removeAllIndexes];
            break;
        }
        [dbRows addIndex:dbRow];
    }
    if ([dbRows count] == 0) {
        [[db playlists] setSearch:@"" forList:_currentList];
        [[db playlists] setSelection:[NSArray array] forBrowser:1 list:_currentList];
        [[db playlists] setSelection:[NSArray array] forBrowser:2 list:_currentList];
        [[db playlists] setSelection:[NSArray array] forBrowser:3 list:_currentList];
        [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
        
        for (NSNumber *i in items) {
            int dbRow = [[db libraryViewSource] rowForItem:i];
            if (dbRow == -1) {
                [dbRows removeAllIndexes];
                break;
            }
            [dbRows addIndex:dbRow];
        }
    }
    if ([dbRows count] > 0) {
        NSIndexSet *tableRows = [self tableRowIndexesForDbRowIndexes:dbRows];
        [libraryTableView selectRowIndexes:tableRows byExtendingSelection:FALSE];
        [libraryTableView scrollRowToVisiblePretty:[tableRows firstIndex]];
    }
}

- (void)highlightArtist:(NSString *)artist {
    [self browseToArtist:artist];
    PRItemAttr *attr;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        attr = PRItemAttrArtistAlbumArtist;
    } else {
        attr = PRItemAttrArtist;
    }
    int row = [self tableRowForDbRow:[[db libraryViewSource] firstRowWithValue:artist forAttr:attr]]; 
    if (row == -1 || row == 0) {
        return;
    }
    [libraryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
    [libraryTableView scrollRowToVisiblePretty:row];
}

- (void)browseToArtist:(NSString *)artist {
    [[db playlists] setSearch:@"" forList:_currentList];
    for (int i = 1; i <= 3; i++) {
        NSArray *selection = [NSArray array];
        if ([[[db playlists] attrForBrowser:i list:_currentList] isEqual:PRItemAttrArtist]) {
            selection = [NSArray arrayWithObject:artist];
        }
        [[db playlists] setSelection:selection forBrowser:i list:_currentList];
    }
    [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
    [browser1TableView scrollRowToVisiblePretty:[browser1TableView selectedRow]];
    [browser2TableView scrollRowToVisiblePretty:[browser2TableView selectedRow]];
    [browser3TableView scrollRowToVisiblePretty:[browser3TableView selectedRow]];
}

// ========================================
// action

- (void)playIndexes:(NSIndexSet *)indexes {
    [now stop];
    [[db playlists] clearList:[now currentList]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        PRItem *item = [[db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]];
        [[db playlists] appendItem:item toList:[now currentList]];
    }];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    if ([[db playlists] countForList:[now currentList]] > 0) {
        [now playItemAtIndex:1];
    }
}

- (void)appendIndexes:(NSIndexSet *)indexes {
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[[db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];    
    }];
    [[[_core win] nowPlayingViewController] addItems:items atIndex:[[db playlists] countForList:[now currentList]]+1];
}

- (void)appendNextIndexes:(NSIndexSet *)indexes {
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[[db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];
    }];
    [[[_core win] nowPlayingViewController] addItems:items atIndex:[now currentIndex]+1];
}

- (void)deleteIndexes:(NSIndexSet *)indexes {
    if ([indexes count] == 0) {
        return;
    }
    if (![_currentList isEqual:[[db playlists] libraryList]]) {
        NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
        NSTableColumn *tableColumn = [libraryTableView tableColumnWithIdentifier:PRListSortIndex];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [indexesToDelete addIndex:[[self tableView:libraryTableView objectValueForTableColumn:tableColumn row:idx] intValue]];
        }];
        [[db playlists] removeItemsAtIndexes:indexesToDelete fromList:_currentList];
        
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:_currentList];
        [libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
    } else {
        NSString *message = @"Do you want to remove the selected song from your library?";
        if ([indexes count] != 1) {
            message = [NSString stringWithFormat:@"Do you want to remove the %d selected songs from your library?", [indexes count]];
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
                            contextInfo:[indexes retain]];
    }
}

- (void)appendIndexes:(NSIndexSet *)indexes toList:(PRList *)list {
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        PRItem *item = [[db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]];
        [[db playlists] appendItem:item toList:list];
    }];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

- (void)revealIndexes:(NSIndexSet *)indexes {
    int row = [indexes indexGreaterThanOrEqualToIndex:0];
    PRItem *item = [[db libraryViewSource] itemForRow:[self dbRowForTableRow:row]];
	[[NSWorkspace sharedWorkspace] selectFile:[[[db library] URLForItem:item] path] inFileViewerRootedAtPath:nil];
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode != NSAlertFirstButtonReturn) {
        return;
    }
    NSIndexSet *indexes = [(NSIndexSet *)contextInfo autorelease];
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[[db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];
    }];
    if ([items containsObject:[now currentItem]]) {
        [now stop];
    }
    [[db library] removeItems:items];
    [[NSNotificationCenter defaultCenter] postLibraryChanged];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    [libraryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:FALSE];    
}

- (void)appendAll {
    [self appendIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:libraryTableView])]];
}

- (void)appendNextAll {
    [self appendNextIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:libraryTableView])]];
}

// ========================================
// action mouse

- (void)play {
	if ([self dbRowForTableRow:[libraryTableView clickedRow]] < 1) {
        return;
	}
    if ([[libraryTableView selectedRowIndexes] count] > 1) {
        [self playIndexes:[libraryTableView selectedRowIndexes]];
    } else {
        [now stop];
        [[db playlists] clearList:[now currentList]];
        [[db playlists] appendItemsFromLibraryViewSourceToList:[now currentList]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
        [now playItemAtIndex:[self dbRowForTableRow:[libraryTableView clickedRow]]];
    }
}

- (void)playBrowser:(id)sender {
    if ([sender clickedRow] == -1) {
        return;
	}
    [now stop];
    [[db playlists] clearList:[now currentList]];
    [[db playlists] appendItemsFromLibraryViewSourceToList:[now currentList]];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    if ([[db playlists] countForList:[now currentList]] > 0) {
        [now playItemAtIndex:1];
    }
}

// ========================================
// setup

- (void)reloadData:(BOOL)force {
    int tables = [[db libraryViewSource] refreshWithList:_currentList force:force];
	
    _updatingTableViewSelection = FALSE;
    if ((tables & PRLibraryView) == PRLibraryView) {
        [libraryTableView reloadData];
    }
    if ((tables & PRBrowser1View) == PRBrowser1View) {
        [browser1TableView reloadData];
    }
    if ((tables & PRBrowser2View) == PRBrowser2View) {    
        [browser2TableView reloadData];
    }
    if ((tables & PRBrowser3View) == PRBrowser3View) {
        [browser3TableView reloadData];
    }
    [browser1TableView selectRowIndexes:[[db libraryViewSource] selectionForBrowser:1] byExtendingSelection:FALSE];
    [browser2TableView selectRowIndexes:[[db libraryViewSource] selectionForBrowser:2] byExtendingSelection:FALSE];
    [browser3TableView selectRowIndexes:[[db libraryViewSource] selectionForBrowser:3] byExtendingSelection:FALSE];
    _updatingTableViewSelection = TRUE;
	
    [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
}

// ========================================
// update

- (void)playingFileChanged:(NSNotification *)note {
    NSIndexSet *rows = [NSIndexSet indexSetWithIndexesInRange:[libraryTableView rowsInRect:[libraryTableView visibleRect]]];
    NSIndexSet *columns = [NSIndexSet indexSetWithIndex:[libraryTableView columnWithIdentifier:PRItemAttrTrackNumber]];
    [libraryTableView reloadDataForRowIndexes:rows columnIndexes:columns];
}

- (void)libraryDidChange:(NSNotification *)note {
    if (_currentList) {
        [self reloadData:TRUE];
    }
}

- (void)tagsDidChange:(NSNotification *)note {
    if (_currentList) {
		[self reloadData:TRUE];
	}
}

- (void)playlistDidChange:(NSNotification *)note {
	if (!_currentList || ![[[note userInfo] valueForKey:@"playlist"] isEqual:_currentList]) {
        return;
	}
    [self reloadData:FALSE];
    [libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
    [libraryTableView scrollRowToVisible:[libraryTableView selectedRow]];
    [browser1TableView scrollRowToVisible:[browser1TableView selectedRow]];
    [browser2TableView scrollRowToVisible:[browser2TableView selectedRow]];
    [browser3TableView scrollRowToVisible:[browser3TableView selectedRow]];
}

- (void)playlistFilesChanged:(NSNotification *)note {
    if (_currentList && [[[note userInfo] valueForKey:@"playlist"] isEqual:_currentList]) {
        [self reloadData:TRUE];
	}
}

// ========================================
// ui

@dynamic ascending, sortAttr, columnInfo;

- (BOOL)ascending {
    return [[db playlists] listViewAscendingForList:_currentList];
}

- (void)setAscending:(BOOL)ascending {
    [[db playlists] setListViewAscending:ascending forList:_currentList];
}

- (PRItemAttr *)sortAttr {
    return [[db playlists] listViewSortAttrForList:_currentList];
}

- (void)setSortAttr:(PRItemAttr *)attr {
    [[db playlists] setListViewSortAttr:attr forList:_currentList];
}

- (NSArray *)columnInfo {
    return [[db playlists] listViewInfoForList:_currentList];
}

- (void)setColumnInfo:(NSArray *)info {
    [[db playlists] setListViewInfo:info forList:_currentList];
}

- (void)toggleColumn:(NSTableColumn *)column {
	[column setHidden:![column isHidden]];
	[self saveTableColumns];
}

- (void)toggleBrowser:(PRItemAttr *)attr {
    if ([[db playlists] verticalForList:_currentList]) {
        [[db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[db playlists] setAttr:attr forBrowser:3 list:_currentList];
    } else {
        NSMutableSet *set = [NSMutableSet set];
        for (int i = 1; i < 4; i++) {
            if ([[db playlists] attrForBrowser:i list:_currentList]) {
                [set addObject:[[db playlists] attrForBrowser:i list:_currentList]];
            }
        }
        
        if ([set containsObject:attr]) { // if removing browser
            [set removeObject:attr];
            if ([set count] == 0) {
                [set addObject:PRItemAttrArtist];
            }
        } else { // if adding browser
            [set addObject:attr];
            if ([set count] > 3) {
                if ([attr isEqual:PRItemAttrComposer]) {
                    [set removeObject:PRItemAttrGenre];
                } else {
                    [set removeObject:PRItemAttrComposer];
                }
            }
        }
        
        NSMutableArray *attrs = [NSMutableArray array];
        for (PRItemAttr *i in [NSArray arrayWithObjects:PRItemAttrAlbum, PRItemAttrArtist, PRItemAttrComposer, PRItemAttrGenre, nil]) {
            if ([set containsObject:i]) {
                [attrs addObject:i];
            }
        }
        [attrs addObject:[NSNull null]];
        [attrs addObject:[NSNull null]];
        [attrs addObject:[NSNull null]];
        
        // save
        for (int i = 0; i < 3; i++) {
            if ([attrs objectAtIndex:i] == [NSNull null]) {
                [[db playlists] setAttr:nil forBrowser:3-i list:_currentList];
            } else {
                [[db playlists] setAttr:[attrs objectAtIndex:i] forBrowser:3-i list:_currentList];
            }
        }
        [[db playlists] setSelection:[NSArray array] forBrowser:1 list:_currentList];
        [[db playlists] setSelection:[NSArray array] forBrowser:2 list:_currentList];
        [[db playlists] setSelection:[NSArray array] forBrowser:3 list:_currentList];
    }
	[self loadBrowser];
    [self reloadData:FALSE];
}

- (void)setBrowserPosition:(PRBrowserPosition)position {
    if (position == PRBrowserPositionHorizontal) {
        [[db playlists] setVertical:PRBrowserPositionHorizontal forList:_currentList];
        [[db playlists] setAttr:PRItemAttrGenre forBrowser:1 list:_currentList];
        [[db playlists] setAttr:PRItemAttrArtist forBrowser:2 list:_currentList];
        [[db playlists] setAttr:PRItemAttrAlbum forBrowser:3 list:_currentList];
    } else if (position == PRBrowserPositionVertical) {
        [[db playlists] setVertical:PRBrowserPositionVertical forList:_currentList];
        [[db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[db playlists] setAttr:PRItemAttrArtist forBrowser:3 list:_currentList];
    } else if (position == PRBrowserPositionHidden) {
        [[db playlists] setVertical:PRBrowserPositionHidden forList:_currentList];
        [[db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[db playlists] setAttr:nil forBrowser:3 list:_currentList];
    }
    [self loadBrowser];
    [self reloadData:TRUE];
}

- (void)loadBrowser {
    refreshing = TRUE;
    [verticalBrowserSplitView removeFromSuperview];
    [horizontalBrowserSplitView removeFromSuperview];
    [libraryScrollView removeFromSuperview];
    int browserPosition = [[db playlists] verticalForList:_currentList];
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
        [verticalBrowserSplitView setPosition:[[db playlists] verticalBrowserWidthForList:_currentList] ofDividerAtIndex:0];
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
        if (![[db playlists] attrForBrowser:2 list:_currentList]) {
            [horizontalBrowserSubSplitview addSubview:[[horizontalBrowser3TableView superview] superview]];
        } else if (![[db playlists] attrForBrowser:1 list:_currentList]) {
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
        [horizontalBrowserSplitView setPosition:[[db playlists] horizontalBrowserHeightForList:_currentList] ofDividerAtIndex:0];
    } else if (browserPosition == PRBrowserPositionHidden){
        [[self view] addSubview:libraryScrollView];
        NSRect bounds = [[self view] bounds];
        bounds.size.height += 1;
        [libraryScrollView setFrame:bounds];
        browser1TableView = nil;
        browser2TableView = nil;
        browser3TableView = nil;
    }
    for (int i = 1; i < 4; i++) {
        PRItemAttr *attr = [[db playlists] attrForBrowser:i list:_currentList];
        NSString *title = @"";
        if (attr) {
            title = [PRLibrary titleForItemAttr:attr];
        }
        [[[[[self tableViewForBrowser:i] tableColumns] objectAtIndex:0] headerCell] setStringValue:title];
    }
    refreshing = FALSE;
}

- (void)saveBrowser {
    if (!_currentList) {
        return;
    }
    int browserPosition = [[db playlists] verticalForList:_currentList];
    if (browserPosition == PRBrowserPositionVertical) {
        float width = [[[browser3TableView superview] superview] bounds].size.width;
        [[db playlists] setVerticalBrowserWidth:width forList:_currentList];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        float height = [horizontalBrowserSubSplitview frame].size.height;
        [[db playlists] setHorizontalBrowserHeight:height forList:_currentList];
    }
}

- (void)loadTableColumns {
    refreshing = TRUE;
	// set column attributes
    NSArray *columnsInfo = [self columnInfo];
	for (int i = 0; i < [columnsInfo count]; i++) {
        NSDictionary *columnInfo = [columnsInfo objectAtIndex:i];
        NSTableColumn *tableColumn = [libraryTableView tableColumnWithIdentifier:[PRPlaylists sortAttrForInternal:[columnInfo valueForKey:@"identifier"]]];
        [tableColumn setWidth:[[columnInfo valueForKey:@"width"] intValue]];
        [tableColumn setHidden:[[columnInfo valueForKey:@"hidden"] boolValue]];
        [libraryTableView moveColumn:[[libraryTableView tableColumns] indexOfObject:tableColumn] toColumn:i];
    }
    
    // playlist column
    NSTableColumn *tableColumn = [libraryTableView tableColumnWithIdentifier:PRListSortIndex];
    [libraryTableView moveColumn:[[libraryTableView tableColumns] indexOfObject:tableColumn] toColumn:0];
    [[[libraryTableView tableColumns] objectAtIndex:0] setHidden:([_currentList isEqual:[[db playlists] libraryList]])];
	
	// highlight sort table column
    [self highlightTableColumn:[self tableColumnForAttr:[self sortAttr]] ascending:[self ascending]];
    refreshing = FALSE;
}

- (void)saveTableColumns {	
	NSArray *columns = [libraryTableView tableColumns];
	NSMutableArray *columnsInfo = [NSMutableArray array];
	for (NSTableColumn *i in columns) {
        if ([[i identifier] intValue] == PRPlaylistIndexSort) {
            continue;
        }
		[columnsInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                [PRPlaylists internalForSortAttr:[i identifier]], @"identifier",
                                [NSNumber numberWithBool:[i isHidden]], @"hidden",
                                [NSNumber numberWithFloat:[i width]], @"width", nil]];
	}
    [self setColumnInfo:columnsInfo];
}

// ========================================
// ui misc

- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending {
    for (NSTableColumn *i in [libraryTableView tableColumns]) {
        if (i != tableColumn) {
            [[i tableView] setIndicatorImage:nil inTableColumn:i];	
        }
	}
    NSImage *indicatorImage;
    if (ascending) {
        indicatorImage = [NSImage imageNamed:@"NSAscendingSortIndicator"];
    } else {
        indicatorImage = [NSImage imageNamed:@"NSDescendingSortIndicator"];
    }
    [[tableColumn tableView] setIndicatorImage:indicatorImage inTableColumn:tableColumn];	
	[[tableColumn tableView] setHighlightedTableColumn:tableColumn];
}

- (NSTableColumn *)tableColumnForAttr:(PRItemAttr *)attr {
    return [libraryTableView tableColumnWithIdentifier:attr];
}

// ========================================
// Menu

- (NSMenu *)browserHeaderMenu {
    int browserPosition = [[db playlists] verticalForList:_currentList];
    MAZeroingWeakRef *selfRef = [MAZeroingWeakRef refWithTarget:self];
    
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"Hidden"];
    [item setActionBlock:^{[[selfRef target] setBrowserPosition:PRBrowserPositionHidden];}];
    if (browserPosition == PRBrowserPositionHidden) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"On Top"];
    [item setActionBlock:^{[[selfRef target] setBrowserPosition:PRBrowserPositionHorizontal];}];
    if (browserPosition == PRBrowserPositionHorizontal) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"On Left"];
    [item setActionBlock:^{[[selfRef target] setBrowserPosition:PRBrowserPositionVertical];}];
    if (browserPosition == PRBrowserPositionVertical) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    if (browserPosition != PRBrowserPositionHidden) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        PRItemAttr *attr1 = [[db playlists] attrForBrowser:1 list:_currentList];
        PRItemAttr *attr2 = [[db playlists] attrForBrowser:2 list:_currentList];
        PRItemAttr *attr3 = [[db playlists] attrForBrowser:3 list:_currentList];
        for (PRItemAttr *i in [NSArray arrayWithObjects:PRItemAttrGenre, PRItemAttrComposer, PRItemAttrArtist, PRItemAttrAlbum, nil]) {
            item = [[[NSMenuItem alloc] init] autorelease];
            [item setTitle:[PRLibrary titleForItemAttr:i]];
            [item setActionBlock:^{[[selfRef target] toggleBrowser:i];}];
            if ([attr1 isEqual:i] || [attr2 isEqual:i] || [attr3 isEqual:i]) {
                [item setState:NSOnState];
            }
            [menu addItem:item];
        }
    }
    return menu;
}

// ========================================
// menu

- (void)updateLibraryMenu {
    if ([libraryTableView clickedRow] == -1) {
        return;
    }
    for (NSMenuItem *i in [libraryMenu itemArray]) {
		[libraryMenu removeItem:i];
	}
    MAZeroingWeakRef *selfRef = [MAZeroingWeakRef refWithTarget:self];
    unichar c[1] = {NSCarriageReturnCharacter};
    
    // Play
    NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"Play"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:0];
    [item setActionBlock:^{[[selfRef target] playIndexes:[[selfRef target] selectedIndexes]];}];
    [libraryMenu addItem:item];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"Play Next"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [item setActionBlock:^{[[selfRef target] appendNextIndexes:[[selfRef target] selectedIndexes]];}];
    [libraryMenu addItem:item];
    
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"Append"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:NSShiftKeyMask];
    [item setActionBlock:^{[[selfRef target] appendIndexes:[[selfRef target] selectedIndexes]];}];
    [libraryMenu addItem:item];    
    [libraryMenu addItem:[NSMenuItem separatorItem]];
    
    // Add to Playlist
    NSMenu *playlistMenu = [[[NSMenu alloc] init] autorelease];
    for (PRList *i in [[db playlists] lists]) {
        if (![[[db playlists] typeForList:i] isEqual:PRListTypeStatic]) {
            continue;
        }
        item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:[NSString stringWithFormat:@" %@",[[db playlists] titleForList:i]]];
        [item setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        [item setActionBlock:^{[[selfRef target] appendIndexes:[[selfRef target] selectedIndexes] toList:i];}];
        [playlistMenu addItem:item];
    }
    NSMenuItem *playlistMenuItem = [[[NSMenuItem alloc] init] autorelease];
    [playlistMenuItem setTitle:@"Add to Playlist"];
    [playlistMenuItem setSubmenu:playlistMenu];
    [libraryMenu addItem:playlistMenuItem];
    [libraryMenu addItem:[NSMenuItem separatorItem]];
    
    // Misc
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"Reveal in Finder"];
    [item setActionBlock:^{[[selfRef target] revealIndexes:[[selfRef target] selectedIndexes]];}];
    [libraryMenu addItem:item];
    [libraryMenu addItem:[NSMenuItem separatorItem]];
    
    // Delete
    c[0] = NSDeleteCharacter;
    item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"Delete"];
    if (![[[db playlists] typeForList:_currentList] isEqual:PRListTypeLibrary]) {
        [item setTitle:@"Remove"];
    }
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:0];
    [item setActionBlock:^{[[selfRef target] deleteIndexes:[[selfRef target] selectedIndexes]];}];
    [libraryMenu addItem:item];
}

- (void)updateHeaderMenu {
	for (NSMenuItem *i in [headerMenu itemArray]) {
		[headerMenu removeItem:i];
	}
	MAZeroingWeakRef *selfRef = [MAZeroingWeakRef refWithTarget:self];
    
    NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
	[menuItem setTitle:@"Browser"];
    [menuItem setSubmenu:[self browserHeaderMenu]];
	[headerMenu addItem:menuItem];
    [headerMenu addItem:[NSMenuItem separatorItem]];
	
	// Columns	
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"headerCell.stringValue" ascending:TRUE] autorelease];
	NSArray *sortedTableColumns = [[libraryTableView tableColumns] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	for (NSTableColumn *i in sortedTableColumns) {
        if ([[i identifier] isEqual:PRListSortIndex]) {
            continue;
        }
		menuItem = [[[NSMenuItem alloc] init] autorelease];
		[menuItem setTitle:[[i headerCell] stringValue]];
		if (![i isHidden]) {
			[menuItem setState:NSOnState];
		}
		[menuItem setActionBlock:^{[[selfRef target] toggleColumn:i];}];
		[headerMenu addItem:menuItem];
	}
}

- (void)updateBrowserHeaderMenu {
    [browserHeaderMenu removeAllItems];
    NSMenu *menu = [self browserHeaderMenu];
    for (NSMenuItem *i in [menu itemArray]) {
        [menu removeItem:i];
        [browserHeaderMenu addItem:i];
    }
}

// ========================================
// misc

- (NSTableView *)tableViewForBrowser:(int)browser {
    if (browser == 1) {
        return browser1TableView;
    } else if (browser == 2) {
        return browser2TableView;
    } else if (browser == 3) {
        return browser3TableView;
    }
    @throw NSInvalidArgumentException;
}

- (int)browserForTableView:(NSTableView *)tableView {
	if (tableView == browser1TableView) {
		return 1;
	} else if (tableView == browser2TableView) {
		return 2;
	} else if (tableView == browser3TableView) {
		return 3;
	}
    @throw NSInvalidArgumentException;
}

- (int)dbRowForTableRow:(int)tableRow {
	return tableRow + 1;
}

- (NSIndexSet *)dbRowIndexesForTableRowIndexes:(NSIndexSet *)tableRows {
	NSMutableIndexSet *dbRows = [NSMutableIndexSet indexSet];
    [tableRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if ([self dbRowForTableRow:idx] != -1) {
			[dbRows addIndex:[self dbRowForTableRow:idx]];
		}
    }];
    return dbRows;
}

- (int)tableRowForDbRow:(int)dbRow {
	return dbRow - 1;
}

- (NSIndexSet *)tableRowIndexesForDbRowIndexes:(NSIndexSet *)dbRows {
    NSMutableIndexSet *tableRows = [NSMutableIndexSet indexSet];
    [dbRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [tableRows addIndex:[self tableRowForDbRow:idx]];
    }];
    return tableRows;
}

// ========================================
// Tableview Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == libraryTableView) {
		return [[db libraryViewSource] count];
	} else if (tableView == browser1TableView) {
        return [[db libraryViewSource] countForBrowser:1] + 1;
	} else if (tableView == browser2TableView) {
		return [[db libraryViewSource] countForBrowser:2] + 1;
	} else if (tableView == browser3TableView) {
		return [[db libraryViewSource] countForBrowser:3] + 1;
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	if (tableView == libraryTableView) {
		rowIndex = [self dbRowForTableRow:rowIndex];
        if (rowIndex == -1) {
            return nil;
        }
        
        PRItemAttr *attr = [tableColumn identifier];
		if ([attr isEqual:PRListSortIndex]) {
            PRFile file_ = [[[db libraryViewSource] itemForRow:rowIndex] intValue];
            if ([[self sortAttr] isEqual:PRListSortIndex]) {
                if ([self ascending]) {
                    return [NSNumber numberWithInt:rowIndex];
                } else {
                    return [NSNumber numberWithInt:[self numberOfRowsInTableView:libraryTableView] - rowIndex + 1];
                } 
            } else {
                NSIndexSet *rows = [[db playlists] indexesOfItem:[NSNumber numberWithInt:file_] inList:_currentList];
                return [NSNumber numberWithInt:[rows firstIndex]];
            }
		} else {
            id value = [[db libraryViewSource] valueForRow:rowIndex attribute:attr andCacheAttributes:^{return [self attributesToCache];}];
            if ([attr isEqual:PRItemAttrRating]) {
                value = [NSNumber numberWithInt:floor([value intValue] / 20)];
            } else if ([attr isEqual:PRItemAttrPath]) {
                value = [[NSURL URLWithString:value] path];
            } else if ([attr isEqual:PRItemAttrTrackNumber]) {
                if ([[[db libraryViewSource] itemForRow:rowIndex] isEqual:[now currentItem]]) {
                    value = [NSString stringWithFormat:@"◈"];
                }
            }
            return value;
		}
	} else if (tableView == browser1TableView || tableView == browser2TableView || tableView == browser3TableView) {		
		int browser = [self browserForTableView:tableView];
		if (rowIndex == 0) {
            PRItemAttr *attr = [[db playlists] attrForBrowser:browser list:_currentList];
			return [NSString stringWithFormat:@"All (%d %@s)", [[db libraryViewSource] countForBrowser:browser], [PRLibrary titleForItemAttr:attr]];
		}
        return [[db libraryViewSource] valueForRow:rowIndex browser:browser];
	}
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	PRItemAttr *attr = [tableColumn identifier];
	if ([self dbRowForTableRow:rowIndex] != -1) {
        PRFile file = [[[db libraryViewSource] itemForRow:[self dbRowForTableRow:rowIndex]] intValue];
        PRItem *item = [PRItem numberWithInt:file];
		if ([attr isEqualToString:PRItemAttrRating]) {
			int rating = [object intValue] * 20;
            [[db library] setValue:[NSNumber numberWithInt:rating] forItem:[NSNumber numberWithInt:file] attr:PRItemAttrRating];
		} else {
            NSURL *URL = [[db library] URLForItem:[PRItem numberWithInt:file]];
            [PRTagger setTag:object forAttribute:attr URL:URL];
            [[db library] updateTagsForItem:[NSNumber numberWithInt:file]];
		}
        [[NSNotificationCenter defaultCenter] postItemsChanged:[NSArray arrayWithObject:item]];
	}
}

// ========================================
// tableview datasource misc

- (NSArray *)attributesToCache {
    NSMutableArray *cachedAttributes = [NSMutableArray array];
    for (NSTableColumn *i in [libraryTableView tableColumns]) {
        if (![i isHidden] && ![[i identifier] isEqual:PRListSortIndex]) {
            [cachedAttributes addObject:[i identifier]];
        }
    }
    return cachedAttributes;
}

// ========================================
// Tableview DragAndDrop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
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
				PRFile file = [[[db libraryViewSource] itemForRow:[self dbRowForTableRow:currentIndex]] intValue];
				[files addObject:[NSNumber numberWithInt:file]];
			}
			currentIndex++;
		}
	} else if (tableView == libraryTableView) {
		// If dragging from library, get selected files
		while ((currentIndex = [rowIndexes indexGreaterThanOrEqualToIndex:currentIndex]) != NSNotFound) {
			if ([self dbRowForTableRow:currentIndex] != -1) {
				PRFile file = [[[db libraryViewSource] itemForRow:[self dbRowForTableRow:currentIndex]] intValue];
				[files addObject:[NSNumber numberWithInt:file]];
			}
			currentIndex++;
		}
	} else {
		return FALSE;
	}
    
    // PRIndexesPboardType
    NSIndexSet *indexes = [NSIndexSet indexSet];
    if (tableView == libraryTableView && [[self sortAttr] isEqual:PRListSortIndex]) {
        indexes = [[[NSIndexSet alloc] initWithIndexSet:[self dbRowIndexesForTableRowIndexes:rowIndexes]] autorelease];
    }
    
    // Write to Pboard
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:files]
            forType:PRFilePboardType];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:indexes]
            forType:PRIndexesPboardType];
	return TRUE;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
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
        ![[[db playlists] typeForList:_currentList] isEqual:PRListTypeLibrary] && 
        [indexes count] != 0 && 
        [indexSet1 firstIndex] == 0 &&
        [indexSet2 firstIndex] == 0 &&
        [indexSet3 firstIndex] == 0) {
		return NSDragOperationEvery;
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];    
    if ([info draggingSource] != libraryTableView) {
        return FALSE;
	}
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:PRIndexesPboardType]];
    
    // get move row
    PRListItem *listItem = [[db playlists] listItemAtIndex:[indexes firstIndex] inList:_currentList];
                   
    int row2 = [self dbRowForTableRow:row];
    [[db playlists] moveItemsAtIndexes:indexes toIndex:row2 inList:_currentList];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:_currentList];
    
    // select
    int index = [[db playlists] indexForListItem:listItem];
    NSIndexSet *indexesToSelect = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self tableRowForDbRow:index], [indexes count])];
    [libraryTableView selectRowIndexes:indexesToSelect byExtendingSelection:FALSE];
    return TRUE;
}

// ========================================
// Tableview Delegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    [cell setHighlighted:[[tableView selectedRowIndexes] containsIndex:row]];
}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)column{
    if (tableView == libraryTableView && [[column identifier] intValue] == PRPlaylistIndexSort) {
        [tableView setAllowsColumnReordering:NO];
    } else {
        [tableView setAllowsColumnReordering:YES];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex {
    if (tableView == libraryTableView && [[[db playlists] typeForList:_currentList] isEqual:PRListTypeStatic] && newColumnIndex == 0) {
        return FALSE;
    } else {
        return TRUE;
    }
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	if (tableView != libraryTableView) {
		return;
	}
    if ([[tableColumn identifier] isEqual:[self sortAttr]]) {
		[self setAscending:![self ascending]];
	} else {
        [self setSortAttr:[tableColumn identifier]];
        [self setAscending:TRUE];
    }
	[self loadTableColumns];
    [self reloadData:FALSE];
    [tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	id object = [notification object];
	if (object == libraryTableView) {
        [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
	} else if (_currentList && (object == browser1TableView || object == browser2TableView || object == browser3TableView)) {
        if (!_updatingTableViewSelection) {
            return;
        }
        BOOL browser = [self browserForTableView:object];
		NSMutableArray *selection = [NSMutableArray array];
        [[object selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            if (idx != 0) {
                [selection addObject:[self tableView:object objectValueForTableColumn:nil row:idx]];
            }
        }];
        [[db playlists] setSelection:selection forBrowser:browser list:_currentList];
        [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
	}
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)indexes {
	if ((tableView == browser1TableView || tableView == browser2TableView || tableView == browser3TableView) && [indexes containsIndex:0]) {
        return [NSIndexSet indexSetWithIndex:0];
	}
	return indexes;
}

- (void)tableViewColumnDidMove:(NSNotification *)notification {
	if (!refreshing) {
		[self saveTableColumns];
	}
}

- (void)tableViewColumnDidResize:(NSNotification *)notification {
	if (!refreshing && [notification object] == libraryTableView) {
		[self saveTableColumns];
	}
}

// ========================================
// Tableview PRDelegate

- (BOOL)tableView:(PRTableView *)tableView keyDown:(NSEvent *)event {
    if ([[event characters] length] != 1) {
        return FALSE;
    }
    BOOL didHandle = FALSE;
    NSUInteger flags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    UniChar c = [[event characters] characterAtIndex:0];
    if (flags == 0) {
        if (c == 0x20) {
            [now playPause];
            didHandle = TRUE;
        } else if (c == 0x7F || c == 0xf728) {
            if (tableView == libraryTableView) {
                [self deleteIndexes:[libraryTableView selectedRowIndexes]];
            }
            didHandle = TRUE;
        } else if (c == 0xd) {
            if (tableView == libraryTableView) {
                [self playIndexes:[libraryTableView selectedRowIndexes]];
            } else {
                [self playBrowser:nil];
            }
            didHandle = TRUE;
        }
    } else if (flags == NSShiftKeyMask) {
        if (c == 0xd) {
            if (tableView == libraryTableView) {
                [self appendIndexes:[libraryTableView selectedRowIndexes]];
            } else {
                [self appendAll];
            }
            didHandle = TRUE;
        }
    } else if (flags == NSAlternateKeyMask) {
        if (c == 0xd) {
            if (tableView == libraryTableView) {
                [self appendNextIndexes:[libraryTableView selectedRowIndexes]];
            } else {
                [self appendNextAll];
            }
            didHandle = TRUE;
        }
    } else if (flags == (NSNumericPadKeyMask | NSFunctionKeyMask)) {
        if (c == 0xf703) {
            [now playNext];
            didHandle = TRUE;
        } else if (c == 0xf702) {
            [now playPrevious];
            didHandle = TRUE;
        }
    }
    return didHandle;
}

// ========================================
// Splitview Delegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    if (splitView == horizontalBrowserSplitView) {
        return subview != horizontalBrowserSubSplitview;
    } else if (splitView == verticalBrowserSplitView) {
        return subview == verticalBrowserLibrarySuperview;
    } else if (splitView == horizontalBrowserSubSplitview) {
        return FALSE;
    }
    @throw NSInvalidArgumentException;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
	return TRUE;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if (refreshing) {
        return;
    }
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

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)idx {	
	if (splitView == verticalBrowserSplitView) {
		if (proposedPosition > 400) {
			return 400;
		} else if (proposedPosition < 120) {
			return 120;
		}
	} else if (splitView == horizontalBrowserSubSplitview) {
        if ([[horizontalBrowserSubSplitview subviews] count] == 3) {
            float width = ([horizontalBrowserSubSplitview frame].size.width - 2) / 3;
            if (idx == 0) {
                return width;
            } else if (idx == 1) {
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

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedRect forDrawnRect:(NSRect)rect ofDividerAtIndex:(NSInteger)idx {
    if (splitView == horizontalBrowserSubSplitview) {
        return NSZeroRect;
    }
    return proposedRect;
}

// ========================================
// Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
	if (menu == libraryMenu) {
		[self updateLibraryMenu];
	} else if (menu == headerMenu) {
		[self updateHeaderMenu];
	} else if (menu == browserHeaderMenu) {
		[self updateBrowserHeaderMenu];
	} else {
        @throw NSInvalidArgumentException;
    }
}

@end
