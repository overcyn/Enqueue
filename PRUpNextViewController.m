#import "PRUpNextViewController.h"
#import "NSColor+Extensions.h"
#import "NSIndexPath+Extensions.h"
#import "NSIndexSet+Extensions.h"
#import "NSMenuItem+Extensions.h"
#import "NSNotificationCenter+Extensions.h"
#import "NSTableView+Extensions.h"
#import "PRBridge_Front.h"
#import "PRConnection.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRGradientView.h"
#import "PRItem.h"
#import "PRLibrary.h"
#import "PRLibraryViewController.h"
#import "PRList.h"
#import "PRListItems.h"
#import "PRMainWindowController.h"
#import "PRMovie.h"
#import "PROutlineView.h"
#import "PRPlayer.h"
#import "PRPlayerState.h"
#import "PRPlaylists.h"
#import "PRQueue.h"
#import "PRTask.h"
#import "PRUpNextCell.h"
#import "PRUpNextHeaderCell.h"

@interface PRUpNextViewController () <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate, PROutlineViewDelegate>
@end

@implementation PRUpNextViewController {
    PRBridge *_bridge;
    
    PROutlineView *_outlineView;
    NSScrollView *_scrollview;
    
    NSView *_headerView;
    NSButton *_clearButton;
    NSPopUpButton *_menuButton;
    
    NSMenu *_contextMenu;
        
    NSPoint _dropPoint;
    
    NSCell *_cachedNowPlayingCell;
    NSCell *_cachedNowPlayingHeaderCell;
    
    PRNowPlayingListItems *_playerList;
    PRPlayerState *_player;
    NSArray *_queue;
}

#pragma mark - Initialization

