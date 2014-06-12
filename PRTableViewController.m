#import "PRTableViewController.h"
#import "NSColor+Extensions.h"
#import "NSMenuItem+Extensions.h"
#import "NSString+Extensions.h"
#import "NSTableView+Extensions.h"
#import "PRBitRateFormatter.h"
#import "PRCenteredTextFieldCell.h"
#import "PRCore.h"
#import "PRDateFormatter.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRKindFormatter.h"
#import "PRLibrary.h"
#import "PRLibraryViewController.h"
#import "PRLibraryViewSource.h"
#import "PRMainWindowController.h"
#import "PRMainWindowController.h"
#import "PRNowPlayingController.h"
#import "PRNowPlayingViewController.h"
#import "PRNumberFormatter.h"
#import "PRPaneSplitView.h"
#import "PRPlaylists.h"
#import "PRQueue.h"
#import "PRRatingCell.h"
#import "PRSizeFormatter.h"
#import "PRStringFormatter.h"
#import "PRTableHeaderCell.h"
#import "PRTableViewController+Private.h"
#import "PRTagger.h"
#import "PRTimeFormatter.h"
#import "sqlite_str.h"
#import <Carbon/Carbon.h>


@implementation PRTableViewController

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    return self;
}

- (void)loadView {
    NSView *view = [[NSView alloc] init];
    [view setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [self setView:view];
    
    // BrowserSplitView
    _horizontalBrowserSplitView = [[PRPaneSplitView alloc] init];
    [_horizontalBrowserSplitView setDelegate:self];
    [_horizontalBrowserSplitView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    
    _horizontalBrowserSubSplitView = [[NSSplitView alloc] init];
    [_horizontalBrowserSubSplitView setDividerStyle:NSSplitViewDividerStyleThin];
    [_horizontalBrowserSubSplitView setVertical:YES];
    [_horizontalBrowserSubSplitView setDelegate:self];
    [_horizontalBrowserSplitView addSubview:_horizontalBrowserSubSplitView];
    
    _horizontalBrowserDetailSuperView = [[NSView alloc] init];
    [_horizontalBrowserSplitView addSubview:_horizontalBrowserDetailSuperView];
    
    _verticalBrowserSplitView = [[NSSplitView alloc] init];
    [_verticalBrowserSplitView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [_verticalBrowserSplitView setDividerStyle:NSSplitViewDividerStyleThin];
    [_verticalBrowserSplitView setVertical:YES];
    [_verticalBrowserSplitView setDelegate:self];
    
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
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRListSortIndex];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:40];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"#"];
    [[tableColumn headerCell] setAlignment:NSCenterTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setAlignment:NSCenterTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];
    
    // Path
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrPath];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Path"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // Title
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrTitle];
    [tableColumn setWidth:300];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Title"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Artist
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrArtist];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Artist"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Album
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrAlbum];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Album"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // AlbumArtist
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrAlbumArtist];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Album Artist"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Composer
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrComposer];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Composer"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Genre
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrGenre];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Genre"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Year
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrYear];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Year"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:numberFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Comments
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrComments];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:50];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Comments"];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:stringFormatter];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // BPM
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrBPM];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"BPM"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:numberFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Track
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrTrackNumber];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Track #"];
    [[tableColumn headerCell] setAlignment:NSCenterTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:numberFormatter];
    [[tableColumn dataCell] setAlignment:NSCenterTextAlignment];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // Disc
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrDiscNumber];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Disc #"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:numberFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:YES];
    [tableColumns addObject:tableColumn];

    // PlayCount
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrPlayCount];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Plays"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:numberFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // DateAdded
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrDateAdded];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Date Added"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:dateFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // LastPlayed
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrLastPlayed];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Last Played"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:dateFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // Size
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrSize];
    [tableColumn setWidth:100];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Size"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:sizeFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // Kind
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrKind];
    [tableColumn setWidth:200];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Kind"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:kindFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // Time
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrTime];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Time"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:timeFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // Bitrate
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrBitrate];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Bitrate"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setFormatter:bitRateFormatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // Channels
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrChannels];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Channels"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // SampleRate
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrSampleRate];
    [tableColumn setWidth:40];
    [tableColumn setMinWidth:40];
    [tableColumn setMaxWidth:1000];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Sample Rate"];
    [[tableColumn headerCell] setAlignment:NSRightTextAlignment];
    [tableColumn setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    // Rating
    tableColumn = [[NSTableColumn alloc] initWithIdentifier:PRItemAttrRating];
    [tableColumn setWidth:75];
    [tableColumn setMinWidth:75];
    [tableColumn setMaxWidth:75];
    [tableColumn setHeaderCell:[[PRTableHeaderCell alloc] init]];
    [[tableColumn headerCell] setStringValue:@"Rating"];
    [[tableColumn headerCell] setAlignment:NSLeftTextAlignment];
    PRRatingCell *ratingCell = [[PRRatingCell alloc] init];
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
    [tableColumn setEditable:NO];
    [tableColumns addObject:tableColumn];

    for (NSTableColumn *i in tableColumns) {
        [i setHidden:YES];
        [_detailTableView addTableColumn:i];
    }

    // LibraryTableView Context menu
    _libraryMenu = [[NSMenu alloc] init];
    [_libraryMenu setDelegate:self];
    [_detailTableView setMenu:_libraryMenu];

    // LibraryTableView Header Context Menu
    _headerMenu = [[NSMenu alloc] init];
    [_headerMenu setDelegate:self];
    [[_detailTableView headerView] setMenu:_headerMenu];

    // BrowserTableView
    NSMutableArray *scrollViews = [NSMutableArray array];
    for (NSInteger i = 0; i < 4; i++){
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        [scrollView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setAutohidesScrollers:YES];
        [scrollViews addObject:scrollView];
        
        PRTableView *tableView = [[PRTableView alloc] initWithFrame:[scrollView bounds]];
        [tableView setTarget:self];
        [tableView setDoubleAction:@selector(playBrowser:)];
        [tableView setDataSource:self];
        [tableView setDelegate:self];
        [tableView setFocusRingType:NSFocusRingTypeNone];
        [tableView setBackgroundColor:[NSColor PRBrowserBackgroundColor]];
        [scrollView setDocumentView:tableView];
        
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@""];
        [column setDataCell:[[PRCenteredTextFieldCell alloc] init]];
        [column setEditable:NO];
        [tableView addTableColumn:column];
    }
    _horizontalBrowser1ScrollView = scrollViews[0];
    _horizontalBrowser2ScrollView = scrollViews[1];
    _horizontalBrowser3ScrollView = scrollViews[2];
    [_verticalBrowserSplitView addSubview:scrollViews[3]];
    _horizontalBrowser1TableView = [scrollViews[0] documentView];
    _horizontalBrowser2TableView = [scrollViews[1] documentView];
    _horizontalBrowser3TableView = [scrollViews[2] documentView];
    _verticalBrowser1TableView = [scrollViews[3] documentView];
    
    _verticalBrowserDetailSuperView = [[NSView alloc] init];
    [_verticalBrowserSplitView addSubview:_verticalBrowserDetailSuperView];
    
    // BrowserTableView Context Menu
    _browserHeaderMenu = [[NSMenu alloc] init];
    [_browserHeaderMenu setDelegate:self];
    [[_horizontalBrowser1TableView headerView] setMenu:_browserHeaderMenu];
    [[_horizontalBrowser2TableView headerView] setMenu:_browserHeaderMenu];
    [[_horizontalBrowser3TableView headerView] setMenu:_browserHeaderMenu];
    [[_verticalBrowser1TableView headerView] setMenu:_browserHeaderMenu];
        
    // Key Views
    [[self firstKeyView] setNextKeyView:_horizontalBrowser1TableView];
    [_horizontalBrowser1TableView setNextKeyView:_horizontalBrowser2TableView];
    [_horizontalBrowser2TableView setNextKeyView:_horizontalBrowser3TableView];
    [_horizontalBrowser3TableView setNextKeyView:_verticalBrowser1TableView];
    [_verticalBrowser1TableView setNextKeyView:_detailTableView];
    [_detailTableView setNextKeyView:[self lastKeyView]];
    
    // Update
    [[NSNotificationCenter defaultCenter] observeLibraryChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(tagsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeUseAlbumArtistChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistFilesChanged:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(playingFileChanged:)];
}

