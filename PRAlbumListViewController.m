#import "PRAlbumListViewController.h"
#import "PRBrowserViewController.h"
#import "PRSynchronizedScrollView.h"
#import "PRPlayer.h"
#import "PRDb.h"
#import "PRAlbumArtController.h"
#import "PRAlbumTableView2.h"
#import "PRAlbumListViewCell.h"
#import "NSIndexSet+Extensions.h"
#import "PRCore.h"


@implementation PRAlbumListViewController {
    PRSynchronizedScrollView *_artworkScrollView;
    PRAlbumTableView2 *_artworkTableView;
    
    int _libraryCount; // number of rows in libraryTableView
    NSMutableIndexSet *_tableIndexes; // rows in library table view which are filled
    NSArray *_albumCountArray; // array of album counts
    NSMutableArray *_albumSumCountArray; // array of sum of album counts
    
    NSCache *_cachedArtwork;
}

// #pragma mark - Initialization

// - (id)initWithCore:(PRCore *)core {
//     if (!(self = [super initWithCore:core])) {return nil;}
//     _core = core;
//     _db = [core db];
//     _now = [core now];
//     _refreshing = NO;
//     _updatingTableViewSelection = YES;
//     _currentList = nil;
    
//     _cachedArtwork = [[NSCache alloc] init];
//     [_cachedArtwork setCountLimit:50];
//     return self;
// }

// - (void)loadView {
//     _detailView = [[NSView alloc] init];
    
//     _artworkScrollView = [[PRSynchronizedScrollView alloc] init];
//     [_artworkScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
//     [_detailView addSubview:_artworkScrollView];
    
//     _artworkTableView = [[PRAlbumTableView2 alloc] initWithFrame:[_artworkScrollView bounds]];
//     [_artworkTableView setFocusRingType:NSFocusRingTypeNone];
//     [_artworkTableView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.93 alpha:1.0]];
//     [_artworkTableView setDataSource:self];
//     [_artworkTableView setDelegate:self];
//     [_artworkTableView setTarget:self];
//     [_artworkTableView setAction:@selector(selectAlbum)];
//     [_artworkTableView setDoubleAction:@selector(playAlbum)];
//     [_artworkScrollView setDocumentView:_artworkTableView];
    
//     NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"0"];
//     [[column headerCell] setStringValue:@"Album by Artist"];
//     [column setResizingMask:NSTableColumnAutoresizingMask];
//     [column setEditable:NO];
//     [column setDataCell:[[PRAlbumListViewCell alloc] init]];
//     [_artworkTableView addTableColumn:column];
    
//     _detailScrollView = [[PRSynchronizedScrollView alloc] init];
//     [_detailScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
//     [_detailScrollView setHasVerticalScroller:YES];
//     [_detailScrollView setHasHorizontalScroller:YES];
//     [_detailView addSubview:_detailScrollView];
    
//     _detailTableView = [[PRAlbumTableView alloc] initWithFrame:[_detailScrollView bounds]];
//     [_detailTableView setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
//     [_detailTableView setUsesAlternatingRowBackgroundColors:YES];
//     [_detailTableView setFocusRingType:NSFocusRingTypeNone];
//     [_detailTableView setTarget:self];
//     [_detailTableView setDoubleAction:@selector(play)];
//     [_detailTableView registerForDraggedTypes:@[PRFilePboardType]];
//     [_detailTableView setVerticalMotionCanBeginDrag:NO];
//     [_detailTableView setAllowsMultipleSelection:YES];
//     [_detailTableView setDataSource:self];
//     [_detailTableView setDelegate:self];
//     [_detailScrollView setDocumentView:_detailTableView];
//     [_artworkTableView setActualResponder:_detailTableView];
    
//     NSDictionary *views = @{@"v1":_artworkScrollView, @"v2":_detailScrollView};
//     [_detailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v1(174)][v2]|" options:0 metrics:nil views:views]];
//     [_detailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v1]|" options:0 metrics:nil views:views]];
//     [_detailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v2]|" options:0 metrics:nil views:views]];
    
//     [super loadView];
    
//     [[_artworkTableView headerView] setMenu:_headerMenu];
    
//     [(PRSynchronizedScrollView *)_detailScrollView setSynchronizedScrollView:_artworkScrollView];
//     [_artworkScrollView setSynchronizedScrollView:_detailScrollView];
// }

