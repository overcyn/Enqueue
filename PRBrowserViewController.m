#import "PRBrowserViewController.h"
#import "NSColor+Extensions.h"
#import "NSMenuItem+Extensions.h"
#import "NSString+Extensions.h"
#import "NSTableView+Extensions.h"
#import "PRAction.h"
#import "PRActionCenter.h"
#import "PRBitRateFormatter.h"
#import "PRBrowseView.h"
#import "PRBrowserListViewController.h"
#import "PRCenteredTextFieldCell.h"
#import "PRConnection.h"
#import "PRCore.h"
#import "PRDateFormatter.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRKindFormatter.h"
#import "PRLibrary.h"
#import "PRLibraryDescription.h"
#import "PRLibraryViewController.h"
#import "PRLibraryViewSource.h"
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
#import "PRTableView.h"
#import "PRTagger.h"
#import "PRTimeFormatter.h"
#import "sqlite_str.h"
#import "PRListDescription.h"

@interface PRBrowserViewController () <PRBrowseViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, PRTableViewDelegate, PRBrowserListViewController>
@end

@implementation PRBrowserViewController {
    __weak PRCore *_core;
    __weak PRDb *_db;
    __weak PRNowPlayingController *_now;
    
    PRTableView *_detailTableView;
    NSView *_detailView;
    NSScrollView *_detailScrollView;
    
    PRBrowserListViewController *_browser1ListVC;
    PRBrowserListViewController *_browser2ListVC;
    PRBrowserListViewController *_browser3ListVC;
    
    NSMenu *_libraryMenu;
    NSMenu *_headerMenu;
    
    PRList *_currentList;
    BOOL _updatingTableViewSelection; // YES during reloadData: so tableViewSelectionDidChange doesn't trigger
    BOOL _refreshing;
    
    BOOL _lastLibraryTypeSelectFailure; // Optimization for type select. YES if last search was unsuccessful.
    
    PRListDescription *_listDescription;
    PRLibraryDescription *_libraryDescription;
    NSArray *_browserDescriptions;
}

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _now = [core now];
    _db = [core db];
    _refreshing = NO;
    _updatingTableViewSelection = YES;
    _currentList = nil;
    return self;
}