#pragma mark - Accessors

- (PRList *)currentList {
    return _currentList;
}

- (void)setCurrentList:(PRList *)list {
    _currentList = list;
    
    if (list) {        
        [self loadTableColumns];
        [self loadBrowser];
        [self reloadData:YES];
        [_detailTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [_detailTableView scrollRowToVisiblePretty:0];
        [_browser1TableView scrollRowToVisiblePretty:[_browser1TableView selectedRow]];
        [_browser2TableView scrollRowToVisiblePretty:[_browser2TableView selectedRow]];
        [_browser3TableView scrollRowToVisiblePretty:[_browser3TableView selectedRow]];
    }
}

- (NSDictionary *)info {
    return [[_db libraryViewSource] info];
}

- (NSArray *)selection {
    NSMutableArray *selectionArray = [NSMutableArray array];
    [[self dbRowIndexesForTableRowIndexes:[_detailTableView selectedRowIndexes]] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [selectionArray addObject:[[_db libraryViewSource] itemForRow:idx]];
    }];
    return selectionArray;
}

#pragma mark - Accessors Priv

- (NSIndexSet *)selectedIndexes {
    return [_detailTableView selectedRowIndexes];
}

#pragma mark - Action

- (void)highlightItem:(PRItem *)item {
    NSString *artist;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation] && [[[_db library] valueForItem:item attr:PRItemAttrCompilation] boolValue]) {
        artist = compilationString;
    } else {
        artist = [[_db library] artistValueForItem:item];
    }
    [self browseToArtist:artist];
    
    int dbRow = [[_db libraryViewSource] rowForItem:item];
    if (dbRow != -1) {
        int tableRow = [self tableRowForDbRow:dbRow];
        [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tableRow] byExtendingSelection:NO];
        [_detailTableView scrollRowToVisiblePretty:tableRow];
    }
}

- (void)highlightFiles:(NSArray *)items {
    if ([items count] == 0) {
        return;
    }
    NSMutableIndexSet *dbRows = [NSMutableIndexSet indexSet];
    for (NSNumber *i in items) {
        int dbRow = [[_db libraryViewSource] rowForItem:i];
        if (dbRow == -1) {
            [dbRows removeAllIndexes];
            break;
        }
        [dbRows addIndex:dbRow];
    }
    if ([dbRows count] == 0) {
        [[_db playlists] setSearch:@"" forList:_currentList];
        [[_db playlists] setSelection:@[] forBrowser:1 list:_currentList];
        [[_db playlists] setSelection:@[] forBrowser:2 list:_currentList];
        [[_db playlists] setSelection:@[] forBrowser:3 list:_currentList];
        [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
        
        for (NSNumber *i in items) {
            int dbRow = [[_db libraryViewSource] rowForItem:i];
            if (dbRow == -1) {
                [dbRows removeAllIndexes];
                break;
            }
            [dbRows addIndex:dbRow];
        }
    }
    if ([dbRows count] > 0) {
        NSIndexSet *tableRows = [self tableRowIndexesForDbRowIndexes:dbRows];
        [_detailTableView selectRowIndexes:tableRows byExtendingSelection:NO];
        [_detailTableView scrollRowToVisiblePretty:[tableRows firstIndex]];
    }
}

- (void)highlightArtist:(NSString *)artist {
    [self browseToArtist:artist];
    PRItemAttr *attr;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        attr = PRItemAttrArtistAlbumArtist;
    } else {
        attr = PRItemAttrArtist;
    }
    int row = [self tableRowForDbRow:[[_db libraryViewSource] firstRowWithValue:artist forAttr:attr]]; 
    if (row == -1 || row == 0) {
        return;
    }
    [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [_detailTableView scrollRowToVisiblePretty:row];
}

- (void)browseToArtist:(NSString *)artist {
    [[_db playlists] setSearch:@"" forList:_currentList];
    for (int i = 1; i <= 3; i++) {
        NSArray *selection = @[];
        if ([[[_db playlists] attrForBrowser:i list:_currentList] isEqual:PRItemAttrArtist]) {
            selection = @[artist];
        }
        [[_db playlists] setSelection:selection forBrowser:i list:_currentList];
    }
    [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
    [_browser1TableView scrollRowToVisiblePretty:[_browser1TableView selectedRow]];
    [_browser2TableView scrollRowToVisiblePretty:[_browser2TableView selectedRow]];
    [_browser3TableView scrollRowToVisiblePretty:[_browser3TableView selectedRow]];
}

#pragma mark - Action Priv

- (void)playIndexes:(NSIndexSet *)indexes {
    [_now stop];
    [[_db playlists] clearList:[_now currentList]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        PRItem *item = [[_db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]];
        [[_db playlists] appendItem:item toList:[_now currentList]];
    }];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_now currentList]];
    if ([[_db playlists] countForList:[_now currentList]] > 0) {
        [_now playNext];
    }
}