// #pragma mark - Accessors

// - (PRItemAttr *)sortAttr {
//     return [[_db playlists] albumListViewSortAttrForList:_currentList];
// }

// - (void)setSortAttr:(NSString *)attr {
//     [[_db playlists] setAlbumListViewSortAttr:attr forList:_currentList];
// }

// - (BOOL)ascending {
//     return [[_db playlists] albumListViewAscendingForList:_currentList];
// }

// - (void)setAscending:(BOOL)ascending {
//     [[_db playlists] setAlbumListViewAscending:ascending forList:_currentList];
// }

// #pragma mark - Update

// - (void)reloadData:(BOOL)force {
//     @autoreleasepool {
//         // update libSrc
//         int tables = [[_db libraryViewSource] refreshWithList:_currentList force:force];

//         // update albumCountArray, tableIndexes & libraryCount
//         _libraryCount = 0;
//         _albumCountArray = [[_db libraryViewSource] albumCounts];
//         _tableIndexes = [NSMutableIndexSet indexSet];
//         for (NSNumber *i in _albumCountArray) {
//             [_tableIndexes addIndexesInRange:NSMakeRange(_libraryCount, [i intValue])];
//             if ([i intValue] < 10) {
//                 _libraryCount += 10 + 1;
//             } else {
//                 _libraryCount += [i intValue] + 1;
//             }
//         }
        
//         // update albumSumCountArray
//         int count = 0;
//         _albumSumCountArray = [[NSMutableArray alloc] initWithArray:_albumCountArray];
//         for (int i = 0; i < [_albumSumCountArray count]; i++) {
//             count = count + [[_albumSumCountArray objectAtIndex:i] intValue];
//             [_albumSumCountArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:count]];
//         }
            
//         // update cachedArt
//         if (force) {
//             [_cachedArtwork removeAllObjects];
//         }
        
//         // reload tables
//         _updatingTableViewSelection = NO;
//         if ((tables & PRLibraryView) == PRLibraryView) {
//             [_detailTableView reloadData];
//             [_artworkTableView reloadData];
//         }
//         if ((tables & PRBrowser1View) == PRBrowser1View) {
//             [_browser1TableView reloadData];
//         }
//         if ((tables & PRBrowser2View) == PRBrowser2View) {    
//             [_browser2TableView reloadData];
//         }
//         if ((tables & PRBrowser3View) == PRBrowser3View) {
//             [_browser3TableView reloadData];
//         }
//         [_browser1TableView selectRowIndexes:[[_db libraryViewSource] selectionForBrowser:1] byExtendingSelection:NO];
//         [_browser2TableView selectRowIndexes:[[_db libraryViewSource] selectionForBrowser:2] byExtendingSelection:NO];
//         [_browser3TableView selectRowIndexes:[[_db libraryViewSource] selectionForBrowser:3] byExtendingSelection:NO];
//         _updatingTableViewSelection = YES;

//         [NSNotificationCenter post:PRLibraryViewSelectionDidChangeNotification];
//     }
// }

// #pragma mark - Action

// - (void)selectAlbum {
//     if ([_artworkTableView clickedRow] == -1) {
//         [_detailTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
//         return;
//     }    
//     int row = [_artworkTableView clickedRow];
//     NSRect rectOfRow = [_artworkTableView rectOfRow:row];
//     NSPoint point = rectOfRow.origin;
//     point.x += rectOfRow.size.width + 5;
//     int rowAtPoint = [_detailTableView rowAtPoint:point];
//     [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowAtPoint] byExtendingSelection:NO];
// }

// - (void)playAlbum {
//     if ([_artworkTableView clickedRow] == -1) {
//         return;
//     }
//     [_now stop];
//     [[_db playlists] clearList:[_now currentList]];
    
//     int currentIndex;
//     int row = [_artworkTableView clickedRow];
//     if (row == 0) {
//         currentIndex = 0;
//     } else {
//         currentIndex = [[_albumSumCountArray objectAtIndex:(row - 1)] intValue];
//     }
//     int maxIndex = currentIndex + [[_albumCountArray objectAtIndex:row] intValue];
    
