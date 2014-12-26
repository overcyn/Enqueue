#import "PRLibraryListViewController.h"
#import "PRActionCenter.h"
#import "NSTableView+Extensions.h"
#import "PRAction.h"
#import "PRBitRateFormatter.h"
#import "PRCenteredTextFieldCell.h"
#import "PRDateFormatter.h"
#import "PRKindFormatter.h"
#import "PRLibraryDescription.h"
#import "PRListDescription.h"
#import "PRNumberFormatter.h"
#import "PRRatingCell.h"
#import "PRSizeFormatter.h"
#import "PRStringFormatter.h"
#import "PRTableHeaderCell.h"
#import "PRTableView.h"
#import "PRTimeFormatter.h"

@interface PRLibraryListViewController () <NSMenuDelegate, NSTableViewDelegate, NSTableViewDataSource>
@end

@implementation PRLibraryListViewController {
    PRLibraryDescription *_libraryDescription;
    PRTableView *_tableView;
    NSMenu *_libraryMenu;
    NSMenu *_headerMenu;
    BOOL _refreshing;
    
    BOOL _lastLibraryTypeSelectFailure; // Optimization for type select. YES if last search was unsuccessful.
}

@synthesize libraryDescription = _libraryDescription;

#pragma mark - API

- (void)setLibraryDescription:(PRLibraryDescription *)value {
    _libraryDescription = value;
    [self _loadTableColumns];
    [_tableView reloadData];
}

- (NSArray *)selectedItems {
    NSMutableArray *items = [NSMutableArray array];
    [[_tableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [items addObject:[_libraryDescription itemForRow:idx]];
    }];
    return items;
}

#pragma mark - NSViewController

- (void)loadView {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    [self setView:scrollView];
    
    _tableView = [[PRTableView alloc] initWithFrame:[scrollView bounds]];
    [_tableView setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
    [_tableView setUsesAlternatingRowBackgroundColors:YES];
    [_tableView setFocusRingType:NSFocusRingTypeNone];
    [_tableView setTarget:self];
    [_tableView setDoubleAction:@selector(_doubleAction:)];
    [_tableView registerForDraggedTypes:@[PRFilePboardType]];
    [_tableView setVerticalMotionCanBeginDrag:NO];
    [_tableView setAllowsMultipleSelection:YES];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [scrollView setDocumentView:_tableView];
        
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
        [_tableView addTableColumn:i];
    }

    _libraryMenu = [[NSMenu alloc] init];
    [_libraryMenu setDelegate:self];
    [_tableView setMenu:_libraryMenu];

    _headerMenu = [[NSMenu alloc] init];
    [_headerMenu setDelegate:self];
    [[_tableView headerView] setMenu:_headerMenu];
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _libraryMenu) {
        [self _updateLibraryMenu];
    } else if (menu == _headerMenu) {
        [self _updateHeaderMenu];
    }
}