- (void)appendIndexes:(NSIndexSet *)indexes {
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];    
    }];
    [[[_core win] nowPlayingViewController] addItems:items atIndex:[[_db playlists] countForList:[_now currentList]]+1];
}

- (void)appendNextIndexes:(NSIndexSet *)indexes {
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];
    }];
    [[[_core win] nowPlayingViewController] addItems:items atIndex:[_now currentIndex]+1];
}

- (void)deleteIndexes:(NSIndexSet *)indexes {
    if ([indexes count] == 0) {
        return;
    }
    if (![_currentList isEqual:[[_db playlists] libraryList]]) {
        NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
        NSTableColumn *tableColumn = [_detailTableView tableColumnWithIdentifier:PRListSortIndex];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [indexesToDelete addIndex:[[self tableView:_detailTableView objectValueForTableColumn:tableColumn row:idx] intValue]];
        }];
        [[_db playlists] removeItemsAtIndexes:indexesToDelete fromList:_currentList];
        
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:_currentList];
        [_detailTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    } else {
        NSString *message = @"Do you want to remove the selected song from your library?";
        if ([indexes count] != 1) {
            message = [NSString stringWithFormat:@"Do you want to remove the %lu selected songs from your library?", (unsigned long)[indexes count]];
        }
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Remove"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:message];
        [alert setInformativeText:@"These files will not be deleted from your computer"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[[self view] window] 
                          modalDelegate:self 
                         didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:)
                            contextInfo:(__bridge_retained void *)indexes];
    }
}

- (void)appendIndexes:(NSIndexSet *)indexes toList:(PRList *)list {
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        PRItem *item = [[_db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]];
        [[_db playlists] appendItem:item toList:list];
    }];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

- (void)revealIndexes:(NSIndexSet *)indexes {
    int row = [indexes indexGreaterThanOrEqualToIndex:0];
    PRItem *item = [[_db libraryViewSource] itemForRow:[self dbRowForTableRow:row]];
    [[NSWorkspace sharedWorkspace] selectFile:[[[_db library] URLForItem:item] path] inFileViewerRootedAtPath:nil];
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSIndexSet *indexes = (__bridge_transfer NSIndexSet *)contextInfo;
    if (returnCode != NSAlertFirstButtonReturn) {
        return;
    }
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [items addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];
    }];
    if ([items containsObject:[_now currentItem]]) {
        [_now stop];
    }
    [[_db library] removeItems:items];
    [[NSNotificationCenter defaultCenter] postLibraryChanged];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_now currentList]];
    [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];    
}

- (void)appendAll {
    [self appendIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:_detailTableView])]];
}

- (void)appendNextAll {
    [self appendNextIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:_detailTableView])]];
}

#pragma mark - Action Mouse Priv

- (void)play {
    if ([self dbRowForTableRow:[_detailTableView clickedRow]] < 1) {
        return;
    }
    if ([[_detailTableView selectedRowIndexes] count] > 1) {
        [self playIndexes:[_detailTableView selectedRowIndexes]];
    } else {
        [_now stop];
        [[_db playlists] clearList:[_now currentList]];
        [[_db playlists] appendItemsFromLibraryViewSourceToList:[_now currentList]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_now currentList]];
        [_now playItemAtIndex:[self dbRowForTableRow:[_detailTableView clickedRow]]];
    }
}

- (void)playBrowser:(id)sender {
    if ([sender clickedRow] == -1) {
        return;
    }
    [_now stop];
    [[_db playlists] clearList:[_now currentList]];
    [[_db playlists] appendItemsFromLibraryViewSourceToList:[_now currentList]];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_now currentList]];
    if ([[_db playlists] countForList:[_now currentList]] > 0) {
        [_now playNext];
    }
}

#pragma mark - Setup

- (void)reloadData:(BOOL)force {
    int tables = [[_db libraryViewSource] refreshWithList:_currentList force:force];
    
    _updatingTableViewSelection = NO;
    if ((tables & PRLibraryView) == PRLibraryView) {
        [_detailTableView reloadData];
    }
    if ((tables & PRBrowser1View) == PRBrowser1View) {
        [_browser1TableView reloadData];
    }
    if ((tables & PRBrowser2View) == PRBrowser2View) {    
        [_browser2TableView reloadData];
    }
    if ((tables & PRBrowser3View) == PRBrowser3View) {
        [_browser3TableView reloadData];
    }
    [_browser1TableView selectRowIndexes:[[_db libraryViewSource] selectionForBrowser:1] byExtendingSelection:NO];
    [_browser2TableView selectRowIndexes:[[_db libraryViewSource] selectionForBrowser:2] byExtendingSelection:NO];
    [_browser3TableView selectRowIndexes:[[_db libraryViewSource] selectionForBrowser:3] byExtendingSelection:NO];
    _updatingTableViewSelection = YES;
    
    [NSNotificationCenter post:PRLibraryViewSelectionDidChangeNotification];
}

#pragma mark - Update Priv