- (void)loadView {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    [scrollView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    _detailView = scrollView;
    
    _detailTableView = [[PRTableView alloc] initWithFrame:[scrollView bounds]];
    [_detailTableView setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
    [_detailTableView setUsesAlternatingRowBackgroundColors:YES];
    [_detailTableView setFocusRingType:NSFocusRingTypeNone];
    [_detailTableView setTarget:self];
    [_detailTableView setDoubleAction:@selector(play)];
    [_detailTableView registerForDraggedTypes:@[PRFilePboardType]];
    [_detailTableView setVerticalMotionCanBeginDrag:NO];
    [_detailTableView setAllowsMultipleSelection:YES];
    [_detailTableView setDataSource:self];
    [_detailTableView setDelegate:self];
    [scrollView setDocumentView:_detailTableView];
    
    PRBrowseView *view = [[PRBrowseView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
    [view setDelegate:self];
    [self setView:view];
        
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
    [[tableColumn headerCell] setStringValue:@"Track"];
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
    
    // Browsers
    _browser1ListVC = [[PRBrowserListViewController alloc] init];
    [_browser1ListVC setDelegate:self];
    _browser2ListVC = [[PRBrowserListViewController alloc] init];
    [_browser2ListVC setDelegate:self];
    _browser3ListVC = [[PRBrowserListViewController alloc] init];
    [_browser3ListVC setDelegate:self];
        
    // Key Views
    [[self firstKeyView] setNextKeyView:[_browser1ListVC view]];
    [[_browser1ListVC view] setNextKeyView:[_browser2ListVC view]];
    [[_browser2ListVC view] setNextKeyView:[_browser3ListVC view]];
    [[_browser3ListVC view] setNextKeyView:_detailTableView];
    [_detailTableView setNextKeyView:[self lastKeyView]];
    
    // Update
    [[NSNotificationCenter defaultCenter] observeLibraryChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(tagsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeUseAlbumArtistChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistFilesChanged:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(playingFileChanged:)];
}

#pragma mark - API

- (NSMenu *)browserHeaderMenu {
    return nil;
}

#pragma mark - Accessors

- (PRList *)currentList {
    return _currentList;
}

- (void)setCurrentList:(PRList *)list {
    _currentList = list;
    
    if (list) {
        [self reloadData:YES];
        [self loadTableColumns];
        [self loadBrowser];
        [_detailTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [_detailTableView scrollRowToVisiblePretty:0];
        [_browser1ListVC scrollToSelectedRow];
        [_browser2ListVC scrollToSelectedRow];
        [_browser3ListVC scrollToSelectedRow];
    }
}

- (NSDictionary *)info {
    return [_libraryDescription info];
}

- (NSArray *)selection {
    NSMutableArray *selectionArray = [NSMutableArray array];
    [[_detailTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [selectionArray addObject:[_libraryDescription itemForRow:idx]];
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
        artist = PRCompilationString;
    } else {
        artist = [[_db library] artistValueForItem:item];
    }
    [self browseToArtist:artist];
    
    NSInteger row = [_libraryDescription rowForItem:item];
    if (row != -1) {
        [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [_detailTableView scrollRowToVisiblePretty:row];
    }
}

- (void)highlightFiles:(NSArray *)items {
    NSMutableIndexSet *rows = [NSMutableIndexSet indexSet];
    for (NSNumber *i in items) {
        NSInteger row = [_libraryDescription rowForItem:i];
        if (row == -1) {
            [rows removeAllIndexes];
            break;
        }
        [rows addIndex:row];
    }
    if ([rows count] == 0) {
        [[_db playlists] setSearch:@"" forList:_currentList];
        [[_db playlists] setSelection:@[] forBrowser:1 list:_currentList];
        [[_db playlists] setSelection:@[] forBrowser:2 list:_currentList];
        [[_db playlists] setSelection:@[] forBrowser:3 list:_currentList];
        [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
        
        for (NSNumber *i in items) {
            NSInteger row = [_libraryDescription rowForItem:i];
            if (row != -1) {
                [rows addIndex:row];
            }
        }
    }
    if ([rows count] > 0) {
        [_detailTableView selectRowIndexes:rows byExtendingSelection:NO];
        [_detailTableView scrollRowToVisiblePretty:[rows firstIndex]];
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
    NSInteger row = [_libraryDescription firstRowWithValue:artist forAttr:attr];
    if (row == -1) {
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
    [_browser1ListVC scrollToSelectedRow];
    [_browser2ListVC scrollToSelectedRow];
    [_browser3ListVC scrollToSelectedRow];
}

#pragma mark - Action Priv

- (void)play {
    NSIndexSet *indexes = [_detailTableView selectedRowIndexes];
    NSInteger clickedRow = [_detailTableView clickedRow];
    if ([indexes count] > 1) {
        [self playIndexes:indexes];
    } else if ([indexes count] == 1){
        NSMutableArray *items = [NSMutableArray array];
        for (NSInteger i = 0; i < [_libraryDescription count]; i++) {
            [items addObject:[_libraryDescription itemForRow:i]];
        }
        PRPlayItemsAction *action = [[PRPlayItemsAction alloc] init];
        [action setIndex:clickedRow];
        [action setItems:items];
        [PRActionCenter performAction:action];
    }
}

- (void)playIndexes:(NSIndexSet *)indexes {
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
        [items addObject:[_libraryDescription itemForRow:i]];
    }];
    
    PRPlayItemsAction *action = [[PRPlayItemsAction alloc] init];
    [action setItems:items];
    [PRActionCenter performAction:action];
}

- (void)appendIndexes:(NSIndexSet *)indexes {
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
        [items addObject:[_libraryDescription itemForRow:i]];
    }];
    
    PRAddItemsToListAction *action = [[PRAddItemsToListAction alloc] init];
    [action setItems:items];
    [action setIndex:-1];
    [PRActionCenter performAction:action];
}

- (void)appendNextIndexes:(NSIndexSet *)indexes {
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
        [items addObject:[_libraryDescription itemForRow:i]];
    }];
    
    PRAddItemsToListAction *action = [[PRAddItemsToListAction alloc] init];
    [action setItems:items];
    [action setIndex:-2];
    [PRActionCenter performAction:action];
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
    NSMutableArray *items = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
        [items addObject:[_libraryDescription itemForRow:i]];
    }];
    
    PRAddItemsToListAction *action = [[PRAddItemsToListAction alloc] init];
    [action setItems:items];
    [action setIndex:-1];
    [action setList:list];
    [PRActionCenter performAction:action];
}

- (void)revealIndexes:(NSIndexSet *)indexes {
    // int row = [indexes indexGreaterThanOrEqualToIndex:0];
    // PRItem *item = [[_db libraryViewSource] itemForRow:[self dbRowForTableRow:row]];
    // [[NSWorkspace sharedWorkspace] selectFile:[[[_db library] URLForItem:item] path] inFileViewerRootedAtPath:nil];
}

- (void)deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    // NSIndexSet *indexes = (__bridge_transfer NSIndexSet *)contextInfo;
    // if (returnCode != NSAlertFirstButtonReturn) {
    //     return;
    // }
    // NSMutableArray *items = [NSMutableArray array];
    // [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    //     [items addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];
    // }];
    // if ([items containsObject:[_now currentItem]]) {
    //     [_now stop];
    // }
    // [[_db library] removeItems:items];
    // [[NSNotificationCenter defaultCenter] postLibraryChanged];
    // [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_now currentList]];
    // [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];    
}

- (void)appendAll {
    [self appendIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:_detailTableView])]];
}

