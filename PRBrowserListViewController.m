#import "PRBrowserListViewController.h"
#import "PRLibraryDescription.h"
#import "PRTableView.h"
#import "NSColor+Extensions.h"
#import "PRCenteredTextFieldCell.h"
#import "PRTask.h"
#import "PRBridge_Front.h"

@interface PRBrowserListViewController () <NSTableViewDelegate, NSTableViewDataSource, PRTableViewDelegate, NSMenuDelegate>
@end

@implementation PRBrowserListViewController {
    PRBridge *_bridge;
    NSMenu *_headerMenu;
    PRBrowserDescription *_browserDescription;
    PRTableView *_tableView;
    BOOL _updatingSelection;
    __weak id<PRBrowserListViewControllerDelegate> _delegate;
}

- (id)initWithBridge:(PRBridge *)bridge {
    if ((self = [super init])) {
        _bridge = bridge;
    }
    return self;
}

- (void)loadView {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    [scrollView setHasVerticalScroller:YES];
    [self setView:scrollView];

    _tableView = [[PRTableView alloc] initWithFrame:[scrollView bounds]];
    [_tableView setTarget:self];
    [_tableView setDoubleAction:@selector(_doubleAction:)];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setFocusRingType:NSFocusRingTypeNone];
    [_tableView setBackgroundColor:[NSColor PRBrowserBackgroundColor]];
    [_tableView setAllowsMultipleSelection:YES];
    [scrollView setDocumentView:_tableView];
    
    _headerMenu = [[NSMenu alloc] init];
    [_headerMenu setDelegate:self];
    [[_tableView headerView] setMenu:_headerMenu];

    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@""];
    [column setResizingMask:NSTableColumnAutoresizingMask];
    [column setDataCell:[[PRCenteredTextFieldCell alloc] init]];
    [column setEditable:NO];
    [_tableView addTableColumn:column];
}

#pragma mark - API

@synthesize browserDescription = _browserDescription;
@synthesize delegate = _delegate;

- (void)setBrowserDescription:(PRBrowserDescription *)value {
    if ([value isEqualExceptSelection:_browserDescription]) { // So type selection doesn't trigger a reload
        _updatingSelection = YES;
        _browserDescription = value;
        [_tableView selectRowIndexes:[_browserDescription selection] byExtendingSelection:NO];
        _updatingSelection = NO;
    } else {
        _updatingSelection = YES;
        _browserDescription = value;
        [[[[_tableView tableColumns] objectAtIndex:0] headerCell] setStringValue:[_browserDescription title]?:@""];
        [_tableView reloadData];
        [_tableView selectRowIndexes:[_browserDescription selection] byExtendingSelection:NO];
        _updatingSelection = NO;
    }
}

- (NSIndexSet *)selectedIndexes {
    return [_tableView selectedRowIndexes];
}

#pragma mark - NSTableViewDataSource

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
   NSArray *items = [_delegate browserListViewControllerLibraryItems:self];
   [pboard declareTypes:@[PRFilePboardType] owner:self];
   [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:items] forType:PRFilePboardType];
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
    if ([indexes count] == 0 || [indexes containsIndex:0]) {
        return [NSIndexSet indexSetWithIndex:0];
    }
    return indexes;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (!_updatingSelection) {
        [_delegate browserListViewControllerDidChangeSelection:self];
    }
}

- (NSInteger)tableView:(NSTableView *)tableView nextTypeSelectMatchFromRow:(NSInteger)startRow toRow:(NSInteger)endRow forString:(NSString *)string {
    return PRIndexForTypeSelect(tableView, startRow, endRow, string, ^(NSInteger row){
        return [_browserDescription valueForRow:row];
    });
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
        if (c == 0xd) {
            [self _playAction:nil];
            didHandle = YES;
        }
    } else if (flags == NSShiftKeyMask) {
        if (c == 0xd) {
            [self _appendNextAction:nil];
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

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    for (NSMenuItem *i in [_headerMenu itemArray]) {
        [_headerMenu removeItem:i];
    }
    NSMenu *headerMenu = [_delegate browserListViewControllerHeaderMenu:self];
    for (NSMenuItem *i in [headerMenu itemArray]) {
        [headerMenu removeItem:i];
        [_headerMenu addItem:i];
    }
}

#pragma mark - Action

- (void)_doubleAction:(id)sender {
    if ([_tableView clickedRow] != -1) {
        [self _playAction:sender];
    }
}

- (void)_playAction:(id)sender {
    [_bridge performTask:PRPlayItemsTask([_delegate browserListViewControllerLibraryItems:self], 0)];
}

- (void)_appendAction:(id)sender {
    [_bridge performTask:PRAddItemsToListTask([_delegate browserListViewControllerLibraryItems:self], -1, nil)];
}

- (void)_appendNextAction:(id)sender {
    [_bridge performTask:PRAddItemsToListTask([_delegate browserListViewControllerLibraryItems:self], -2, nil)];
}

@end