- (void)playingFileChanged:(NSNotification *)note {
    NSIndexSet *rows = [NSIndexSet indexSetWithIndexesInRange:[_detailTableView rowsInRect:[_detailTableView visibleRect]]];
    NSIndexSet *columns = [NSIndexSet indexSetWithIndex:[_detailTableView columnWithIdentifier:PRItemAttrTrackNumber]];
    [_detailTableView reloadDataForRowIndexes:rows columnIndexes:columns];
}

- (void)libraryDidChange:(NSNotification *)note {
    if (_currentList) {
        [self reloadData:YES];
    }
}

- (void)tagsDidChange:(NSNotification *)note {
    if (_currentList) {
        [self reloadData:YES];
    }
}

- (void)playlistDidChange:(NSNotification *)note {
    if (!_currentList || ![[[note userInfo] valueForKey:@"playlist"] isEqual:_currentList]) {
        return;
    }
    [self reloadData:NO];
    [_detailTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    [_detailTableView scrollRowToVisible:[_detailTableView selectedRow]];
    [_browser1TableView scrollRowToVisible:[_browser1TableView selectedRow]];
    [_browser2TableView scrollRowToVisible:[_browser2TableView selectedRow]];
    [_browser3TableView scrollRowToVisible:[_browser3TableView selectedRow]];
}

- (void)playlistFilesChanged:(NSNotification *)note {
    if (_currentList && [[[note userInfo] valueForKey:@"playlist"] isEqual:_currentList]) {
        [self reloadData:YES];
    }
}

#pragma mark - UI Priv

- (BOOL)ascending {
    return [[_db playlists] listViewAscendingForList:_currentList];
}

- (void)setAscending:(BOOL)ascending {
    [[_db playlists] setListViewAscending:ascending forList:_currentList];
}

- (PRItemAttr *)sortAttr {
    return [[_db playlists] listViewSortAttrForList:_currentList];
}

- (void)setSortAttr:(PRItemAttr *)attr {
    [[_db playlists] setListViewSortAttr:attr forList:_currentList];
}

- (NSArray *)columnInfo {
    return [[_db playlists] listViewInfoForList:_currentList];
}

- (void)setColumnInfo:(NSArray *)info {
    [[_db playlists] setListViewInfo:info forList:_currentList];
}

- (void)toggleColumn:(NSTableColumn *)column {
    [column setHidden:![column isHidden]];
    [self saveTableColumns];
}

- (void)toggleBrowser:(PRItemAttr *)attr {
    if ([[_db playlists] verticalForList:_currentList]) {
        [[_db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:attr forBrowser:3 list:_currentList];
    } else {
        NSMutableSet *set = [NSMutableSet set];
        for (int i = 1; i < 4; i++) {
            if ([[_db playlists] attrForBrowser:i list:_currentList]) {
                [set addObject:[[_db playlists] attrForBrowser:i list:_currentList]];
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
        for (PRItemAttr *i in @[PRItemAttrAlbum, PRItemAttrArtist, PRItemAttrComposer, PRItemAttrGenre]) {
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
                [[_db playlists] setAttr:nil forBrowser:3-i list:_currentList];
            } else {
                [[_db playlists] setAttr:[attrs objectAtIndex:i] forBrowser:3-i list:_currentList];
            }
        }
    }
    [[_db playlists] setSelection:@[] forBrowser:1 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:2 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:3 list:_currentList];
    [self loadBrowser];
    [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
}

- (void)setBrowserPosition:(PRBrowserPosition)position {
    if (position == PRBrowserPositionHorizontal) {
        [[_db playlists] setVertical:PRBrowserPositionHorizontal forList:_currentList];
        [[_db playlists] setAttr:PRItemAttrGenre forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:PRItemAttrArtist forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:PRItemAttrAlbum forBrowser:3 list:_currentList];
    } else if (position == PRBrowserPositionVertical) {
        [[_db playlists] setVertical:PRBrowserPositionVertical forList:_currentList];
        [[_db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:PRItemAttrArtist forBrowser:3 list:_currentList];
    } else if (position == PRBrowserPositionHidden) {
        [[_db playlists] setVertical:PRBrowserPositionHidden forList:_currentList];
        [[_db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:3 list:_currentList];
    }
    [[_db playlists] setSelection:@[] forBrowser:1 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:2 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:3 list:_currentList];
    [self loadBrowser];
    [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
}

- (void)loadBrowser {
    _refreshing = YES;
    [_verticalBrowserSplitView removeFromSuperview];
    [_horizontalBrowserSplitView removeFromSuperview];
    [_detailView removeFromSuperview];
    int browserPosition = [[_db playlists] verticalForList:_currentList];
    if (browserPosition == PRBrowserPositionVertical) {
        [[self view] addSubview:_verticalBrowserSplitView];
        NSRect bounds = [[self view] bounds];
        bounds.size.height += 1;
        [_verticalBrowserSplitView setFrame:bounds];
        [_verticalBrowserDetailSuperView addSubview:_detailView];
        [_detailView setFrame:[_verticalBrowserDetailSuperView bounds]];
        _browser1TableView = nil;
        _browser2TableView = nil;
        _browser3TableView = _verticalBrowser1TableView;
        [_verticalBrowserSplitView setPosition:[[_db playlists] verticalBrowserWidthForList:_currentList] ofDividerAtIndex:0];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [[self view] addSubview:_horizontalBrowserSplitView];
        NSRect bounds = [[self view] bounds];
        bounds.size.height += 1;
        [_horizontalBrowserSplitView setFrame:bounds];
        [_horizontalBrowserDetailSuperView addSubview:_detailView];
        bounds = [_horizontalBrowserDetailSuperView bounds];
        bounds.size.height += 1;
        [_detailView setFrame:bounds];
        
        [_horizontalBrowser1ScrollView removeFromSuperview];
        [_horizontalBrowser2ScrollView removeFromSuperview];
        [_horizontalBrowser3ScrollView removeFromSuperview];
        if (![[_db playlists] attrForBrowser:2 list:_currentList]) {
            [_horizontalBrowserSubSplitView addSubview:_horizontalBrowser3ScrollView];
        } else if (![[_db playlists] attrForBrowser:1 list:_currentList]) {
            [_horizontalBrowserSubSplitView addSubview:_horizontalBrowser2ScrollView];
            [_horizontalBrowserSubSplitView addSubview:_horizontalBrowser3ScrollView];
        } else {
            [_horizontalBrowserSubSplitView addSubview:_horizontalBrowser1ScrollView];
            [_horizontalBrowserSubSplitView addSubview:_horizontalBrowser2ScrollView];
            [_horizontalBrowserSubSplitView addSubview:_horizontalBrowser3ScrollView];
        }
        
        _browser1TableView = _horizontalBrowser1TableView;
        _browser2TableView = _horizontalBrowser2TableView;
        _browser3TableView = _horizontalBrowser3TableView;
       [_horizontalBrowserSplitView setPosition:[[_db playlists] horizontalBrowserHeightForList:_currentList] ofDividerAtIndex:0];
    } else if (browserPosition == PRBrowserPositionHidden){
        [[self view] addSubview:_detailView];
        NSRect bounds = [[self view] bounds];
        bounds.size.height += 1;
        [_detailView setFrame:bounds];
        _browser1TableView = nil;
        _browser2TableView = nil;
        _browser3TableView = nil;
    }
    for (int i = 1; i < 4; i++) {
        PRItemAttr *attr = [[_db playlists] attrForBrowser:i list:_currentList];
        NSString *title = @"";
        if (attr) {
            title = [PRLibrary titleForItemAttr:attr];
        }
        [[[[[self tableViewForBrowser:i] tableColumns] objectAtIndex:0] headerCell] setStringValue:title];
    }
    _refreshing = NO;
}

- (void)saveBrowser {
    if (!_currentList) {
        return;
    }
    int browserPosition = [[_db playlists] verticalForList:_currentList];
    if (browserPosition == PRBrowserPositionVertical) {
        float width = [[[_browser3TableView superview] superview] bounds].size.width;
        [[_db playlists] setVerticalBrowserWidth:width forList:_currentList];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        float height = [_horizontalBrowserSubSplitView frame].size.height;
        [[_db playlists] setHorizontalBrowserHeight:height forList:_currentList];
    }
}

- (void)loadTableColumns {
    _refreshing = YES;
    // set column attributes
    NSArray *columnsInfo = [self columnInfo];
    for (int i = 0; i < [columnsInfo count]; i++) {
        NSDictionary *columnInfo = [columnsInfo objectAtIndex:i];
        NSTableColumn *tableColumn = [_detailTableView tableColumnWithIdentifier:[PRPlaylists sortAttrForInternal:[columnInfo valueForKey:@"identifier"]]];
        [tableColumn setWidth:[[columnInfo valueForKey:@"width"] intValue]];
        [tableColumn setHidden:[[columnInfo valueForKey:@"hidden"] boolValue]];
        [_detailTableView moveColumn:[[_detailTableView tableColumns] indexOfObject:tableColumn] toColumn:i];
    }
    
    // playlist column
    NSTableColumn *tableColumn = [_detailTableView tableColumnWithIdentifier:PRListSortIndex];
    [_detailTableView moveColumn:[[_detailTableView tableColumns] indexOfObject:tableColumn] toColumn:0];
    [[[_detailTableView tableColumns] objectAtIndex:0] setHidden:([_currentList isEqual:[[_db playlists] libraryList]])];
    
    // highlight sort table column
    [self highlightTableColumn:[self tableColumnForAttr:[self sortAttr]] ascending:[self ascending]];
    _refreshing = NO;
}

- (void)saveTableColumns {
    NSArray *columns = [_detailTableView tableColumns];
    NSMutableArray *columnsInfo = [NSMutableArray array];
    for (NSTableColumn *i in columns) {
        if ([[i identifier] intValue] == PRPlaylistIndexSort) {
            continue;
        }
        [columnsInfo addObject:@{@"identifier":[PRPlaylists internalForSortAttr:[i identifier]], @"hidden":@([i isHidden]), @"width":@([i width])}];
    }
    [self setColumnInfo:columnsInfo];
}

#pragma mark - UI Misc Priv

- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending {
    for (NSTableColumn *i in [_detailTableView tableColumns]) {
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
    return [_detailTableView tableColumnWithIdentifier:attr];
}

#pragma mark - Menu

- (NSMenu *)browserHeaderMenu {
    int browserPosition = [[_db playlists] verticalForList:_currentList];
    __weak PRTableViewController *weakSelf = self;
    
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [item setTitle:@"Hidden"];
    [item setActionBlock:^{[weakSelf setBrowserPosition:PRBrowserPositionHidden];}];
    if (browserPosition == PRBrowserPositionHidden) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"On Top"];
    [item setActionBlock:^{[weakSelf setBrowserPosition:PRBrowserPositionHorizontal];}];
    if (browserPosition == PRBrowserPositionHorizontal) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"On Left"];
    [item setActionBlock:^{[weakSelf setBrowserPosition:PRBrowserPositionVertical];}];
    if (browserPosition == PRBrowserPositionVertical) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    if (browserPosition != PRBrowserPositionHidden) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        PRItemAttr *attr1 = [[_db playlists] attrForBrowser:1 list:_currentList];
        PRItemAttr *attr2 = [[_db playlists] attrForBrowser:2 list:_currentList];
        PRItemAttr *attr3 = [[_db playlists] attrForBrowser:3 list:_currentList];
        for (PRItemAttr *i in @[PRItemAttrGenre, PRItemAttrComposer, PRItemAttrArtist, PRItemAttrAlbum]) {
            item = [[NSMenuItem alloc] init];
            [item setTitle:[PRLibrary titleForItemAttr:i]];
            [item setActionBlock:^{[weakSelf toggleBrowser:i];}];
            if ([attr1 isEqual:i] || [attr2 isEqual:i] || [attr3 isEqual:i]) {
                [item setState:NSOnState];
            }
            [menu addItem:item];
        }
    }
    return menu;
}

#pragma mark - Menu Priv

- (void)updateLibraryMenu {
    if ([_detailTableView clickedRow] == -1) {
        return;
    }
    for (NSMenuItem *i in [_libraryMenu itemArray]) {
        [_libraryMenu removeItem:i];
    }
    __weak PRTableViewController *weakSelf = self;
    unichar c[1] = {NSCarriageReturnCharacter};
    
    // Play
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [item setTitle:@"Play"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:0];
    [item setActionBlock:^{[weakSelf playIndexes:[weakSelf selectedIndexes]];}];
    [_libraryMenu addItem:item];
    
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"Play Next"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [item setActionBlock:^{[weakSelf appendNextIndexes:[weakSelf selectedIndexes]];}];
    [_libraryMenu addItem:item];
    
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"Append"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:NSShiftKeyMask];
    [item setActionBlock:^{[weakSelf appendIndexes:[weakSelf selectedIndexes]];}];
    [_libraryMenu addItem:item];    
    [_libraryMenu addItem:[NSMenuItem separatorItem]];
    
    // Add to Playlist
    NSMenu *playlistMenu = [[NSMenu alloc] init];
    for (PRList *i in [[_db playlists] lists]) {
        if (![[[_db playlists] typeForList:i] isEqual:PRListTypeStatic]) {
            continue;
        }
        item = [[NSMenuItem alloc] init];
        [item setTitle:[NSString stringWithFormat:@" %@",[[_db playlists] titleForList:i]]];
        [item setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        [item setActionBlock:^{[weakSelf appendIndexes:[weakSelf selectedIndexes] toList:i];}];
        [playlistMenu addItem:item];
    }
    NSMenuItem *playlistMenuItem = [[NSMenuItem alloc] init];
    [playlistMenuItem setTitle:@"Add to Playlist"];
    [playlistMenuItem setSubmenu:playlistMenu];
    [_libraryMenu addItem:playlistMenuItem];
    [_libraryMenu addItem:[NSMenuItem separatorItem]];
    
    // Misc
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"Reveal in Finder"];
    [item setActionBlock:^{[weakSelf revealIndexes:[weakSelf selectedIndexes]];}];
    [_libraryMenu addItem:item];
    [_libraryMenu addItem:[NSMenuItem separatorItem]];
    
    // Delete
    c[0] = NSDeleteCharacter;
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"Delete"];
    if (![[[_db playlists] typeForList:_currentList] isEqual:PRListTypeLibrary]) {
        [item setTitle:@"Remove"];
    }
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:0];
    [item setActionBlock:^{[weakSelf deleteIndexes:[weakSelf selectedIndexes]];}];
    [_libraryMenu addItem:item];
}

- (void)updateHeaderMenu {
    for (NSMenuItem *i in [_headerMenu itemArray]) {
        [_headerMenu removeItem:i];
    }
    __weak PRTableViewController *weakSelf = self;
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setTitle:@"Browser"];
    [menuItem setSubmenu:[self browserHeaderMenu]];
    [_headerMenu addItem:menuItem];
    [_headerMenu addItem:[NSMenuItem separatorItem]];
    
    // Columns  
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"headerCell.stringValue" ascending:YES];
    NSArray *sortedTableColumns = [[_detailTableView tableColumns] sortedArrayUsingDescriptors:@[sortDescriptor]];
    for (NSTableColumn *i in sortedTableColumns) {
        if ([[i identifier] isEqual:PRListSortIndex]) {
            continue;
        }
        menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:[[i headerCell] stringValue]];
        if (![i isHidden]) {
            [menuItem setState:NSOnState];
        }
        [menuItem setActionBlock:^{[weakSelf toggleColumn:i];}];
        [_headerMenu addItem:menuItem];
    }
}