- (void)appendNextAll {
    [self appendNextIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfRowsInTableView:_detailTableView])]];
}

#pragma mark - Setup

- (void)reloadData:(BOOL)force {
    PRLibraryDescription *libraryDescriptions = nil;
    BOOL success = [[[_core conn] playlists] zLibraryDescriptionForList:_currentList out:&libraryDescriptions];
    _libraryDescription = libraryDescriptions;
    
    NSArray *browserDescriptions = nil;
    success = [[[_core conn] playlists] zBrowserDescriptionsForList:_currentList out:&browserDescriptions];
    _browserDescriptions = browserDescriptions;
    
    PRListDescription *listDescription = nil;
    success = [[[_core conn] playlists] zListDescriptionForList:_currentList out:&listDescription];
    _listDescription = listDescription;
    
    [_detailTableView reloadData];
    [_browser1ListVC setBrowserDescription:_browserDescriptions[0]];
    [_browser2ListVC setBrowserDescription:_browserDescriptions[1]];
    [_browser3ListVC setBrowserDescription:_browserDescriptions[2]];
    
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
    [_browser1ListVC scrollToSelectedRow];
    [_browser2ListVC scrollToSelectedRow];
    [_browser3ListVC scrollToSelectedRow];
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
    
    PRBrowseView *view = (PRBrowseView *)[self view];
    [view setDetailView:_detailView];
    
    int browserPosition = [[_db playlists] verticalForList:_currentList];
    if (browserPosition == PRBrowserPositionVertical) {
        [view setStyle:PRBrowseViewStyleVertical];
        [view setBrowseViews:@[[_browser3ListVC view]]];
        [view setDividerPosition:[[_db playlists] verticalBrowserWidthForList:_currentList]];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [view setStyle:PRBrowseViewStyleHorizontal];
        NSArray *browseViews = nil;
        if (![[_db playlists] attrForBrowser:2 list:_currentList]) {
            browseViews = @[[_browser3ListVC view]];
        } else if (![[_db playlists] attrForBrowser:1 list:_currentList]) {
            browseViews = @[[_browser2ListVC view], [_browser3ListVC view]];
        } else {
            browseViews = @[[_browser1ListVC view], [_browser2ListVC view], [_browser3ListVC view]];
        }
        [view setBrowseViews:browseViews];
        [view setDividerPosition:[[_db playlists] horizontalBrowserHeightForList:_currentList]];
    } else if (browserPosition == PRBrowserPositionHidden){
        [view setStyle:PRBrowseViewStyleNone];
    }
    _refreshing = NO;
}