//     for (; currentIndex < maxIndex; currentIndex++) {
//         PRItem *item = [[_db libraryViewSource] itemForRow:currentIndex + 1];
//         [[_db playlists] appendItem:item toList:[_now currentList]];
//     }
    
//     [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_now currentList]];
//     [_now playItemAtIndex:1];
// }

// #pragma mark - UI Priv

// - (NSArray *)columnInfo {
//     return [[_db playlists] albumListViewInfoForList:_currentList];
// }

// - (void)setColumnInfo:(NSArray *)columnInfo {
//     [[_db playlists] setAlbumListViewInfo:columnInfo forList:_currentList];
// }

// - (NSTableColumn *)tableColumnForAttr:(NSString *)attr {
//     if ([attr isEqual:PRListSortArtistAlbum]) {
//         return [_artworkTableView tableColumnWithIdentifier:@"0"];
//     } else {
//         return [super tableColumnForAttr:attr];
//     }
// }

// - (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending {
//     // clear indicator and higlighted column image
//     for (NSTableColumn *i in [_detailTableView tableColumns]) {
//         [_detailTableView setIndicatorImage:nil inTableColumn:i];
//     }
//     for (NSTableColumn *i in [_artworkTableView tableColumns]) {
//         [_artworkTableView setIndicatorImage:nil inTableColumn:i];
//     }
//     [_detailTableView setHighlightedTableColumn:nil];
//     [_artworkTableView setHighlightedTableColumn:nil];
    
//     // set highlighted column
//     NSTableView *tableView = [tableColumn tableView];
//     [tableView setHighlightedTableColumn:tableColumn];
    
//     // set indicator image
//     NSImage *indicatorImage;
//     if (ascending) {
//         indicatorImage = [NSImage imageNamed:@"NSAscendingSortIndicator"];
//     } else {
//         indicatorImage = [NSImage imageNamed:@"NSDescendingSortIndicator"];
//     }
//     [tableView setIndicatorImage:indicatorImage inTableColumn:tableColumn];    
// }

// #pragma mark - TableView DataSource

// - (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {    
//     if (tableView == _detailTableView) {
//         return _libraryCount;
//     } else if (tableView == _artworkTableView) {
//         return [_albumCountArray count];
//     } else {
//         return [super numberOfRowsInTableView:tableView];
//     }
// }

// - (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)tableRow {
//     if (tableView == _artworkTableView) {
//         int dbRow = [[_albumSumCountArray objectAtIndex:tableRow] intValue];
//         PRItem *item = [[_db libraryViewSource] itemForRow:dbRow];
        
//         NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//         [dict setObject:_db forKey:@"db"];
//         [dict setObject:item forKey:@"file"];
//         [dict setObject:[NSImage imageNamed:@"PRLightAlbumArt"] forKey:@"icon"];
                
//         // asynchronous drawing
//         NSImage *icon = [_cachedArtwork objectForKey:item];
//         if (icon) {
//             [dict setObject:icon forKey:@"icon"];
//         } else {
//             NSMutableArray *items = [NSMutableArray array];
//             for (int i = dbRow - [[_albumCountArray objectAtIndex:tableRow] intValue] + 1; i < dbRow + 1; i++) {
//                 [items addObject:[[_db libraryViewSource] itemForRow:i]];
//             }
//             NSDictionary *artworkInfo = [[_db albumArtController] artworkInfoForItems:items];
//             NSRect dirtyRect = [_artworkTableView rectOfRow:tableRow];            
//             [[NSOperationQueue backgroundQueue] addBlock:^{[self cacheArtworkForItem:item artworkInfo:artworkInfo dirtyRect:dirtyRect];}];
//         }
//         return dict;
//     } else {
//         return [super tableView:tableView objectValueForTableColumn:tableColumn row:tableRow];
//     }
// }

// - (void)cacheArtworkForItem:(PRItem *)item artworkInfo:(NSDictionary *)artworkInfo dirtyRect:(NSRect)dirtyRect {
//     @autoreleasepool {
//         NSImage *icon = [[_db albumArtController] artworkForArtworkInfo:artworkInfo];;    
//         if (!icon) {
//             icon = [NSImage imageNamed:@"PRLightAlbumArt"];
//         }
//         [_cachedArtwork setObject:icon forKey:item];
        