- (void)updateBrowserHeaderMenu {
    [_browserHeaderMenu removeAllItems];
    NSMenu *menu = [self browserHeaderMenu];
    for (NSMenuItem *i in [menu itemArray]) {
        [menu removeItem:i];
        [_browserHeaderMenu addItem:i];
    }
}

#pragma mark - Misc Priv

- (NSTableView *)tableViewForBrowser:(int)browser {
    if (browser == 1) {
        return _browser1TableView;
    } else if (browser == 2) {
        return _browser2TableView;
    } else if (browser == 3) {
        return _browser3TableView;
    }
    @throw NSInvalidArgumentException;
}

- (int)browserForTableView:(NSTableView *)tableView {
    if (tableView == _browser1TableView) {
        return 1;
    } else if (tableView == _browser2TableView) {
        return 2;
    } else if (tableView == _browser3TableView) {
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

#pragma mark - TableView Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == _detailTableView) {
        return [[_db libraryViewSource] count];
    } else if (tableView == _browser1TableView) {
        return [[_db libraryViewSource] countForBrowser:1] + 1;
    } else if (tableView == _browser2TableView) {
        return [[_db libraryViewSource] countForBrowser:2] + 1;
    } else if (tableView == _browser3TableView) {
        return [[_db libraryViewSource] countForBrowser:3] + 1;
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    if (tableView == _detailTableView) {
        rowIndex = [self dbRowForTableRow:rowIndex];
        if (rowIndex == -1) {
            return nil;
        }
        
        PRItemAttr *attr = [tableColumn identifier];
        if ([attr isEqual:PRListSortIndex]) {
            PRItem *item = [[_db libraryViewSource] itemForRow:rowIndex];
            if ([[self sortAttr] isEqual:PRListSortIndex]) {
                if ([self ascending]) {
                    return [NSNumber numberWithInt:rowIndex];
                } else {
                    return [NSNumber numberWithInt:[self numberOfRowsInTableView:_detailTableView] - rowIndex + 1];
                } 
            } else {
                NSIndexSet *rows = [[_db playlists] indexesOfItem:item inList:_currentList];
                return [NSNumber numberWithInt:[rows firstIndex]];
            }
        } else {
            id value = [[_db libraryViewSource] valueForRow:rowIndex attribute:attr andCacheAttributes:^{return [self attributesToCache];}];
            if ([attr isEqual:PRItemAttrRating]) {
                value = [NSNumber numberWithInt:floor([value intValue] / 20)];
            } else if ([attr isEqual:PRItemAttrPath]) {
                value = [[NSURL URLWithString:value] path];
            } else if ([attr isEqual:PRItemAttrTrackNumber]) {
                if ([[[_db libraryViewSource] itemForRow:rowIndex] isEqual:[_now currentItem]]) {
                    value = [NSString stringWithFormat:@"◈"];
                }
            }
            return value;
        }
    } else if (tableView == _browser1TableView || tableView == _browser2TableView || tableView == _browser3TableView) {        
        int browser = [self browserForTableView:tableView];
        if (rowIndex == 0) {
            PRItemAttr *attr = [[_db playlists] attrForBrowser:browser list:_currentList];
            return [NSString stringWithFormat:@"All (%d %@s)", [[_db libraryViewSource] countForBrowser:browser], [PRLibrary titleForItemAttr:attr]];
        }
        return [[_db libraryViewSource] valueForRow:rowIndex browser:browser];
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    PRItemAttr *attr = [tableColumn identifier];
    if ([self dbRowForTableRow:rowIndex] != -1) {
        PRItem *item = [[_db libraryViewSource] itemForRow:[self dbRowForTableRow:rowIndex]];
        if ([attr isEqualToString:PRItemAttrRating]) {
            int rating = [object intValue] * 20;
            [[_db library] setValue:[NSNumber numberWithInt:rating] forItem:item attr:PRItemAttrRating];
        } else {
            [PRTagger setTag:object forAttribute:attr URL:[[_db library] URLForItem:item]];
            [PRTagger updateTagsForItem:item database:_db];
        }
        [[NSNotificationCenter defaultCenter] postItemsChanged:@[item]];
    }
}

#pragma mark - TableView Datasource Priv

- (NSArray *)attributesToCache {
    NSMutableArray *cachedAttributes = [NSMutableArray array];
    for (NSTableColumn *i in [_detailTableView tableColumns]) {
        if (![i isHidden] && ![[i identifier] isEqual:PRListSortIndex]) {
            [cachedAttributes addObject:[i identifier]];
        }
    }
    return cachedAttributes;
}

#pragma mark - TableView DragAndDrop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    [pboard declareTypes:@[PRFilePboardType, PRIndexesPboardType] owner:self];
    
    // PRFilePboardType
    NSInteger currentIndex = 0;
    NSMutableArray *files = [NSMutableArray array];
    if (tableView == _browser1TableView ||
        tableView == _browser2TableView ||
        tableView == _browser3TableView) {
        // If dragging from browser, get all files
        while (currentIndex < [self numberOfRowsInTableView:_detailTableView]) {
            if ([self dbRowForTableRow:currentIndex] != -1) {
                [files addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:currentIndex]]];
            }
            currentIndex++;
        }
    } else if (tableView == _detailTableView) {
        // If dragging from library, get selected files
        while ((currentIndex = [rowIndexes indexGreaterThanOrEqualToIndex:currentIndex]) != NSNotFound) {
            if ([self dbRowForTableRow:currentIndex] != -1) {
                [files addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:currentIndex]]];
            }
            currentIndex++;
        }
    } else {
        return NO;
    }
    
    // PRIndexesPboardType
    NSIndexSet *indexes = [NSIndexSet indexSet];
    if (tableView == _detailTableView && [[self sortAttr] isEqual:PRListSortIndex]) {
        indexes = [[NSIndexSet alloc] initWithIndexSet:[self dbRowIndexesForTableRowIndexes:rowIndexes]];
    }
    
    // Write to Pboard
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:files]
            forType:PRFilePboardType];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:indexes]
            forType:PRIndexesPboardType];
    return YES;
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
    
    NSIndexSet *indexSet1 = [[_db libraryViewSource] selectionForBrowser:1];
    NSIndexSet *indexSet2 = [[_db libraryViewSource] selectionForBrowser:2];
    NSIndexSet *indexSet3 = [[_db libraryViewSource] selectionForBrowser:3];
    
    if (tableView == _detailTableView && 
        op == NSTableViewDropAbove && 
        ![[[_db playlists] typeForList:_currentList] isEqual:PRListTypeLibrary] && 
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
    if ([info draggingSource] != _detailTableView) {
        return NO;
    }
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:PRIndexesPboardType]];
    
    // get move row
    PRListItem *listItem = [[_db playlists] listItemAtIndex:[indexes firstIndex] inList:_currentList];
                   
    int row2 = [self dbRowForTableRow:row];
    [[_db playlists] moveItemsAtIndexes:indexes toIndex:row2 inList:_currentList];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:_currentList];
    
    // select
    int index = [[_db playlists] indexForListItem:listItem];
    NSIndexSet *indexesToSelect = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self tableRowForDbRow:index], [indexes count])];
    [_detailTableView selectRowIndexes:indexesToSelect byExtendingSelection:NO];
    return YES;
}