#pragma mark - NSTableViewDataSource

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
        //         return [NSNumber numberWithInt:[self numberOfRowsInTableView:_tableView] - rowIndex + 1];
        //     } 
        // } else {
        //     NSIndexSet *rows = [[_db playlists] indexesOfItem:item inList:_currentList];
        //     return [NSNumber numberWithInt:[rows firstIndex]];
        // }
    } else {
        id value = [_libraryDescription valueForRow:rowIndex attribute:attr andCacheAttributes:^{return [self _attributesToCache];}];
        if ([attr isEqual:PRItemAttrRating]) {
            value = @(floor([value intValue] / 20));
        } else if ([attr isEqual:PRItemAttrPath]) {
            value = [[NSURL URLWithString:value] path];
        } else if ([attr isEqual:PRItemAttrTrackNumber]) {
            // if ([[_libraryDescription itemForRow:rowIndex] isEqual:[_now currentItem]]) {
            //     value = [NSString stringWithFormat:@"◈"];
            // }
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
    // if (tableView == _tableView && [[self sortAttr] isEqual:PRListSortIndex]) {
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
    
    // if (tableView == _tableView && 
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
    // if ([info draggingSource] != _tableView) {
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
    // [_tableView selectRowIndexes:indexesToSelect byExtendingSelection:NO];
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

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)column {
    [tableView setAllowsColumnReordering:([[column identifier] intValue] != PRPlaylistIndexSort)];
}

- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex {
    return !([[[_libraryDescription listDescription] type] isEqual:PRListTypeStatic] && columnIndex == 0);
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    PRItemAttr *columnAttr = [tableColumn identifier];
    PRListDescription *listDescription = [_libraryDescription listDescription];
    if ([columnAttr isEqual:[listDescription listViewSortAttr]]) {
        [listDescription setListViewAscending:![listDescription listViewAscending]];
    } else {
        [listDescription setListViewSortAttr:columnAttr];
        [listDescription setListViewAscending:YES];
    }
    
    PRSetListDescriptionAction *action = [[PRSetListDescriptionAction alloc] init];
    [action setList:[_libraryDescription list]];
    [action setListDescription:[_libraryDescription listDescription]];
    [PRActionCenter performAction:action];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [NSNotificationCenter post:PRLibraryViewSelectionDidChangeNotification];
}

- (void)tableViewColumnDidMove:(NSNotification *)notification {
    if (!_refreshing) {
        [self _saveTableColumns];
    }
}

- (void)tableViewColumnDidResize:(NSNotification *)notification {
    if (!_refreshing) {
        [self _saveTableColumns];
    }
}

#pragma mark - PRTableViewDelegate

- (BOOL)tableView:(PRTableView *)tableView keyDown:(NSEvent *)event {
    if ([[event characters] length] != 1) {
        return NO;
    }
    BOOL didHandle = NO;
    NSUInteger flags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    UniChar c = [[event characters] characterAtIndex:0];
    if (flags == 0) {
        if (c == 0x7F || c == 0xf728) {
            [self _deleteAction:nil];
            didHandle = YES;
        } else if (c == 0xd) {
            [self _playAction:nil];
            didHandle = YES;
        }
    } else if (flags == NSShiftKeyMask) {
        if (c == 0xd) {
            [self _playNextAction:nil];
            didHandle = YES;
        }
    } else if (flags == NSAlternateKeyMask) {
        if (c == 0xd) {
            [self _appendAction:nil];
            didHandle = YES;
        }
    }
    return didHandle;
}

#pragma mark - Action

- (void)_doubleAction:(id)sender {
    NSIndexSet *indexes = [_tableView selectedRowIndexes];
    if ([indexes count] > 1) {
        PRPlayItemsAction *action = [[PRPlayItemsAction alloc] init];
        [action setItems:[self selectedItems]];
        [PRActionCenter performAction:action];
    } else if ([indexes count] == 1){
        NSMutableArray *items = [NSMutableArray array];
        for (NSInteger i = 0; i < [_libraryDescription count]; i++) {
            [items addObject:[_libraryDescription itemForRow:i]];
        }
        PRPlayItemsAction *action = [[PRPlayItemsAction alloc] init];
        [action setIndex:[_tableView clickedRow]];
        [action setItems:items];
        [PRActionCenter performAction:action];
    }
}

- (void)_playAction:(id)sender {
    PRPlayItemsAction *action = [[PRPlayItemsAction alloc] init];
    [action setItems:[self selectedItems]];
    [PRActionCenter performAction:action];
}

- (void)_playNextAction:(id)sender {
    PRAddItemsToListAction *action = [[PRAddItemsToListAction alloc] init];
    [action setItems:[self selectedItems]];
    [action setIndex:-1];
    [PRActionCenter performAction:action];
}

- (void)_appendAction:(id)sender {
    PRAddItemsToListAction *action = [[PRAddItemsToListAction alloc] init];
    [action setItems:[self selectedItems]];
    [action setIndex:-2];
    [PRActionCenter performAction:action];
}

- (void)_toggleColumnAction:(NSMenuItem *)sender {
    NSTableColumn *column = [sender representedObject];
    [column setHidden:![column isHidden]];
    [self _saveTableColumns];
}

- (void)_deleteAction:(id)sender {
    // if ([indexes count] == 0) {
    //     return;
    // }
    // if (![_currentList isEqual:[[_db playlists] libraryList]]) {
    //     NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
    //     NSTableColumn *tableColumn = [_tableView tableColumnWithIdentifier:PRListSortIndex];
    //     [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    //         [indexesToDelete addIndex:[[self tableView:_tableView objectValueForTableColumn:tableColumn row:idx] intValue]];
    //     }];
    //     [[_db playlists] removeItemsAtIndexes:indexesToDelete fromList:_currentList];
        
    //     [[NSNotificationCenter defaultCenter] postListItemsDidChange:_currentList];
    //     [_tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    // } else {
    //     NSString *message = @"Do you want to remove the selected song from your library?";
    //     if ([indexes count] != 1) {
    //         message = [NSString stringWithFormat:@"Do you want to remove the %lu selected songs from your library?", (unsigned long)[indexes count]];
    //     }
    //     NSAlert *alert = [[NSAlert alloc] init];
    //     [alert addButtonWithTitle:@"Remove"];
    //     [alert addButtonWithTitle:@"Cancel"];
    //     [alert setMessageText:message];
    //     [alert setInformativeText:@"These files will not be deleted from your computer"];
    //     [alert setAlertStyle:NSWarningAlertStyle];
    //     [alert beginSheetModalForWindow:[[self view] window] 
    //                       modalDelegate:self 
    //                      didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:)
    //                         contextInfo:(__bridge_retained void *)indexes];
    // }
}

- (void)_appendToListAction:(NSMenuItem *)sender {
    PRAddItemsToListAction *action = [[PRAddItemsToListAction alloc] init];
    [action setItems:[self selectedItems]];
    [action setIndex:-1];
    [action setList:[sender representedObject]];
    [PRActionCenter performAction:action];
}

#pragma mark - Internal

- (void)_loadTableColumns {
    _refreshing = YES;
    
    PRListDescription *listDescription = [_libraryDescription listDescription];
    NSArray *columnsInfo = [listDescription listViewInfo];
    for (NSInteger i = 0; i < [columnsInfo count]; i++) {
        NSDictionary *columnInfo = [columnsInfo objectAtIndex:i];
        NSTableColumn *tableColumn = [_tableView tableColumnWithIdentifier:[PRPlaylists sortAttrForInternal:[columnInfo valueForKey:@"identifier"]]];
        [tableColumn setWidth:[[columnInfo valueForKey:@"width"] intValue]];
        [tableColumn setHidden:[[columnInfo valueForKey:@"hidden"] boolValue]];
        [_tableView moveColumn:[[_tableView tableColumns] indexOfObject:tableColumn] toColumn:i];
    }
    
    NSTableColumn *tableColumn = [_tableView tableColumnWithIdentifier:PRListSortIndex];
    [tableColumn setHidden:![[listDescription type] isEqual:PRListTypeStatic]];
    [_tableView moveColumn:[[_tableView tableColumns] indexOfObject:tableColumn] toColumn:0];
    
    tableColumn = [_tableView tableColumnWithIdentifier:[listDescription listViewSortAttr]];
    [_tableView PRHighlightTableColumn:tableColumn ascending:[listDescription listViewAscending]];
    
    _refreshing = NO;
}

- (void)_saveTableColumns {
    NSMutableArray *columnsInfo = [NSMutableArray array];
    for (NSTableColumn *i in [_tableView tableColumns]) {
        if ([[i identifier] intValue] == PRPlaylistIndexSort) {
            continue;
        }
        [columnsInfo addObject:@{@"identifier":[PRPlaylists internalForSortAttr:[i identifier]], @"hidden":@([i isHidden]), @"width":@([i width])}];
    }
    [[_libraryDescription listDescription] setListViewInfo:columnsInfo];
}

- (void)_updateLibraryMenu {
    if ([_tableView clickedRow] != -1) {
        for (NSMenuItem *i in [_libraryMenu itemArray]) {
            [_libraryMenu removeItem:i];
        }
        
        // Play
        unichar c[1] = {NSCarriageReturnCharacter};
        NSMenuItem *item = [[NSMenuItem alloc] init];
        [item setTitle:@"Play"];
        [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
        [item setKeyEquivalentModifierMask:0];
        [item setTarget:self];
        [item setAction:@selector(_playAction:)];
        [_libraryMenu addItem:item];
        
        item = [[NSMenuItem alloc] init];
        [item setTitle:@"Play Next"];
        [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
        [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [item setTarget:self];
        [item setAction:@selector(_playNextAction:)];
        [_libraryMenu addItem:item];
        
        item = [[NSMenuItem alloc] init];
        [item setTitle:@"Append"];
        [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
        [item setKeyEquivalentModifierMask:NSShiftKeyMask];
        [item setTarget:self];
        [item setAction:@selector(_appendAction:)];
        [_libraryMenu addItem:item];
        [_libraryMenu addItem:[NSMenuItem separatorItem]];
        
        // // Add to Playlist
        // NSMenu *playlistMenu = [[NSMenu alloc] init];
        // for (PRList *i in [[_db playlists] lists]) {
        //     if (![[[_db playlists] typeForList:i] isEqual:PRListTypeStatic]) {
        //         continue;
        //     }
        //     item = [[NSMenuItem alloc] init];
        //     [item setTitle:[NSString stringWithFormat:@" %@",[[_db playlists] titleForList:i]]];
        //     [item setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        //     [item setActionBlock:^{[weakSelf appendIndexes:[weakSelf selectedIndexes] toList:i];}];
        //     [playlistMenu addItem:item];
        // }
        // NSMenuItem *playlistMenuItem = [[NSMenuItem alloc] init];
        // [playlistMenuItem setTitle:@"Add to Playlist"];
        // [playlistMenuItem setSubmenu:playlistMenu];
        // [_libraryMenu addItem:playlistMenuItem];
        // [_libraryMenu addItem:[NSMenuItem separatorItem]];
        
        // // Misc
        // item = [[NSMenuItem alloc] init];
        // [item setTitle:@"Reveal in Finder"];
        // [item setActionBlock:^{[weakSelf revealIndexes:[weakSelf selectedIndexes]];}];
        // [_libraryMenu addItem:item];
        // [_libraryMenu addItem:[NSMenuItem separatorItem]];
        
        // Delete
        PRListDescription *listDescription = [_libraryDescription listDescription];
        
        c[0] = NSDeleteCharacter;
        item = [[NSMenuItem alloc] init];
        [item setTitle:@"Delete"];
        if ([[listDescription type] isEqual:PRListTypeStatic]) {
            [item setTitle:@"Remove"];
        }
        [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
        [item setKeyEquivalentModifierMask:0];
        [item setTarget:self];
        [item setAction:@selector(_deleteAction:)];
        [_libraryMenu addItem:item];
    }
}

- (void)_updateHeaderMenu {
    for (NSMenuItem *i in [_headerMenu itemArray]) {
        [_headerMenu removeItem:i];
    }
    
    // NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    // [menuItem setTitle:@"Browser"];
    // [menuItem setSubmenu:[self browserHeaderMenu]];
    // [_headerMenu addItem:menuItem];
    // [_headerMenu addItem:[NSMenuItem separatorItem]];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"headerCell.stringValue" ascending:YES];
    NSArray *sortedTableColumns = [[_tableView tableColumns] sortedArrayUsingDescriptors:@[sortDescriptor]];
    for (NSTableColumn *i in sortedTableColumns) {
        if ([[i identifier] isEqual:PRListSortIndex]) {
            continue;
        }
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:[[i headerCell] stringValue]];
        if (![i isHidden]) {
            [menuItem setState:NSOnState];
        }
        [menuItem setTarget:self];
        [menuItem setAction:@selector(_toggleColumnAction:)];
        [menuItem setRepresentedObject:i];
        [_headerMenu addItem:menuItem];
    }
}

- (NSArray *)_attributesToCache {
    NSMutableArray *cachedAttributes = [NSMutableArray array];
    for (NSTableColumn *i in [_tableView tableColumns]) {
        if (![i isHidden] && ![[i identifier] isEqual:PRListSortIndex]) {
            [cachedAttributes addObject:[i identifier]];
        }
    }
    return cachedAttributes;
}

/*

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
    // [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];    
}

*/
@end
