#import "PRNowPlayingViewController.h"
#import "PRNowPlayingViewController_Private.h"
#import "BWTexturedSlider.h"
#import "NSColor+Extensions.h"
#import "NSIndexPath+Extensions.h"
#import "NSIndexSet+Extensions.h"
#import "NSMenuItem+Extensions.h"
#import "NSTableView+Extensions.h"
#import "PRAction.h"
#import "PRActionCenter.h"
#import "PRConnection.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRGradientView.h"
#import "PRLibrary.h"
#import "PRLibraryViewController.h"
#import "PRListDescription.h"
#import "PRListItemsDescription.h"
#import "PRMainWindowController.h"
#import "PRMoviePlayer.h"
#import "PRNowPlayingCell.h"
#import "PRNowPlayingController.h"
#import "PRNowPlayingDescription.h"
#import "PRNowPlayingHeaderCell.h"
#import "PROutlineView.h"
#import "PRPlaylists.h"
#import "PRPlaylistsViewController.h"
#import "PRQueue.h"
#import "PRTableView.h"
#import "PRBrowserViewController.h"
#import "PRViewController.h"


@interface PRNowPlayingViewController () <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate, NSTextFieldDelegate, PROutlineViewDelegate>
@end

@implementation PRNowPlayingViewController {
    __weak PRCore *_core;
    __weak PRDb *_db;
    
    PROutlineView *_outlineView;
    NSScrollView *_scrollview;
    
    NSView *_headerView;
    NSButton *_clearButton;
    NSPopUpButton *_menuButton;
    
    NSMenu *_playlistMenu;
    NSMenu *_contextMenu;
        
    NSPoint _dropPoint;
    
    NSCell *_cachedNowPlayingCell;
    NSCell *_cachedNowPlayingHeaderCell;
    
    PRNowPlayingListItemsDescription *_listItemsDescription;
    PRNowPlayingDescription *_nowPlayingDescription;
}

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _db = [core db];
    return self;
}