- (void)saveBrowser {
    if (!_currentList) {
        return;
    }
    int browserPosition = [[_db playlists] verticalForList:_currentList];
    float width = [(PRBrowseView *)[self view] dividerPosition];
    if (browserPosition == PRBrowserPositionVertical) {
        [[_db playlists] setVerticalBrowserWidth:width forList:_currentList];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [[_db playlists] setHorizontalBrowserHeight:width forList:_currentList];
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

#pragma mark - Menu Priv

- (void)updateLibraryMenu {
    if ([_detailTableView clickedRow] == -1) {
        return;
    }
    for (NSMenuItem *i in [_libraryMenu itemArray]) {
        [_libraryMenu removeItem:i];
    }
    __weak PRBrowserViewController *weakSelf = self;
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
    __weak PRBrowserViewController *weakSelf = self;
    
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

#pragma mark - PRBrowseViewDelegate

- (void)browseViewDidChangeDividerPosition:(PRBrowseView *)view {
    [self saveBrowser];
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_libraryDescription count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    PRItemAttr *attr = [tableColumn identifier];
    if ([attr isEqual:PRListSortIndex]) {
        // PRItem *item = [[_db libraryViewSource] itemForRow:rowIndex];
        // if ([[self sortAttr] isEqual:PRListSortIndex]) {
        //     if ([self ascending]) {
        //         return [NSNumber numberWithInt:rowIndex];
        //     } else {
        //         return [NSNumber numberWithInt:[self numberOfRowsInTableView:_detailTableView] - rowIndex + 1];
        //     } 
        // } else {
        //     NSIndexSet *rows = [[_db playlists] indexesOfItem:item inList:_currentList];
        //     return [NSNumber numberWithInt:[rows firstIndex]];
        // }
    } else {
        id value = [_libraryDescription valueForRow:rowIndex attribute:attr andCacheAttributes:^{return [self attributesToCache];}];
        if ([attr isEqual:PRItemAttrRating]) {
            value = @(floor([value intValue] / 20));
        } else if ([attr isEqual:PRItemAttrPath]) {
            value = [[NSURL URLWithString:value] path];
        } else if ([attr isEqual:PRItemAttrTrackNumber]) {
            if ([[_libraryDescription itemForRow:rowIndex] isEqual:[_now currentItem]]) {
                value = [NSString stringWithFormat:@"◈"];
            }
        }
        return value;
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    // PRItemAttr *attr = [tableColumn identifier];
    // if ([self dbRowForTableRow:rowIndex] != -1) {
    //     PRItem *item = [[_db libraryViewSource] itemForRow:[self dbRowForTableRow:rowIndex]];
    //     if ([attr isEqualToString:PRItemAttrRating]) {
    //         int rating = [object intValue] * 20;
    //         [[_db library] setValue:[NSNumber numberWithInt:rating] forItem:item attr:PRItemAttrRating];
    //     } else {
    //         [PRTagger setTag:object forAttribute:attr URL:[[_db library] URLForItem:item]];
    //         [PRTagger updateTagsForItem:item database:_db];
    //     }
    //     [[NSNotificationCenter defaultCenter] postItemsChanged:@[item]];
    // }
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
    // [pboard declareTypes:@[PRFilePboardType, PRIndexesPboardType] owner:self];
    
    // // PRFilePboardType
    // NSInteger currentIndex = 0;
    // NSMutableArray *files = [NSMutableArray array];
    //     // If dragging from library, get selected files
    //     while ((currentIndex = [rowIndexes indexGreaterThanOrEqualToIndex:currentIndex]) != NSNotFound) {
    //         if ([self dbRowForTableRow:currentIndex] != -1) {
    //             [files addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:currentIndex]]];
    //         }
    //         currentIndex++;
    //     }
    
    // // PRIndexesPboardType
    // NSIndexSet *indexes = [NSIndexSet indexSet];
    // if (tableView == _detailTableView && [[self sortAttr] isEqual:PRListSortIndex]) {
    //     indexes = [[NSIndexSet alloc] initWithIndexSet:[self dbRowIndexesForTableRowIndexes:rowIndexes]];
    // }
    
    // // Write to Pboard
    // [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:files]
    //         forType:PRFilePboardType];
    // [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:indexes]
    //         forType:PRIndexesPboardType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    // NSPasteboard *pasteboard = [info draggingPasteboard];
    // NSData *indexesData = [pasteboard dataForType:PRIndexesPboardType];
    // NSIndexSet *indexes;
    // if (indexesData) {
    //     indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexesData];
    // } else {
    //     indexes = [NSIndexSet indexSet];
    // }
    
    // NSIndexSet *indexSet1 = [[_db libraryViewSource] selectionForBrowser:1];
    // NSIndexSet *indexSet2 = [[_db libraryViewSource] selectionForBrowser:2];
    // NSIndexSet *indexSet3 = [[_db libraryViewSource] selectionForBrowser:3];
    
    // if (tableView == _detailTableView && 
    //     op == NSTableViewDropAbove && 
    //     ![[[_db playlists] typeForList:_currentList] isEqual:PRListTypeLibrary] && 
    //     [indexes count] != 0 && 
    //     [indexSet1 firstIndex] == 0 &&
    //     [indexSet2 firstIndex] == 0 &&
    //     [indexSet3 firstIndex] == 0) {
    //     return NSDragOperationEvery;
    // }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView  *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    // NSPasteboard *pboard = [info draggingPasteboard];    
    // if ([info draggingSource] != _detailTableView) {
    //     return NO;
    // }
    // NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:PRIndexesPboardType]];
    
    // // get move row
    // PRListItem *listItem = [[_db playlists] listItemAtIndex:[indexes firstIndex] inList:_currentList];
                   
    // int row2 = [self dbRowForTableRow:row];
    // [[_db playlists] moveItemsAtIndexes:indexes toIndex:row2 inList:_currentList];
    // [[NSNotificationCenter defaultCenter] postListItemsDidChange:_currentList];
    
    // // select
    // int index = [[_db playlists] indexForListItem:listItem];
    // NSIndexSet *indexesToSelect = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([self tableRowForDbRow:index], [indexes count])];
    // [_detailTableView selectRowIndexes:indexesToSelect byExtendingSelection:NO];
    return YES;
}

// - (NSInteger)tableView:(NSTableView *)tableView nextTypeSelectMatchFromRow:(NSInteger)startRow toRow:(NSInteger)endRow forString:(NSString *)string {
//     // forward event if space-key so window can play/pause
//     if ([string isEqualToString:@" "]) {
//         return -1;
//     }
//     // if last search was unsuccessful don't search again
//     if (_lastLibraryTypeSelectFailure && [string length] > 1) {
//         return startRow;
//     }
    
//     NSTableColumn *column;
//     if (tableView == _browser1TableView || tableView == _browser2TableView || tableView == _browser3TableView) {
//         column = [[tableView tableColumns] objectAtIndex:0];
//     } else {
//         column = [tableView tableColumnWithIdentifier:PRItemAttrTitle];
//     }
//     // endRow can be before startRow so account for loop around
//     int end = !(endRow < startRow) ? endRow : [self numberOfRowsInTableView:tableView] - 1;
//     for (int i = startRow; i <= end; i++) {
//         NSString *value = [self tableView:tableView objectValueForTableColumn:column row:i];
//         if ([value noCaseBegins:string]) {
//             _lastLibraryTypeSelectFailure = NO;
//             return i;
//         }
//         if (i == end && endRow < startRow && end != endRow) {
//             i = -1;
//             end = endRow;
//         }
//     }
//     _lastLibraryTypeSelectFailure = YES;
//     return startRow;
// }

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
    return !([[[_db playlists] typeForList:_currentList] isEqual:PRListTypeStatic] && columnIndex == 0);
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
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
    [NSNotificationCenter post:PRLibraryViewSelectionDidChangeNotification];
}

- (void)tableViewColumnDidMove:(NSNotification *)notification {
    if (!_refreshing) {
        [self saveTableColumns];
    }
}

- (void)tableViewColumnDidResize:(NSNotification *)notification {
    if (!_refreshing) {
        [self saveTableColumns];
    }
}

#pragma mark - PRBrowserViewControllerDelegate

- (void)browserViewControllerDidChangeSelection:(PRBrowserListViewController *)browserVC {
    NSMutableArray *browserSelections = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        NSMutableArray *browserSelection = [NSMutableArray array];
        PRBrowserListViewController *browserVC = @[_browser1ListVC, _browser2ListVC, _browser3ListVC][i];
        PRBrowserDescription *browserDescription = [browserVC browserDescription];
        NSIndexSet *selectedIndexes = [browserVC selectedIndexes];
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger j, BOOL *stop){
            if (j != 0) {
               [browserSelection addObject:[browserDescription valueForRow:j]];
           }
        }];
        [browserSelections addObject:browserSelection];
    }
    [_listDescription setBrowserSelections:browserSelections];
    
    PRSetListDescriptionAction *action = [[PRSetListDescriptionAction alloc] init];
    [action setList:_currentList];
    [action setListDescription:_listDescription];
    [PRActionCenter performAction:action];
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
            [self deleteIndexes:[_detailTableView selectedRowIndexes]];
            didHandle = YES;
        } else if (c == 0xd) {
            [self playIndexes:[_detailTableView selectedRowIndexes]];
            didHandle = YES;
        }
    } else if (flags == NSShiftKeyMask) {
        if (c == 0xd) {
            [self appendIndexes:[_detailTableView selectedRowIndexes]];
            didHandle = YES;
        }
    } else if (flags == NSAlternateKeyMask) {
        if (c == 0xd) {
            [self appendNextIndexes:[_detailTableView selectedRowIndexes]];
            didHandle = YES;
        }
    }
    return didHandle;
}

#pragma mark - Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _libraryMenu) {
        [self updateLibraryMenu];
    } else if (menu == _headerMenu) {
        [self updateHeaderMenu];
    }
}

@end