#pragma mark - TableView Delegate

- (NSInteger)tableView:(NSTableView *)tableView nextTypeSelectMatchFromRow:(NSInteger)startRow toRow:(NSInteger)endRow forString:(NSString *)string {
    // forward event if space-key so window can play/pause
    if ([string isEqualToString:@" "]) {
        return -1;
    }
    // if last search was unsuccessful don't search again
    if (_lastLibraryTypeSelectFailure && [string length] > 1) {
        return startRow;
    }
    
    NSTableColumn *column;
    if (tableView == _browser1TableView || tableView == _browser2TableView || tableView == _browser3TableView) {
        column = [[tableView tableColumns] objectAtIndex:0];
    } else {
        column = [tableView tableColumnWithIdentifier:PRItemAttrTitle];
    }
    // endRow can be before startRow so account for loop around
    int end = !(endRow < startRow) ? endRow : [self numberOfRowsInTableView:tableView] - 1;
    for (int i = startRow; i <= end; i++) {
        NSString *value = [self tableView:tableView objectValueForTableColumn:column row:i];
        if ([value noCaseBegins:string]) {
            _lastLibraryTypeSelectFailure = NO;
            return i;
        }
        if (i == end && endRow < startRow && end != endRow) {
            i = -1;
            end = endRow;
        }
    }
    _lastLibraryTypeSelectFailure = YES;
    return startRow;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    [cell setHighlighted:[[tableView selectedRowIndexes] containsIndex:row]];
}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)column{
    if (tableView == _detailTableView && [[column identifier] intValue] == PRPlaylistIndexSort) {
        [tableView setAllowsColumnReordering:NO];
    } else {
        [tableView setAllowsColumnReordering:YES];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex {
    if (tableView == _detailTableView && [[[_db playlists] typeForList:_currentList] isEqual:PRListTypeStatic] && newColumnIndex == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    if (tableView != _detailTableView) {
        return;
    }
    if ([[tableColumn identifier] isEqual:[self sortAttr]]) {
        [self setAscending:![self ascending]];
    } else {
        [self setSortAttr:[tableColumn identifier]];
        [self setAscending:YES];
    }
    [self loadTableColumns];
    [self reloadData:NO];
    [tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    id object = [notification object];
    if (object == _detailTableView) {
        [NSNotificationCenter post:PRLibraryViewSelectionDidChangeNotification];
    } else if (_currentList && (object == _browser1TableView || object == _browser2TableView || object == _browser3TableView)) {
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
        [[_db playlists] setSelection:selection forBrowser:browser list:_currentList];
        [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
    }
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)indexes {
    if ((tableView == _browser1TableView || tableView == _browser2TableView || tableView == _browser3TableView) && [indexes containsIndex:0]) {
        return [NSIndexSet indexSetWithIndex:0];
    }
    return indexes;
}

- (void)tableViewColumnDidMove:(NSNotification *)notification {
    if (!_refreshing) {
        [self saveTableColumns];
    }
}

- (void)tableViewColumnDidResize:(NSNotification *)notification {
    if (!_refreshing && [notification object] == _detailTableView) {
        [self saveTableColumns];
    }
}

#pragma mark - TableView PRDelegate

- (BOOL)tableView:(PRTableView *)tableView keyDown:(NSEvent *)event {
    if ([[event characters] length] != 1) {
        return NO;
    }
    BOOL didHandle = NO;
    NSUInteger flags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    UniChar c = [[event characters] characterAtIndex:0];
    if (flags == 0) {
        if (c == 0x7F || c == 0xf728) {
            if (tableView == _detailTableView) {
                [self deleteIndexes:[_detailTableView selectedRowIndexes]];
            }
            didHandle = YES;
        } else if (c == 0xd) {
            if (tableView == _detailTableView) {
                [self playIndexes:[_detailTableView selectedRowIndexes]];
            } else {
                [self playBrowser:nil];
            }
            didHandle = YES;
        }
    } else if (flags == NSShiftKeyMask) {
        if (c == 0xd) {
            if (tableView == _detailTableView) {
                [self appendIndexes:[_detailTableView selectedRowIndexes]];
            } else {
                [self appendAll];
            }
            didHandle = YES;
        }
    } else if (flags == NSAlternateKeyMask) {
        if (c == 0xd) {
            if (tableView == _detailTableView) {
                [self appendNextIndexes:[_detailTableView selectedRowIndexes]];
            } else {
                [self appendNextAll];
            }
            didHandle = YES;
        }
    }
    return didHandle;
}

#pragma mark - SplitView Delegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    if (splitView == _horizontalBrowserSplitView) {
        return subview != _horizontalBrowserSubSplitView;
    } else if (splitView == _verticalBrowserSplitView) {
        return subview == _verticalBrowserDetailSuperView;
    } else if (splitView == _horizontalBrowserSubSplitView) {
        return NO;
    }
    @throw NSInvalidArgumentException;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if (_refreshing) {
        return;
    }
    if ([notification object] == _horizontalBrowserSplitView) {
        if ([_horizontalBrowserSubSplitView frame].size.height < 120) {
            NSRect frame = [_horizontalBrowserSubSplitView frame];
            frame.size.height = 120;
            [_horizontalBrowserSubSplitView setFrame:frame];
        } else if ([_horizontalBrowserDetailSuperView frame].size.height < 120) {
            NSRect frame = [_horizontalBrowserSubSplitView frame];
            frame.size.height = [_horizontalBrowserSplitView frame].size.height - 120 - [_horizontalBrowserSplitView dividerThickness];
            [_horizontalBrowserSubSplitView setFrame:frame];
        }
    }
    [self saveBrowser];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)idx { 
    if (splitView == _verticalBrowserSplitView) {
        if (proposedPosition > 400) {
            return 400;
        } else if (proposedPosition < 120) {
            return 120;
        }
    } else if (splitView == _horizontalBrowserSubSplitView) {
        if ([[_horizontalBrowserSubSplitView subviews] count] == 3) {
            float width = ([_horizontalBrowserSubSplitView frame].size.width - 2) / 3;
            if (idx == 0) {
                return width;
            } else if (idx == 1) {
                return width * 2 + 1;
            }
        } else if ([[_horizontalBrowserSubSplitView subviews] count] == 2)  {
            float width = [_horizontalBrowserSubSplitView frame].size.width / 2;
            return width;
        } else {
            return [_horizontalBrowserSubSplitView frame].size.width;
        }
    } else if (splitView == _horizontalBrowserSplitView) {
        if (proposedPosition < 120) {
            return 120;
        } else if (proposedPosition > [_horizontalBrowserSplitView frame].size.height - 120) {
            return [_horizontalBrowserSplitView frame].size.height - 120;
        }
    }
    return proposedPosition;
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedRect forDrawnRect:(NSRect)rect ofDividerAtIndex:(NSInteger)idx {
    if (splitView == _horizontalBrowserSubSplitView) {
        return NSZeroRect;
    }
    return proposedRect;
}

#pragma mark - Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _libraryMenu) {
        [self updateLibraryMenu];
    } else if (menu == _headerMenu) {
        [self updateHeaderMenu];
    } else if (menu == _browserHeaderMenu) {
        [self updateBrowserHeaderMenu];
    } else {
        @throw NSInvalidArgumentException;
    }
}

@end