//         [[NSOperationQueue mainQueue] addBlock:^{[_artworkTableView setNeedsDisplayInRect:dirtyRect];}];
//     }
// }

// #pragma mark - TableView DragAndDrop

// - (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
//     NSInteger currentIndex = 0;
//     NSMutableArray *files = [NSMutableArray array];
//     if (tableView == _artworkTableView) {
//         int row = [rowIndexes firstIndex];
//         if (row == 0) {
//             currentIndex = 0;
//         } else {
//             currentIndex = [[_albumSumCountArray objectAtIndex:(row - 1)] intValue];
//         }
//         int maxIndex = currentIndex + [[_albumCountArray objectAtIndex:row] intValue];
        
//         for (; currentIndex < maxIndex; currentIndex++) {
//             [files addObject:[[_db libraryViewSource] itemForRow:currentIndex + 1]];
//         }
        
//         // archive files and save to pasteboard
//         if ([files count] == 0) {
//             return NO;
//         }
//         NSData *data = [NSKeyedArchiver archivedDataWithRootObject:files];
//         [pboard declareTypes:@[PRFilePboardType] owner:self];
//         [pboard setData:data forType:PRFilePboardType];
//         return YES;
//     } else if (tableView == _detailTableView) {
//         if ([self dbRowForTableRow:[rowIndexes firstIndex]] == -1) {
//             return NO;
//         }
//         return [super tableView:tableView writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
//     }
//     return [super tableView:tableView writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
// }

// - (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
//     return NSDragOperationNone;
// }

// #pragma mark - TableView Delegate

// - (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
//     if (tableView == _artworkTableView) {
//         if ([[self sortAttr] isEqual:PRListSortArtistAlbum]) {
//             [self setAscending:[self ascending]];
//         } else {
//             [self setAscending:YES];
//         }
//         [self setSortAttr:PRListSortArtistAlbum];
//         [self loadTableColumns];
//         [self reloadData:NO];
//         [tableView selectColumnIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
//         return;
//     }
//     [super tableView:tableView didClickTableColumn:tableColumn];
// }

// - (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
//     if (tableView == _artworkTableView) {
//         if ([[_albumCountArray objectAtIndex:row] intValue] < 10) {
//             return (19 * 11) - 2; 
//         } else {
//             return 19 * ([[_albumCountArray objectAtIndex:row] intValue] + 1) - 2; 
//         }
//     } else {
//         return 17;
//     }
// }

// - (void)tableViewSelectionDidChange:(NSNotification *)notification {
//     if ([notification object] == _detailTableView) {
//         int index = 0;
//         NSMutableIndexSet *selectionIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:[_detailTableView selectedRowIndexes]];
//         while ([selectionIndexes indexGreaterThanOrEqualToIndex:index] != NSNotFound) {
//             if ([self dbRowForTableRow:index] == -1) {
//                 [selectionIndexes removeIndex:index];
//             }
//             index++;
//         }
//         [_detailTableView selectRowIndexes:selectionIndexes byExtendingSelection:NO];
//     }
//     [super tableViewSelectionDidChange:notification];
// }

// - (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)indexes {
//     if (tableView == _artworkTableView) {
//         return [NSIndexSet indexSet];
//     }
//     return [super tableView:tableView selectionIndexesForProposedSelection:indexes];
// }

// - (int)dbRowForTableRow:(int)tableRow {
//     if (![_tableIndexes containsIndex:tableRow]) {
//         return -1;
//     }
//     return [_tableIndexes countOfIndexesInRange:NSMakeRange(0, tableRow + 1)];
// }

// - (int)tableRowForDbRow:(int)dbRow {
//     NSInteger tableRow = [_tableIndexes indexAtPosition:dbRow-1];
//     if (tableRow == NSNotFound) {
//         return -1;
//     }
//     return tableRow;
// }

// - (BOOL)shouldDrawGridForRow:(int)row tableView:(NSTableView *)tableView {
//     if (tableView == _detailTableView) {
//         return ([self dbRowForTableRow:row + 1] != -1 && [self dbRowForTableRow:row] == -1);
//     } else if (tableView == _artworkTableView) {
//         return (row + 1) != [self numberOfRowsInTableView:_artworkTableView];
//     } else {
//         return NO;
//     }
// }

@end