- (id)initWithBridge:(PRBridge *)bridge {
    if ((self = [super init])) {
        _bridge = bridge;
    }
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
    
    // context menu
    _contextMenu = [[NSMenu alloc] init];
    [_contextMenu setDelegate:self];
    [_contextMenu setAutoenablesItems:NO];
    [_outlineView setMenu:_contextMenu];
    
    // key views
    [[self firstKeyView] setNextKeyView:_outlineView];
    [_outlineView setNextKeyView:[self lastKeyView]];
    
    // update
    [self _reloadData:nil];
    
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
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(_playlistItemsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(_itemsDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(_playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeBackendChanged:self sel:@selector(_backendDidChange:)];
    [NSNotificationCenter addObserver:self selector:@selector(_applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}

#pragma mark - API

- (void)higlightPlayingFile {
    if ([_player currentItem]) {
        NSIndexPath *indexPath = [_playerList indexPathForIndex:[_player currentIndex]];
        NSIndexPath *parentIndexPath = [NSIndexPath indexPathForAlbum:[indexPath indexAtPosition:0]];
        if (![_outlineView isItemExpanded:parentIndexPath]) {
            [_outlineView collapseItem:nil];
            [_outlineView expandItem:parentIndexPath];
        }
        [_outlineView scrollRowToVisiblePretty:[_outlineView rowForItem:indexPath]];
    }
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
        _cachedNowPlayingCell = [[PRUpNextCell alloc] initTextCell:@""];
        _cachedNowPlayingHeaderCell = [[PRUpNextHeaderCell alloc] initTextCell:@""];
    }
    return ([item length] == 1) ? _cachedNowPlayingHeaderCell : _cachedNowPlayingCell;
}

#pragma mark - NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)view writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@[[_player currentList],[self _selectedIndexes]]];
    [pboard declareTypes:@[PRIndexesPboardType] owner:self];
    [pboard setData:data forType:PRIndexesPboardType];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)view validateDrop:(id<NSDraggingInfo>)info proposedItem:(NSIndexPath *)item proposedChildIndex:(NSInteger)index {
    if (index == NSOutlineViewDropOnItemIndex) {
        return NSDragOperationNone;
    }
    // KD: WTF is this?
    // if ([item length] == 1 && (![_outlineView isItemExpanded:item] || index == [[_playerList albumCounts][[item indexAtPosition:0]] integerValue])) {
    //     [_outlineView setDropItem:nil dropChildIndex:[item indexAtPosition:0] + 1];
    // }
    return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)view acceptDrop:(id<NSDraggingInfo>)info item:(NSIndexPath *)indexPath childIndex:(NSInteger)childIndex {
    NSInteger dropIndex;
    if (!indexPath) {
        dropIndex = [_playerList indexForIndexPath:indexPath];
    } else if ([indexPath length] == 1) {
        dropIndex = [_playerList indexForIndexPath:indexPath] + childIndex;
    } else {
        dropIndex = 0;
    }
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *filesData = [pboard dataForType:PRFilePboardType];
    NSData *indexesData = [pboard dataForType:PRIndexesPboardType];
    if (filesData) {
        NSArray *items = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
        [_bridge performTask:PRAddItemsToListTask(items, dropIndex, [_player currentList])];
    } else if (indexesData) {
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:indexesData];
        if ([array[0] isEqual:[_player currentList]]) {
            [_bridge performTask:PRMoveIndexesInListTask(array[1], dropIndex, [_player currentList])];
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
        return [[_playerList albumCounts] count];
    } else if ([item length] == 1) {
        return [[_playerList albumCounts][[item indexAtPosition:0]] integerValue];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(NSIndexPath *)item {
    NSInteger index = [_playerList indexForIndexPath:item];
    PRItemID *itemID = [_playerList itemIDAtIndex:index];
    __block PRItem *it = nil;
    [_bridge performTaskSync:^(PRCore *core){
        [[[core conn] library] zItemDescriptionForItem:itemID out:&it];
    }];
    
    if ([item length] == 1) {
        NSString *album = [it album];
        NSString *artist = [it artist];
        if (!artist || [artist isEqualToString:@""]) {
            artist = @"Unknown Artist";
        }
        if (!album || [album isEqualToString:@""]) {
            album = @"Unknown Album";
        }
        if ([it compilation] && [[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]) {
            artist = @"Compilation";
        }
       NSNumber *drawBorder = @([item indexAtPosition:0] + 1 == [[_playerList albumCounts] count] || [_outlineView isItemExpanded:item]);
        return @{@"title":artist, @"subtitle":album, @"item":item, @"drawBorder":drawBorder, @"target":self};
    } else {
        NSString *title = [it title];
        NSImage *icon;
        NSImage *invertedIcon;
        if ([_player currentIndex] == index) {
            icon = [NSImage imageNamed:@"PRSpeakerIcon"];
            invertedIcon = [NSImage imageNamed:@"PRLightSpeakerIcon"];
        } else if ([[_player invalidItems] containsObject:itemID]) {
            icon = [NSImage imageNamed:@"Exclamation Point"];
            invertedIcon = [NSImage imageNamed:@"Exclamation Point"];
        } else {
            icon = [[NSImage alloc] init];
            invertedIcon = [[NSImage alloc] init];
        }
        PRListItemID *listItem = [_playerList listItemIDAtIndex:index];
        NSUInteger queueIndex = [_queue indexOfObject:listItem];
        NSNumber *badge = (_queue && queueIndex != NSNotFound) ? @(queueIndex + 1) : @0;
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
            [self _removeSelectedAction:nil];
            didHandle = YES;
        } else if (c == 0xd) {
            [self _playSelectedAction:nil];
            didHandle = YES;
        }
    } else if (flags == (NSNumericPadKeyMask | NSFunctionKeyMask)) {
        if (c == 0xf703) {
            [_bridge performTask:PRPlayNextTask()];
            didHandle = YES;
        } else if (c == 0xf702) {
            [_bridge performTask:PRPlayPreviousTask()];
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
        [self _removeSelectedAction:nil];
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
    [self _updateContextMenu];
}

#pragma mark - Action

- (void)_doubleAction:(id)sender {
    if ([_outlineView clickedRow] == -1) {
        return;
    }
    id item = [_outlineView itemAtRow:[_outlineView clickedRow]];
    NSInteger index = [_playerList indexForIndexPath:item];
    [_bridge performTask:PRPlayIndexTask(index)];
}

- (void)_playSelectedAction:(id)sender {
    NSIndexSet *selected = [self _selectedIndexes];
    if ([selected count] != 0) {
        [_bridge performTask:PRPlayIndexTask([selected firstIndex])];
    }
}

- (void)_removeSelectedAction:(id)sender {
    NSIndexSet *selected = [self _selectedIndexes];
    if ([selected count] != 0) {
        [_bridge performTask:PRRemoveItemsFromListTask(selected, [_player currentList])];
    }
}

- (void)_revealSelectedAction:(id)sender {
    NSArray *items = [self _selectedItems];
    if ([items count] != 0) {
        [_bridge performTask:PRRevealTask(items)];
    }
}

- (void)_showSelectedInLibraryAction:(id)sender {
    NSArray *items = [self _selectedItems];
    if ([items count] != 0) {
        [_bridge performTask:PRHighightItemsTask(items)];
    }
}

- (void)_addSelectedToQueueAction:(id)sender {
    NSArray *items = [self _selectedItems];
    if ([items count] != 0) {
        [_bridge performTask:PRAddToQueueTask(items)];
    }
}

- (void)_removeSelectedFromQueueAction:(id)sender {
    NSArray *items = [self _selectedItems];
    if ([items count] != 0) {
        [_bridge performTask:PRRemoveFromQueueTask(items)];
    }
}

- (void)_clearQueueAction:(id)sender {
    [_bridge performTask:PRClearQueueTask()];
}

- (void)_saveAsNewPlaylist:(id)sender {
    [_bridge performTask:PRDuplicateListTask([_player currentList])];
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
    // [[_db playlists] copyItemsFromList:[_player currentList] toList:list];
    // [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

- (void)addToPlaylist:(id)sender {
    // PRList *list = [sender representedObject];
    // NSIndexSet *dbRows = [self selectedDbRows];
    // NSInteger dbRow = [dbRows firstIndex];
    // while (dbRow != NSNotFound) {
    //     [[_db playlists] appendItem:[[_db playlists] itemAtIndex:dbRow forList:[_player currentList]] toList:list];
    //     dbRow = [dbRows indexGreaterThanIndex:dbRow];
    // }
    // [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

#pragma mark - Notifications

- (void)_itemsDidChange:(NSNotification *)notification {
    [self _reloadData:nil];
}

- (void)_playlistItemsDidChange:(NSNotification *)notification {
    [self _reloadData:nil];
}

- (void)_playlistDidChange:(NSNotification *)notification {
    [self _reloadData:nil];
}

- (void)_backendDidChange:(NSNotification *)note {
    for (NSObject *i in [[note userInfo][@"changeset"] changes]) {
        if ([i isKindOfClass:[PRNowPlayingChange class]]) {
            [self _reloadData:nil];
        }
    }
}

- (void)_applicationWillTerminate:(NSNotification *)notification {
    NSMutableIndexSet *collapseState = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < [self outlineView:_outlineView numberOfChildrenOfItem:nil]; i++) {
        if ([_outlineView isItemExpanded:[NSIndexPath indexPathForAlbum:i]]) {
            [collapseState addIndex:i];
        }
    }
    [[PRDefaults sharedDefaults] setValue:collapseState forKey:PRDefaultsNowPlayingCollapseState];
}

#pragma mark - Internal

- (void)_reloadData:(PRChangeSet *)changeSet {
    __block PRNowPlayingListItems *playerList;
    __block PRPlayerState *player;
    __block NSArray *queue;
    [_bridge performTaskSync:^(PRCore *core){
        player = [[core now] playerState];
        playerList = [[PRNowPlayingListItems alloc] initWithListID:[player currentList] connection:[core conn]];
        [[[core conn] queue] zQueueArray:&queue];
    }];
    _player = player;
    _playerList = playerList;
    _queue = queue;
    
    [_outlineView reloadData];
}

- (NSIndexSet *)_selectedIndexes {
    NSMutableIndexSet *selectedIndexes = [NSMutableIndexSet indexSet];
    [[_outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
        NSIndexPath *item = [_outlineView itemAtRow:i];
        NSInteger index = [_playerList indexForIndexPath:item];
        if ([item length] == 2) {
            [selectedIndexes addIndex:index];
        } else {
            NSInteger albumCount = [[_playerList albumCounts][[item indexAtPosition:0]] integerValue];
            [selectedIndexes addIndexesInRange:NSMakeRange(index, albumCount)];
        }
    }];
    return selectedIndexes;
}

- (NSArray *)_selectedItems {
    NSMutableArray *selectedItems = [NSMutableArray array];
    [[self _selectedIndexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
        [selectedItems addObject:[_playerList itemIDAtIndex:i]];
    }];
    return selectedItems;
}

- (NSArray *)_selectedListItems {
    NSMutableArray *selectedListItems = [NSMutableArray array];
    [[self _selectedIndexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
        [selectedListItems addObject:[_playerList listItemIDAtIndex:i]];
    }];
    return selectedListItems;
}

- (void)_updateContextMenu {
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
    // [item setActionBlock:^{[weakSelf _playSelectedAction:];}];
    // [_contextMenu addItem:item];
    
    // // Queue
    // BOOL addToQueue = NO;
    // BOOL removeFromQueue = NO;
    
    // NSArray *queue = nil;
    // [[[_core conn] queue] zQueueArray:&queue];
    
    // NSIndexSet *dbRows = [self selectedDbRows];
    // NSInteger dbRow = [dbRows firstIndex];
    // while (dbRow != NSNotFound) {
    //     PRListItem *listItem = [_playerList listItemAtIndex:dbRow-1];
    //     if ([queue containsObject:listItem]) {
    //         removeFromQueue = YES;
    //     } else {
    //         addToQueue = YES;
    //     }
    //     dbRow = [dbRows indexGreaterThanIndex:dbRow];
    // }
    // if (addToQueue) {
    //     NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Add to Queue" action:@selector(_addSelectedToQueueAction:) keyEquivalent:@""];
    //     [menuItem setTarget:self];
    //     [_contextMenu addItem:menuItem];
    // }
    // if (removeFromQueue) {
    //     NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Remove From Queue" action:@selector(_removeSelectedFromQueueAction:) keyEquivalent:@""];
    //     [menuItem setTarget:self];
    //     [_contextMenu addItem:menuItem];
    // }
    // if ([queue count] != 0) {
    //     NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Clear Queue" action:@selector(_clearQueueAction:) keyEquivalent:@""];
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
    // [playlists zListIDs:&lists];
    // for (NSNumber *i in lists) {
    //     PRListDescription *listDescription = nil;
    //     BOOL success = [playlists zListForListID:i out:&listDescription];
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
    // NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Show in Library" action:@selector(_showSelectedInLibraryAction:) keyEquivalent:@""];
    // [menuItem setTarget:self];
    // [_contextMenu addItem:menuItem];
    // menuItem = [[NSMenuItem alloc] initWithTitle:@"Reveal in Finder" action:@selector(_revealSelectedAction:) keyEquivalent:@""];
    // [menuItem setTarget:self];
    // [_contextMenu addItem:menuItem];
    // [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // c[0] = NSDeleteCharacter;;
    // item = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(_removeSelectedAction:) keyEquivalent:[NSString stringWithCharacters:c length:1]];
    // [item setTarget:self];
    // [item setKeyEquivalentModifierMask:0];
    // [_contextMenu addItem:item];
}

@end