- (void)loadView {
    PRGradientView *background = [[PRGradientView alloc] initWithFrame:NSMakeRect(0, 0, 210, 500)];
    [background setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [background setColor:[NSColor PRSidebarBackgroundColor]];
    [background setAltColor:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    [self setView:background];
    
    // outline view
    _scrollview = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 210, 501)];
    [_scrollview setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_scrollview setFocusRingType:NSFocusRingTypeNone];
    [_scrollview setDrawsBackground:NO];
    [_scrollview setBorderType:NSNoBorder];
    [_scrollview setAutohidesScrollers:YES];
    [_scrollview setHasVerticalScroller:YES];
    [[self view] addSubview:_scrollview];
    
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
    _outlineView = [[PROutlineView alloc] initWithFrame:[_scrollview bounds]];
    [_outlineView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_outlineView setFocusRingType:NSFocusRingTypeNone];
    [_outlineView setBackgroundColor:[NSColor transparent]];
    [_outlineView setHeaderView:nil];
    [_outlineView setAllowsMultipleSelection:YES];
    [_outlineView setDoubleAction:@selector(_doubleAction:)];
    [_outlineView setIntercellSpacing:NSMakeSize(0, 0)];
    [_outlineView setTarget:self];
    [_outlineView setDataSource:self];
    [_outlineView setDelegate:self]; 
    [_outlineView registerForDraggedTypes:@[PRFilePboardType, PRIndexesPboardType]];
    [_outlineView setVerticalMotionCanBeginDrag:NO];
    [_outlineView setAutoresizesOutlineColumn:NO];
    [_outlineView addTableColumn:column];
    [_outlineView setOutlineTableColumn:column];
    [_scrollview setDocumentView:_outlineView];
    
    // header view
    _headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 50, 30)];
    
    _playlistMenu = [[NSMenu alloc] init];
    [_playlistMenu setAutoenablesItems:NO];
    [_playlistMenu setDelegate:self];
    _menuButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(18, 3, 25, 25)];
    [[_menuButton cell] setArrowPosition:NSPopUpNoArrow];
    [_menuButton setMenu:_playlistMenu];
    [_menuButton setPullsDown:YES];
    [_menuButton setBordered:NO];
    [_menuButton setToolTip:@"Save the Now Playing playlist."];
    [_headerView addSubview:_menuButton];
    
    _clearButton = [[NSButton alloc] initWithFrame:NSMakeRect(1, 3, 25, 25)];
    [_clearButton setImage:[NSImage imageNamed:@"Trash"]];
    [_clearButton setBordered:NO];
    [_clearButton setTarget:self];
    [_clearButton setAction:@selector(clearPlaylist)];
    [_clearButton setButtonType:NSMomentaryChangeButton];
    [_clearButton setToolTip:@"Clear the Now Playing playlist."];
    [_headerView addSubview:_clearButton];
    
    // context menu
    _contextMenu = [[NSMenu alloc] init];
    [_contextMenu setDelegate:self];
    [_contextMenu setAutoenablesItems:NO];
    [_outlineView setMenu:_contextMenu];
    
    // key views
    [[self firstKeyView] setNextKeyView:_outlineView];
    [_outlineView setNextKeyView:[self lastKeyView]];
    
    // update
    [self menuNeedsUpdate:_playlistMenu];
    [self _updateTableView];
    
    // restore collapse state
    NSIndexSet *collapseState = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsNowPlayingCollapseState];
    [_outlineView collapseItem:nil];
    if ([collapseState lastIndex] < [self outlineView:_outlineView numberOfChildrenOfItem:nil]) {
        [collapseState enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [_outlineView expandItem:[NSIndexPath indexPathForAlbum:idx]];
        }];
    } else {
        [_outlineView expandItem:[NSIndexPath indexPathForAlbum:0]];
    }
    
    // notifications
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(_updateTableView)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(_updateTableView)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(_currentFileDidChange:)];
    [NSNotificationCenter addObserver:self selector:@selector(_applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}

#pragma mark - Accessors

@synthesize headerView = _headerView;

#pragma mark - Action

- (void)collapseAll {
    [_outlineView expandItem:nil];
}

- (void)higlightPlayingFile {
    // if (![_nowPlayingDescription currentItem]) {
    //     return;
    // }
    // id currentItem = [self itemForDbRow:[_nowPlayingDescription currentIndex]];
    // NSArray *parentItem = [self itemForItem:[NSIndexPath indexPathForAlbum:[currentItem indexAtPosition:0]]];
    // if (![_outlineView isItemExpanded:parentItem]) {
    //     [_outlineView collapseItem:nil];
    // }
    // [_outlineView expandItem:parentItem];
    // [_outlineView scrollRowToVisiblePretty:[_outlineView rowForItem:currentItem]];
}

#pragma mark - Action Priv

- (void)clearPlaylist {
    [PRActionCenter performAction:[[PRClearNowPlayingAction alloc] init]];
}

- (void)playSelected {
    NSIndexSet *selected = [self _selectedRows];
    if ([selected count] != 0) {
        PRPlayItemAction *action = [[PRPlayItemAction alloc] init];
        [action setIndex:[selected firstIndex]];
        [PRActionCenter performAction:action];
    }
}

- (void)removeSelected {
    NSIndexSet *selected = [self _selectedRows];
    if ([selected count] != 0) {
        PRRemoveItemsFromListAction *action = [[PRRemoveItemsFromListAction alloc] init];
        [action setIndexes:selected];
        [action setList:[_nowPlayingDescription currentList]];
        [PRActionCenter performAction:action];
    }
}

- (void)revealSelectedInFinder {
    // NSMutableArray *array = [NSMutableArray array];
    // [[self _selectedRows] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
    //     [array addObject:[_listItemsDescription itemAtIndex:i]];
    // }];
    
    // NSString *path = nil;
    // [[[_core conn] library] zValueForItem:array[0] attr:PRItemAttrPath out:&path];
    // if (path) {
    //     [PRActionCenter performAction:[PRBlockAction blockActionWithBlock:^(PRCore *core) {
    //         [[NSWorkspace sharedWorkspace] selectFile:[[NSURL URLWithString:path] path] inFileViewerRootedAtPath:nil];
    //     }]];
    // }
}

- (void)showSelectedInLibrary {
    // NSIndexSet *dbRows = [self selectedDbRows];
    // if ([dbRows count] != 0) {
    //     NSMutableArray *items = [NSMutableArray array];
    //     [dbRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    //         [items addObject:[_listItemsDescription itemAtIndex:idx-1]];
    //     }];
        
    //     PRHighlightItemsAction *action = [[PRHighlightItemsAction alloc] init];
    //     [action setItems:items];
    //     [PRActionCenter performAction:action];
    // }
}

- (void)addSelectedToQueue {
    // [self removeSelectedFromQueue];
    // NSIndexSet *dbRows = [self selectedDbRows];
    // NSInteger dbRow = [dbRows firstIndex];
    // while (dbRow != NSNotFound) {
    //     if (dbRow != [_nowPlayingDescription currentIndex]) {
    //         [[_db queue] appendListItem:[_listItemsDescription listItemAtIndex:dbRow-1]];
    //     }
    //     dbRow = [dbRows indexGreaterThanIndex:dbRow];
    // }
}

- (void)removeSelectedFromQueue {
    // NSIndexSet *dbRows = [self selectedDbRows];
    // NSInteger dbRow = [dbRows firstIndex];
    // while (dbRow != NSNotFound) {
    //     [[_db queue] removeListItem:[_listItemsDescription listItemAtIndex:dbRow-1]];
    //     dbRow = [dbRows indexGreaterThanIndex:dbRow];
    // }
}

- (void)clearQueue {
    // [PRActionCenter performAction:[PRBlockAction blockActionWithBlock:^(PRCore *core) {
    //     [[[core db] queue] clear];
    // }]];
}

#pragma mark - Action Menu Priv

- (void)saveAsNewPlaylist:(id)sender {
    // PRDuplicatePlaylistAction *action = [[PRDuplicatePlaylistAction alloc] init];
    // [action setList:[_nowPlayingDescription currentList]];
    // [PRActionCenter performAction:action];
}

- (void)saveAsPlaylist:(id)sender {
    // NSInteger playlist = [[sender representedObject] intValue];
    // NSString *title = [[_db playlists] titleForList:[NSNumber numberWithInt:playlist]];
    // NSAlert *alert = [[NSAlert alloc] init];
    // [alert addButtonWithTitle:@"Save"];
    // [alert addButtonWithTitle:@"Cancel"];
    // [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to save this as \"%@\"?", title]];
    // [alert setInformativeText:@"Existing playlist contents will be removed."];
    // [alert setAlertStyle:NSWarningAlertStyle];
    
    // [alert beginSheetModalForWindow:[[self view] window] modalDelegate:self didEndSelector:@selector(saveAsPlaylistHandler:code:context:) contextInfo:(__bridge_retained void *)@(playlist)];
}

- (void)saveAsPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context {
    // PRList *list = (__bridge_transfer PRList *)context;
    // if (code != NSAlertFirstButtonReturn) {
    //     return;
    // }
    // [[_db playlists] clearList:list];
    // [[_db playlists] copyItemsFromList:[_nowPlayingDescription currentList] toList:list];
    // [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

- (void)addToPlaylist:(id)sender {
    // PRList *list = [sender representedObject];
    // NSIndexSet *dbRows = [self selectedDbRows];
    // NSInteger dbRow = [dbRows firstIndex];
    // while (dbRow != NSNotFound) {
    //     [[_db playlists] appendItem:[[_db playlists] itemAtIndex:dbRow forList:[_nowPlayingDescription currentList]] toList:list];
    //     dbRow = [dbRows indexGreaterThanIndex:dbRow];
    // }
    // [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

#pragma mark - NSOutlineViewDelegate

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    return [item length] == 1 ? 38 : 19;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return YES;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (!_cachedNowPlayingCell || !_cachedNowPlayingHeaderCell) {
        _cachedNowPlayingCell = [[PRNowPlayingCell alloc] initTextCell:@""];
        _cachedNowPlayingHeaderCell = [[PRNowPlayingHeaderCell alloc] initTextCell:@""];
    }
    return ([item length] == 1) ? _cachedNowPlayingHeaderCell : _cachedNowPlayingCell;
}

#pragma mark - NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)view writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@[[_nowPlayingDescription currentList],[self _selectedRows]]];
    [pboard declareTypes:@[PRIndexesPboardType] owner:self];
    [pboard setData:data forType:PRIndexesPboardType];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)view validateDrop:(id<NSDraggingInfo>)info proposedItem:(NSIndexPath *)item proposedChildIndex:(NSInteger)index {
    if (index == NSOutlineViewDropOnItemIndex) {
        return NSDragOperationNone;
    }
    // KD: WTF is this?
    // if ([item length] == 1 && (![_outlineView isItemExpanded:item] || index == [[_listItemsDescription albumCounts][[item indexAtPosition:0]] integerValue])) {
    //     [_outlineView setDropItem:nil dropChildIndex:[item indexAtPosition:0] + 1];
    // }
    return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)view acceptDrop:(id<NSDraggingInfo>)info item:(NSIndexPath *)indexPath childIndex:(NSInteger)childIndex {
    NSInteger dropIndex;
    if (!indexPath) {
        dropIndex = [_listItemsDescription indexForIndexPath:indexPath];
    } else if ([indexPath length] == 1) {
        dropIndex = [_listItemsDescription indexForIndexPath:indexPath] + childIndex;
    } else {
        dropIndex = 0;
    }
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *filesData = [pboard dataForType:PRFilePboardType];
    NSData *indexesData = [pboard dataForType:PRIndexesPboardType];
    if (filesData) {
        PRAddItemsToListAction *action = [[PRAddItemsToListAction alloc] init];
        [action setItems:[NSKeyedUnarchiver unarchiveObjectWithData:filesData]];
        [action setIndex:dropIndex];
        [action setList:[_nowPlayingDescription currentList]];
        [PRActionCenter performAction:action];
    } else if (indexesData) {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:indexesData];
        if ([array[0] isEqual:[_nowPlayingDescription currentList]]) {
            PRMoveIndexesInListAction *action = [[PRMoveIndexesInListAction alloc] init];
            [action setIndexes:array[1]];
            [action setIndex:dropIndex];
            [action setList:[_nowPlayingDescription currentList]];
            [PRActionCenter performAction:action];
        }
    }
    return YES;
}

