#import "PRBrowserViewController.h"
#import "PRLibraryDescription.h"
#import "PRTableView.h"
#import "NSColor+Extensions.h"
#import "PRCenteredTextFieldCell.h"

@interface PRBrowserViewController () <NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>
@end

@implementation PRBrowserViewController {
    NSMenu *_headerMenu;
    PRBrowserDescription *_browserDescription;
    PRTableView *_tableView;
    BOOL _updatingSelection;
    __weak id<PRBrowserViewControllerDelegate> _delegate;
}

- (void)loadView {
    _headerMenu = [[NSMenu alloc] init];
    [_headerMenu setDelegate:self];
    
    // [[_browser1TableView headerView] setMenu:_headerMenu];
    
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    [scrollView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [scrollView setHasVerticalScroller:YES];

    _tableView = [[PRTableView alloc] initWithFrame:[scrollView bounds]];
    [_tableView setTarget:self];
    [_tableView setDoubleAction:@selector(playBrowser:)];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setFocusRingType:NSFocusRingTypeNone];
    [_tableView setBackgroundColor:[NSColor PRBrowserBackgroundColor]];
    [_tableView setAllowsMultipleSelection:YES];
    [scrollView setDocumentView:_tableView];

    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@""];
    [column setResizingMask:NSTableColumnAutoresizingMask];
    [column setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [column setEditable:NO];
    [_tableView addTableColumn:column];
    
    [self setView:scrollView];
}

#pragma mark - API

@synthesize browserDescription = _browserDescription;
@synthesize delegate = _delegate;

- (void)setBrowserDescription:(PRBrowserDescription *)value {
    _updatingSelection = YES;
    _browserDescription = value;
    [[[[_tableView tableColumns] objectAtIndex:0] headerCell] setStringValue:[_browserDescription title]?:@""];
    [_tableView reloadData];
    [_tableView selectRowIndexes:[_browserDescription selection] byExtendingSelection:NO];
    _updatingSelection = NO;
}

- (void)scrollToSelectedRow {
    
}

- (NSIndexSet *)selectedIndexes {
    return [_tableView selectedRowIndexes];
}

#pragma mark - NSTableViewDataSource

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // [pboard declareTypes:@[PRFilePboardType, PRIndexesPboardType] owner:self];
    
    // // PRFilePboardType
    // NSInteger currentIndex = 0;
    // NSMutableArray *files = [NSMutableArray array];
    //     // If dragging from browser, get all files
    //     while (currentIndex < [self numberOfRowsInTableView:_detailTableView]) {
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_browserDescription count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    return [_browserDescription valueForRow:rowIndex];
}

#pragma mark - NSTableViewDelegate

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)indexes {
    if ([indexes containsIndex:0]) {
        return [NSIndexSet indexSetWithIndex:0];
    }
    return indexes;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (!_updatingSelection) {
        [_delegate browserViewControllerDidChangeSelection:self];
    }
}

#pragma mark - PRTableViewDelegate

// - (BOOL)tableView:(PRTableView *)tableView keyDown:(NSEvent *)event {
//     if ([[event characters] length] != 1) {
//         return NO;
//     }
//     BOOL didHandle = NO;
//     NSUInteger flags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
//     UniChar c = [[event characters] characterAtIndex:0];
//     if (flags == 0) {
//         if (c == 0xd) {
//             [self playBrowser:nil];
//             didHandle = YES;
//         }
//     } else if (flags == NSShiftKeyMask) {
//         if (c == 0xd) {
//             [self appendAll];
//             didHandle = YES;
//         }
//     } else if (flags == NSAlternateKeyMask) {
//         if (c == 0xd) {
//             [self appendNextAll];
//             didHandle = YES;
//         }
//     }
//     return didHandle;
// }

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate {
    // int browserPosition = [[_db playlists] verticalForList:_currentList];
    // __weak PRTableViewController *weakSelf = self;
    
    // NSMenu *menu = [[NSMenu alloc] init];
    // NSMenuItem *item = [[NSMenuItem alloc] init];
    // [item setTitle:@"Hidden"];
    // [item setActionBlock:^{[weakSelf setBrowserPosition:PRBrowserPositionHidden];}];
    // if (browserPosition == PRBrowserPositionHidden) {
    //     [item setState:NSOnState];
    // }
    // [menu addItem:item];
    
    // item = [[NSMenuItem alloc] init];
    // [item setTitle:@"On Top"];
    // [item setActionBlock:^{[weakSelf setBrowserPosition:PRBrowserPositionHorizontal];}];
    // if (browserPosition == PRBrowserPositionHorizontal) {
    //     [item setState:NSOnState];
    // }
    // [menu addItem:item];
    
    // item = [[NSMenuItem alloc] init];
    // [item setTitle:@"On Left"];
    // [item setActionBlock:^{[weakSelf setBrowserPosition:PRBrowserPositionVertical];}];
    // if (browserPosition == PRBrowserPositionVertical) {
    //     [item setState:NSOnState];
    // }
    // [menu addItem:item];
    
    // if (browserPosition != PRBrowserPositionHidden) {
    //     [menu addItem:[NSMenuItem separatorItem]];
        
    //     PRItemAttr *attr1 = [[_db playlists] attrForBrowser:1 list:_currentList];
    //     PRItemAttr *attr2 = [[_db playlists] attrForBrowser:2 list:_currentList];
    //     PRItemAttr *attr3 = [[_db playlists] attrForBrowser:3 list:_currentList];
    //     for (PRItemAttr *i in @[PRItemAttrGenre, PRItemAttrComposer, PRItemAttrArtist, PRItemAttrAlbum]) {
    //         item = [[NSMenuItem alloc] init];
    //         [item setTitle:[PRLibrary titleForItemAttr:i]];
    //         [item setActionBlock:^{[weakSelf toggleBrowser:i];}];
    //         if ([attr1 isEqual:i] || [attr2 isEqual:i] || [attr3 isEqual:i]) {
    //             [item setState:NSOnState];
    //         }
    //         [menu addItem:item];
    //     }
    // }
    // return menu;
}

#pragma mark - Internal

- (void)playBrowser:(id)sender {
    // if ([sender clickedRow] == -1) {
    //     return;
    // }
    // NSMutableArray *items = [NSMutableArray array];
    // for (NSInteger i = 0; i < [_libraryDescription count]; i++) {
    //     [items addObject:[_libraryDescription itemForRow:i]];
    // }
    // PRPlayItemsAction *action = [[PRPlayItemsAction alloc] init];
    // [action setItems:items];
    // [PRActionCenter performAction:action];
}

@end