#pragma mark - NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(NSIndexPath *)item {
    return [item length] == 1;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(NSIndexPath *)item {
    if (!item) {
        return [[_listItemsDescription albumCounts] count];
    } else if ([item length] == 1) {
        return [[_listItemsDescription albumCounts][[item indexAtPosition:0]] integerValue];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(NSIndexPath *)item {
    PRLibrary *library = [[_core conn] library];
    NSInteger index = [_listItemsDescription indexForIndexPath:item];
    PRItem *it = [_listItemsDescription itemAtIndex:index];
    
    if ([item length] == 1) {
        NSString *album = nil;
        NSString *artist = nil;
        NSNumber *compilation = nil;
        [library zValueForItem:it attr:PRItemAttrAlbum out:&album];
        [library zValueForItem:it attr:PRItemAttrArtist out:&artist];
        [library zValueForItem:it attr:PRItemAttrCompilation out:&compilation];
        if (!artist || [artist isEqualToString:@""]) {
            artist = @"Unknown Artist";
        }
        if (!album || [album isEqualToString:@""]) {
            album = @"Unknown Album";
        }
        if ([compilation boolValue] && [[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]) {
            artist = @"Compilation";
        }
       NSNumber *drawBorder = @([item indexAtPosition:0] + 1 == [[_listItemsDescription albumCounts] count] || [_outlineView isItemExpanded:item]);
        return @{@"title":artist, @"subtitle":album, @"item":item, @"drawBorder":drawBorder, @"target":self};
    } else {
        NSString *title = nil;
        [library zValueForItem:it attr:PRItemAttrTitle out:&title];
        NSImage *icon;
        NSImage *invertedIcon;
        if ([_nowPlayingDescription currentIndex] == index+1) {
            icon = [NSImage imageNamed:@"PRSpeakerIcon"];
            invertedIcon = [NSImage imageNamed:@"PRLightSpeakerIcon"];
        } else if ([[_nowPlayingDescription invalidItems] containsObject:it]) {
            icon = [NSImage imageNamed:@"Exclamation Point"];
            invertedIcon = [NSImage imageNamed:@"Exclamation Point"];
        } else {
            icon = [[NSImage alloc] init];
            invertedIcon = [[NSImage alloc] init];
        }
        PRListItem *listItem = [_listItemsDescription listItemAtIndex:index];
        NSArray *queue = nil;
        [[[_core conn] queue] zQueueArray:&queue];
        NSUInteger queueIndex = [queue indexOfObject:listItem];
        NSNumber *badge = (queue && queueIndex != NSNotFound) ? @(queueIndex + 1) : @0;
        return @{@"title":title, @"icon":icon, @"invertedIcon":invertedIcon, @"badge":badge, @"item":item, @"target":self};
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(NSIndexPath *)item {
    if (!item) {
        return [NSIndexPath indexPathForAlbum:index];
    } else {
        return [NSIndexPath indexPathForAlbum:[item indexAtPosition:0] song:index];
    }
}

#pragma mark - PROutlineViewDelegate

- (BOOL)outlineView:(PROutlineView *)outlineView keyDown:(NSEvent *)event {
    if ([[event characters] length] != 1) {
        return NO;
    }
    BOOL didHandle = NO;
    NSUInteger flags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    UniChar c = [[event characters] characterAtIndex:0];
    if (flags == 0) {
        if (c == 0x7F || c == 0xf728) {
            [self removeSelected];
            didHandle = YES;
        } else if (c == 0xd) {
            [self playSelected];
            didHandle = YES;
        }
    } else if (flags == (NSNumericPadKeyMask | NSFunctionKeyMask)) {
        if (c == 0xf703) {
            [PRActionCenter performAction:[[PRPlayNextAction alloc] init]];
            didHandle = YES;
        } else if (c == 0xf702) {
            [PRActionCenter performAction:[[PRPlayPreviousAction alloc] init]];
            didHandle = YES;
        }
    }
    return didHandle;
}

#pragma mark - NSDraggingSource

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    [[NSCursor arrowCursor] set];
    if (operation == 0 && !NSMouseInRect([_outlineView convertPointFromBase:[[_outlineView window] convertScreenToBase:_dropPoint]], [_outlineView bounds], YES)) {
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, _dropPoint, NSZeroSize, nil, nil, nil);
        [self removeSelected];
    }
}

- (void)draggedImage:(NSImage *)anImage movedTo:(NSPoint)point {
    _dropPoint = [NSEvent mouseLocation];
    if (!NSMouseInRect([_outlineView convertPointFromBase:[[_outlineView window] convertScreenToBase:_dropPoint]], [_outlineView bounds], YES)) {
        [[NSCursor disappearingItemCursor] set];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

#pragma mark NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _contextMenu) {
        [self _contextMenuNeedsUpdate];
    } else {
        [self _playlistMenuNeedsUpdate];
    }
}

#pragma mark - Action

- (void)_doubleAction:(id)sender {
    if ([_outlineView clickedRow] == -1) {
        return;
    }
    id item = [_outlineView itemAtRow:[_outlineView clickedRow]];
    NSInteger index = [_listItemsDescription indexForIndexPath:item];
    
    PRPlayItemAction *action = [[PRPlayItemAction alloc] init];
    [action setIndex:index];
    [PRActionCenter performAction:action];
}

#pragma mark - Notifications

- (void)playlistDidChange:(NSNotification *)notification {
    // if ([[[notification userInfo] valueForKey:@"playlist"] isEqual:[_nowPlayingDescription currentList]]) {
    //     [self _updateTableView];
    //     [_outlineView collapseItem:nil];
    //     if ([_nowPlayingDescription currentIndex] != 0) {
    //         NSArray *parentItem = [self itemForItem:[NSIndexPath indexPathForAlbum:0]];
    //         [_outlineView expandItem:parentItem];
    //     }
    // }
}

- (void)_currentFileDidChange:(NSNotification *)notification {
    _nowPlayingDescription = [[_core now] description];
    
    [_outlineView reloadVisibleItems];
    // if ([_nowPlayingDescription currentIndex] != 0) {
    //     id currentItem = [self itemForDbRow:[_nowPlayingDescription currentIndex]];
    //     NSArray *parentItem = [self itemForItem:[NSIndexPath indexPathForAlbum:[currentItem album]]];
    //     if (![_outlineView isItemExpanded:parentItem]) {
    //         [_outlineView collapseItem:nil];
    //     }
    //     [_outlineView expandItem:parentItem];
    //     [_outlineView scrollRowToVisiblePretty:[_outlineView rowForItem:currentItem]];
    // }
}

- (void)_applicationWillTerminate:(NSNotification *)notification {
    NSMutableIndexSet *collapseState = [NSMutableIndexSet indexSet];
    NSUInteger count = [self outlineView:_outlineView numberOfChildrenOfItem:nil];
    for (NSUInteger i = 0; i < count; i++) {
        if ([_outlineView isItemExpanded:[self itemForItem:[NSIndexPath indexPathForAlbum:i]]]) {
            [collapseState addIndex:i];
        }
    }
    [[PRDefaults sharedDefaults] setValue:collapseState forKey:PRDefaultsNowPlayingCollapseState];
}

#pragma mark - Internal

- (NSIndexSet *)_selectedRows {
    NSMutableIndexSet *selectedIndexes = [NSMutableIndexSet indexSet];
    [[_outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
        NSIndexPath *item = [_outlineView itemAtRow:i];
        NSInteger index = [_listItemsDescription indexForIndexPath:item];
        if ([item length] == 2) {
            [selectedIndexes addIndex:index];
        } else {
            NSInteger albumCount = [[_listItemsDescription albumCounts][[item indexAtPosition:0]] integerValue];
            [selectedIndexes addIndexesInRange:NSMakeRange(index, albumCount)];
        }
    }];
    return selectedIndexes;
}

- (void)_updateTableView {
    _nowPlayingDescription = [[_core now] description];
    _listItemsDescription = [[PRNowPlayingListItemsDescription alloc] initWithList:[_nowPlayingDescription currentList] database:_db];
    
    [_outlineView reloadData];
}

- (void)_playlistMenuNeedsUpdate {
    // NSMenu *menu = _playlistMenu;
    // for (NSMenuItem *i in [menu itemArray]) {
    //     [menu removeItem:i];
    // }
    // NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    // [menuItem setImage:[NSImage imageNamed:@"Settings"]];
    // [menu addItem:menuItem];
    
    // menuItem = [[NSMenuItem alloc] initWithTitle:@"Save as..." action:nil keyEquivalent:@""];
    // [menuItem setEnabled:NO];
    // [menu addItem:menuItem];
    
    // menuItem = [[NSMenuItem alloc] initWithTitle:@" New Playlist          " action:@selector(saveAsNewPlaylist:) keyEquivalent:@""];
    // [menuItem setImage:[NSImage imageNamed:@"Add"]];
    // [menu addItem:menuItem];
    
    // PRPlaylists *playlists = [[_core conn] playlists];
    // NSArray *lists = nil;
    // [playlists zLists:&lists];
    // for (NSNumber *i in lists) {
    //     PRListDescription *listDescription = nil;
    //     BOOL success = [playlists zListDescriptionForList:i out:&listDescription];
    //     if (!success) {
    //         continue;
    //     }
    //     if ([[listDescription type] isEqual:PRListTypeStatic]) {
    //         NSString *playlistTitle = [NSString stringWithFormat:@" %@", [listDescription title]];
    //         menuItem = [[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(saveAsPlaylist:) keyEquivalent:@""];
    //         [menuItem setRepresentedObject:i];
    //         [menuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
    //         [menu addItem:menuItem];
    //     }
    // }
    
    // for (NSMenuItem *i in [menu itemArray]) {
    //     [i setTarget:self];
    // }
}

- (void)_contextMenuNeedsUpdate {
    // for (NSMenuItem *i in [_contextMenu itemArray]) {
    //     [_contextMenu removeItem:i];
    // }
    // if ([_outlineView clickedRow] == -1) {
    //     return;
    // }
    // unichar c[1] = {NSCarriageReturnCharacter};
    // __weak PRNowPlayingViewController *weakSelf = self;
    
    // NSMenuItem *item = [[NSMenuItem alloc] init];
    // [item setTitle:@"Play"];
    // [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    // [item setKeyEquivalentModifierMask:0];
    // [item setActionBlock:^{[weakSelf playSelected];}];
    // [_contextMenu addItem:item];
    
    // // Queue
    // BOOL addToQueue = NO;
    // BOOL removeFromQueue = NO;
    
    // NSArray *queue = nil;
    // [[[_core conn] queue] zQueueArray:&queue];
    
    // NSIndexSet *dbRows = [self selectedDbRows];
    // NSInteger dbRow = [dbRows firstIndex];
    // while (dbRow != NSNotFound) {
    //     PRListItem *listItem = [_listItemsDescription listItemAtIndex:dbRow-1];
    //     if ([queue containsObject:listItem]) {
    //         removeFromQueue = YES;
    //     } else {
    //         addToQueue = YES;
    //     }
    //     dbRow = [dbRows indexGreaterThanIndex:dbRow];
    // }
    // if (addToQueue) {
    //     NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Add to Queue" action:@selector(addSelectedToQueue) keyEquivalent:@""];
    //     [menuItem setTarget:self];
    //     [_contextMenu addItem:menuItem];
    // }
    // if (removeFromQueue) {
    //     NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Remove From Queue" action:@selector(removeSelectedFromQueue) keyEquivalent:@""];
    //     [menuItem setTarget:self];
    //     [_contextMenu addItem:menuItem];
    // }
    // if ([queue count] != 0) {
    //     NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Clear Queue" action:@selector(clearQueue) keyEquivalent:@""];
    //     [menuItem setTarget:self];
    //     [_contextMenu addItem:menuItem];
    // }
    // [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // // Add To Playlist
    // NSMenuItem *playlistMenuItem = [[NSMenuItem alloc] initWithTitle:@"Add to Playlist" action:nil keyEquivalent:@""];
    // NSMenu *playlistMenu_ = [[NSMenu alloc] init];
    // [playlistMenuItem setSubmenu:playlistMenu_];
    // [_contextMenu addItem:playlistMenuItem];
    
    // PRPlaylists *playlists = [[_core conn] playlists];
    // NSArray *lists = nil;
    // [playlists zLists:&lists];
    // for (NSNumber *i in lists) {
    //     PRListDescription *listDescription = nil;
    //     BOOL success = [playlists zListDescriptionForList:i out:&listDescription];
    //     if (!success) {
    //         continue;
    //     }
    //     if ([[listDescription type] isEqual:PRListTypeStatic]) {
    //         NSString *playlistTitle = [NSString stringWithFormat:@" %@", [listDescription title]];
    //         NSMenuItem *tempMenuItem = [[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(addToPlaylist:) keyEquivalent:@""];
    //         [tempMenuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
    //         [tempMenuItem setRepresentedObject:i];
    //         [tempMenuItem setTarget:self];
    //         [playlistMenu_ addItem:tempMenuItem];
    //     }
    // }
    // [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // // Other
    // NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Show in Library" action:@selector(showSelectedInLibrary) keyEquivalent:@""];
    // [menuItem setTarget:self];
    // [_contextMenu addItem:menuItem];
    // menuItem = [[NSMenuItem alloc] initWithTitle:@"Reveal in Finder" action:@selector(revealSelectedInFinder) keyEquivalent:@""];
    // [menuItem setTarget:self];
    // [_contextMenu addItem:menuItem];
    // [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // c[0] = NSDeleteCharacter;;
    // item = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeSelected) keyEquivalent:[NSString stringWithCharacters:c length:1]];
    // [item setTarget:self];
    // [item setKeyEquivalentModifierMask:0];
    // [_contextMenu addItem:item];
}

@end
