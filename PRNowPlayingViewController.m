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
    
    PROutlineView *_nowPlayingTableView;
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
    _nowPlayingTableView = [[PROutlineView alloc] initWithFrame:[_scrollview bounds]];
    [_nowPlayingTableView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_nowPlayingTableView setFocusRingType:NSFocusRingTypeNone];
    [_nowPlayingTableView setBackgroundColor:[NSColor transparent]];
    [_nowPlayingTableView setHeaderView:nil];
    [_nowPlayingTableView setAllowsMultipleSelection:YES];
    [_nowPlayingTableView setDoubleAction:@selector(play)];
    [_nowPlayingTableView setIntercellSpacing:NSMakeSize(0, 0)];
    [_nowPlayingTableView setTarget:self];
    [_nowPlayingTableView setDataSource:self];
    [_nowPlayingTableView setDelegate:self]; 
    [_nowPlayingTableView registerForDraggedTypes:@[PRFilePboardType]];
    [_nowPlayingTableView setVerticalMotionCanBeginDrag:NO];
    [_nowPlayingTableView setAutoresizesOutlineColumn:NO];
    [_nowPlayingTableView addTableColumn:column];
    [_nowPlayingTableView setOutlineTableColumn:column];
    [_scrollview setDocumentView:_nowPlayingTableView];
    
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
    [_nowPlayingTableView setMenu:_contextMenu];
    
    // key views
    [[self firstKeyView] setNextKeyView:_nowPlayingTableView];
    [_nowPlayingTableView setNextKeyView:[self lastKeyView]];
    
    // update
    [self menuNeedsUpdate:_playlistMenu];
    [self updateTableView];
    
    // restore collapse state
    NSIndexSet *collapseState = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsNowPlayingCollapseState];
    [_nowPlayingTableView collapseItem:nil];
    if ([collapseState lastIndex] < [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil]) {
        [collapseState enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [_nowPlayingTableView expandItem:[self itemForItem:[NSIndexPath indexPathForAlbum:idx]]];
        }];
    } else {
        [_nowPlayingTableView expandItem:[self itemForItem:[NSIndexPath indexPathForAlbum:0]]];
    }
    
    // notifications
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(updateTableView)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(currentFileDidChange:)];
    [NSNotificationCenter addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}

#pragma mark - Accessors

@synthesize headerView = _headerView;

#pragma mark - Action

- (void)collapseAll {
    [_nowPlayingTableView expandItem:nil];
}

- (void)higlightPlayingFile {
    if (![_nowPlayingDescription currentItem]) {
        return;
    }
    id currentItem = [self itemForDbRow:[_nowPlayingDescription currentIndex]];
    NSArray *parentItem = [self itemForItem:[NSIndexPath indexPathForAlbum:[currentItem indexAtPosition:0]]];
    if (![_nowPlayingTableView isItemExpanded:parentItem]) {
        [_nowPlayingTableView collapseItem:nil];
    }
    [_nowPlayingTableView expandItem:parentItem];
    [_nowPlayingTableView scrollRowToVisiblePretty:[_nowPlayingTableView rowForItem:currentItem]];
}

- (void)addItems:(NSArray *)items atIndex:(int)index {
    // Adding
    NSArray *files = items;
    int dbRow = index;
    
    NSMutableArray *beforeArray = [NSMutableArray array];
    NSMutableArray *afterArray = [NSMutableArray array];
    int albumCount = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
    for (int i = 0; i < albumCount; i++) {
        NSArray *item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
        NSRange range = [self dbRangeForParentItem:item];
        if (range.location == dbRow) {
            break;
        }
        [beforeArray addObject:[NSNumber numberWithBool:[_nowPlayingTableView isItemExpanded:item]]];
        if (NSLocationInRange(dbRow, range)) {
            break;
        }
    }
    if (dbRow <= [self dbRowCount]) {
        for (int i = albumCount - 1; i >= 0 ; i--) {
            NSArray *item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
            [afterArray addObject:@([_nowPlayingTableView isItemExpanded:item])];
            NSRange range = [self dbRangeForParentItem:item];
            if (NSLocationInRange(dbRow, range)) {
                break;
            }
        }
    }
    
    // Checks if adding single album
    BOOL singleAlbum = YES;
    if ([files count] > 1) {
        PRLibrary *library = [[_core conn] library];
        NSString *artist = nil;
        NSString *album = nil;
        [library zArtistValueForItem:files[0] out:&artist];
        [library zValueForItem:files[0] attr:PRItemAttrAlbum out:&album];
        for (NSNumber *i in files) {
            NSString *nextArtist = nil;
            NSString *nextAlbum = nil;
            [library zArtistValueForItem:i out:&nextArtist];
            [library zValueForItem:i attr:PRItemAttrAlbum out:&nextAlbum];
            if (![artist isEqualToString:nextArtist] || ![album isEqualToString:nextAlbum]) {
                singleAlbum = NO;
                break;
            }
        }
    }
    
    [[_db playlists] addItems:files atIndex:dbRow toList:[_nowPlayingDescription currentList]];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_nowPlayingDescription currentList]];
    
    [_nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    [_nowPlayingTableView collapseItem:nil];
    
    albumCount = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
    for (int i = 0; i < [beforeArray count]; i++) {
        id item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
        if ([[beforeArray objectAtIndex:i] boolValue]) {
            [_nowPlayingTableView expandItem:item];
        } else {
            [_nowPlayingTableView collapseItem:item];
        }
    }
    for (int i = 0; i < [afterArray count]; i++) {
        id item = [self itemForItem:[NSIndexPath indexPathForAlbum:albumCount - i - 1]];
        if ([[afterArray objectAtIndex:i] boolValue]) {
            [_nowPlayingTableView expandItem:item];
        } else {
            [_nowPlayingTableView collapseItem:item];
        }
    }
    
    if (singleAlbum) {
        id item = [self itemForItem:[NSIndexPath indexPathForAlbum:[beforeArray count]]];
        [_nowPlayingTableView expandItem:item];
    }
}

#pragma mark - Action Priv

- (void)clearPlaylist {
    [PRActionCenter performAction:[[PRClearNowPlayingAction alloc] init]];
}

- (void)playSelected {
    NSIndexSet *selected = [self selectedDbRows];
    if ([selected count] != 0) {
        PRPlayItemAtIndexAction *action = [[PRPlayItemAtIndexAction alloc] init];
        [action setIndex:[selected firstIndex]];
        [PRActionCenter performAction:action];
    }
}

- (void)removeSelected {
    NSIndexSet *dbRows = [self selectedDbRows];
    
    int albumCount = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
    NSMutableArray *array = [NSMutableArray array];
    BOOL prevAlbumMissing = NO;
    for (int i = 0; i < albumCount; i++) {
        NSArray *item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
        NSRange range = [self dbRangeForParentItem:item];
        if (range.length == [dbRows countOfIndexesInRange:range]) {
            prevAlbumMissing = YES;
            continue;
        } else {
            PRItem *item_ = [_listItemsDescription itemAtIndex:range.location-1];
            NSString *artist = nil;
            NSString *album = nil;
            [[[_core conn] library] zValueForItem:item_ attr:PRItemAttrArtist out:&artist];
            [[[_core conn] library] zValueForItem:item_ attr:PRItemAttrAlbum out:&album];
            NSString *prevArtist = [[array lastObject] objectForKey:@"artist"];
            NSString *prevAlbum = [[array lastObject] objectForKey:@"album"];
            if (!(prevAlbumMissing && [artist noCaseCompare:prevArtist] == NSOrderedSame && [album noCaseCompare:prevAlbum] == NSOrderedSame)) {
                NSDictionary *info = @{@"expanded":@([_nowPlayingTableView isItemExpanded:item]), @"artist":artist, @"album":album};
                [array addObject:info];
            }
            prevAlbumMissing = NO;
        }
    }
    
    BOOL shouldStop = [dbRows containsIndex:[_nowPlayingDescription currentIndex]];
    [PRActionCenter performAction:[PRBlockAction blockActionWithBlock:^(PRCore *core) {
        if (shouldStop) {
            [[core now] stop];
        }
        [[[core db] playlists] zRemoveItemsAtIndexes:dbRows fromList:[_nowPlayingDescription currentList]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_nowPlayingDescription currentList]];
            [_nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
            for (int i = 0; i < [array count]; i++) {
                if ([[[array objectAtIndex:i] objectForKey:@"expanded"] boolValue]) {
                    [_nowPlayingTableView expandItem:[self itemForItem:[NSIndexPath indexPathForAlbum:i]]];
                } else {
                    [_nowPlayingTableView collapseItem:[self itemForItem:[NSIndexPath indexPathForAlbum:i]]];
                }
            }
        });
    }]];
}

- (void)revealSelectedInFinder {
    NSMutableArray *array = [NSMutableArray array];
    [[self selectedDbRows] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [array addObject:[_listItemsDescription itemAtIndex:idx-1]];
    }];
    
    NSString *path = nil;
    [[[_core conn] library] zValueForItem:array[0] attr:PRItemAttrPath out:&path];
    if (path) {
        [PRActionCenter performAction:[PRBlockAction blockActionWithBlock:^(PRCore *core) {
            [[NSWorkspace sharedWorkspace] selectFile:[[NSURL URLWithString:path] path] inFileViewerRootedAtPath:nil];
        }]];
    }
}

- (void)showSelectedInLibrary {
    NSIndexSet *dbRows = [self selectedDbRows];
    if ([dbRows count] != 0) {
        NSMutableArray *items = [NSMutableArray array];
        [dbRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [items addObject:[_listItemsDescription itemAtIndex:idx-1]];
        }];
        
        PRHighlightItemsAction *action = [[PRHighlightItemsAction alloc] init];
        [action setItems:items];
        [PRActionCenter performAction:action];
    }
}

- (void)addSelectedToQueue {
    [self removeSelectedFromQueue];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        if (dbRow != [_nowPlayingDescription currentIndex]) {
            [[_db queue] appendListItem:[_listItemsDescription listItemAtIndex:dbRow-1]];
        }
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
}

- (void)removeSelectedFromQueue {
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        [[_db queue] removeListItem:[_listItemsDescription listItemAtIndex:dbRow-1]];
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
}

- (void)clearQueue {
    [PRActionCenter performAction:[PRBlockAction blockActionWithBlock:^(PRCore *core) {
        [[[core db] queue] clear];
    }]];
}

#pragma mark - Action Mouse Priv

- (void)play {
    if ([_nowPlayingTableView clickedRow] == -1) {
        return;
    }
    id item = [_nowPlayingTableView itemAtRow:[_nowPlayingTableView clickedRow]];
    NSInteger row = [self dbRowForItem:item];
    
    [PRActionCenter performAction:[PRBlockAction blockActionWithBlock:^(PRCore *core) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[core now] playItemAtIndex:row];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            int row = [_nowPlayingTableView rowForItem:item];
            [_nowPlayingTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        });
    }]];
}

#pragma mark - Action Menu Priv

- (void)saveAsNewPlaylist:(id)sender {
    PRDuplicatePlaylistAction *action = [[PRDuplicatePlaylistAction alloc] init];
    [action setList:[_nowPlayingDescription currentList]];
    [PRActionCenter performAction:action];
}

- (void)saveAsPlaylist:(id)sender {
    // int playlist = [[sender representedObject] intValue];
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

#pragma mark - Update Priv

- (void)updateTableView {
    _nowPlayingDescription = [[_core now] description];
    _listItemsDescription = [[PRNowPlayingListItemsDescription alloc] initWithList:[_nowPlayingDescription currentList] database:_db];
    
    [_nowPlayingTableView reloadData];
}

- (void)playlistMenuNeedsUpdate {
    NSMenu *menu = _playlistMenu;
    for (NSMenuItem *i in [menu itemArray]) {
        [menu removeItem:i];
    }
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setImage:[NSImage imageNamed:@"Settings"]];
    [menu addItem:menuItem];
    
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Save as..." action:nil keyEquivalent:@""];
    [menuItem setEnabled:NO];
    [menu addItem:menuItem];
    
    menuItem = [[NSMenuItem alloc] initWithTitle:@" New Playlist          " action:@selector(saveAsNewPlaylist:) keyEquivalent:@""];
    [menuItem setImage:[NSImage imageNamed:@"Add"]];
    [menu addItem:menuItem];
    
    PRPlaylists *playlists = [[_core conn] playlists];
    NSArray *lists = nil;
    [playlists zLists:&lists];
    for (NSNumber *i in lists) {
        PRListDescription *listDescription = nil;
        BOOL success = [playlists zListDescriptionForList:i out:&listDescription];
        if (!success) {
            continue;
        }
        if ([[listDescription type] isEqual:PRListTypeStatic]) {
            NSString *playlistTitle = [NSString stringWithFormat:@" %@", [listDescription title]];
            menuItem = [[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(saveAsPlaylist:) keyEquivalent:@""];
            [menuItem setRepresentedObject:i];
            [menuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
            [menu addItem:menuItem];
        }
    }
    
    for (NSMenuItem *i in [menu itemArray]) {
        [i setTarget:self];
    }
}

- (void)contextMenuNeedsUpdate {
    for (NSMenuItem *i in [_contextMenu itemArray]) {
        [_contextMenu removeItem:i];
    }
    if ([_nowPlayingTableView clickedRow] == -1) {
        return;
    }
    unichar c[1] = {NSCarriageReturnCharacter};
    __weak PRNowPlayingViewController *weakSelf = self;
    
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [item setTitle:@"Play"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:0];
    [item setActionBlock:^{[weakSelf playSelected];}];
    [_contextMenu addItem:item];
    
    // Queue
    BOOL addToQueue = NO;
    BOOL removeFromQueue = NO;
    
    NSArray *queue = nil;
    [[[_core conn] queue] zQueueArray:&queue];
    
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        PRListItem *listItem = [_listItemsDescription listItemAtIndex:dbRow-1];
        if ([queue containsObject:listItem]) {
            removeFromQueue = YES;
        } else {
            addToQueue = YES;
        }
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
    if (addToQueue) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Add to Queue" action:@selector(addSelectedToQueue) keyEquivalent:@""];
        [menuItem setTarget:self];
        [_contextMenu addItem:menuItem];
    }
    if (removeFromQueue) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Remove From Queue" action:@selector(removeSelectedFromQueue) keyEquivalent:@""];
        [menuItem setTarget:self];
        [_contextMenu addItem:menuItem];
    }
    if ([queue count] != 0) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Clear Queue" action:@selector(clearQueue) keyEquivalent:@""];
        [menuItem setTarget:self];
        [_contextMenu addItem:menuItem];
    }
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // Add To Playlist
    NSMenuItem *playlistMenuItem = [[NSMenuItem alloc] initWithTitle:@"Add to Playlist" action:nil keyEquivalent:@""];
    NSMenu *playlistMenu_ = [[NSMenu alloc] init];
    [playlistMenuItem setSubmenu:playlistMenu_];
    [_contextMenu addItem:playlistMenuItem];
    
    PRPlaylists *playlists = [[_core conn] playlists];
    NSArray *lists = nil;
    [playlists zLists:&lists];
    for (NSNumber *i in lists) {
        PRListDescription *listDescription = nil;
        BOOL success = [playlists zListDescriptionForList:i out:&listDescription];
        if (!success) {
            continue;
        }
        if ([[listDescription type] isEqual:PRListTypeStatic]) {
            NSString *playlistTitle = [NSString stringWithFormat:@" %@", [listDescription title]];
            NSMenuItem *tempMenuItem = [[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(addToPlaylist:) keyEquivalent:@""];
            [tempMenuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
            [tempMenuItem setRepresentedObject:i];
            [tempMenuItem setTarget:self];
            [playlistMenu_ addItem:tempMenuItem];
        }
    }
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // Other
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Show in Library" action:@selector(showSelectedInLibrary) keyEquivalent:@""];
    [menuItem setTarget:self];
    [_contextMenu addItem:menuItem];
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Reveal in Finder" action:@selector(revealSelectedInFinder) keyEquivalent:@""];
    [menuItem setTarget:self];
    [_contextMenu addItem:menuItem];
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    c[0] = NSDeleteCharacter;;
    item = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeSelected) keyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setTarget:self];
    [item setKeyEquivalentModifierMask:0];
    [_contextMenu addItem:item];
}

- (void)playlistDidChange:(NSNotification *)notification {
    if ([[[notification userInfo] valueForKey:@"playlist"] isEqual:[_nowPlayingDescription currentList]]) {
        [self updateTableView];
        [_nowPlayingTableView collapseItem:nil];
        if ([_nowPlayingDescription currentIndex] != 0) {
            NSArray *parentItem = [self itemForItem:[NSIndexPath indexPathForAlbum:0]];
            [_nowPlayingTableView expandItem:parentItem];
        }
    }
}

- (void)currentFileDidChange:(NSNotification *)notification {
    _nowPlayingDescription = [[_core now] description];
    
    [(PROutlineView *)_nowPlayingTableView reloadVisibleItems];
    if ([_nowPlayingDescription currentIndex] != 0) {
        id currentItem = [self itemForDbRow:[_nowPlayingDescription currentIndex]];
        NSArray *parentItem = [self itemForItem:[NSIndexPath indexPathForAlbum:[currentItem album]]];
        if (![_nowPlayingTableView isItemExpanded:parentItem]) {
            [_nowPlayingTableView collapseItem:nil];
        }
        [_nowPlayingTableView expandItem:parentItem];
        [_nowPlayingTableView scrollRowToVisiblePretty:[_nowPlayingTableView rowForItem:currentItem]];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // save collapse state
    NSMutableIndexSet *collapseState = [NSMutableIndexSet indexSet];
    NSUInteger count = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
    for (NSUInteger i = 0; i < count; i++) {
        if ([_nowPlayingTableView isItemExpanded:[self itemForItem:[NSIndexPath indexPathForAlbum:i]]]) {
            [collapseState addIndex:i];
        }
    }
    [[PRDefaults sharedDefaults] setValue:collapseState forKey:PRDefaultsNowPlayingCollapseState];
}

#pragma mark - Misc Priv

- (int)dbRowCount {
    return [_listItemsDescription count];
}

- (NSRange)dbRangeForParentItem:(id)item {
    return [_listItemsDescription rangeForIndexPath:item];
}

- (int)dbRowForItem:(id)item {
    return [_listItemsDescription indexForIndexPath:item];
}

- (id)itemForDbRow:(int)row {
    return [_listItemsDescription indexPathForIndex:row];
}

- (id)itemForItem:(id)item {
    return item;
}

- (NSIndexSet *)selectedDbRows {
    NSMutableIndexSet *selectedDbRows = [NSMutableIndexSet indexSet];
    NSIndexSet *selectedRowIndexes = [_nowPlayingTableView selectedRowIndexes];
    NSInteger selectedRow = [selectedRowIndexes firstIndex];
    while (selectedRow != NSNotFound) {
        NSIndexPath *item = [_nowPlayingTableView itemAtRow:selectedRow];
        if ([item length] == 2) {
            [selectedDbRows addIndex:[self dbRowForItem:item]];
        } else {
            NSInteger albumCount = [[[_listItemsDescription albumCounts] objectAtIndex:[item indexAtPosition:0]] integerValue];
            [selectedDbRows addIndexesInRange:NSMakeRange([self dbRowForItem:item], albumCount)];
        }
        selectedRow = [selectedRowIndexes indexGreaterThanIndex:selectedRow];
    }
    return selectedDbRows;
}

#pragma mark - NSOutlineViewDelegate

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    [cell setHighlighted:[[outlineView selectedRowIndexes] containsIndex:[outlineView rowForItem:item]]];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item length] == 1) {
        return 38.0;
    } else {
        return 19.0;
    }
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
    if ([item length] == 1) {
        return _cachedNowPlayingHeaderCell;
    }
    return _cachedNowPlayingCell;
}

#pragma mark - OutlineView DragAndDrop

- (BOOL)outlineView:(NSOutlineView *)view writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self selectedDbRows]];
    [pboard declareTypes:@[PRFilePboardType] owner:self];
    [pboard setData:data forType:PRFilePboardType];
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)view validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item_ proposedChildIndex:(NSInteger)index {
    NSIndexPath *item = item_;
    if (index == NSOutlineViewDropOnItemIndex) {
        return NSDragOperationNone;
    }
    if ([item length] == 1 &&
        (![_nowPlayingTableView isItemExpanded:item] ||
         index == [[[_listItemsDescription albumCounts] objectAtIndex:[item indexAtPosition:0]] integerValue])) {
        [_nowPlayingTableView setDropItem:nil dropChildIndex:[item indexAtPosition:0] + 1];
    }
    return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)view acceptDrop:(id<NSDraggingInfo>)info item:(NSIndexPath *)item childIndex:(NSInteger)index {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *filesData = [pboard dataForType:PRFilePboardType];
    if ([info draggingSource] == _nowPlayingTableView) {
        // Moving
        NSIndexSet *dbIndexesToMove = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
        
        // Calculate the index at which to move dbIndexesToMove as dbIndexToInsert
        int dbIndexToInsert;
        if (!item) {
            dbIndexToInsert = [self dbRowForItem:[NSIndexPath indexPathForAlbum:index]];
        } else if ([item length] == 1) {
            dbIndexToInsert = [self dbRowForItem:item] + index;
        } else {
            dbIndexToInsert = 1;
        }
        // convert dbIndexToInsert to tempDbIndexToInsert
        int tempDbIndexToInsert = dbIndexToInsert;
        
        // Calculate collapsed/uncollapsed with dbIndexesToMove removed as tempAlbums
        int location = 1;
        int albumCount = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
        NSMutableArray *tempAlbums = [NSMutableArray array];
        NSString *prevArtist = @"";
        NSString *prevAlbum = @"";
        BOOL prevAlbumMissing = NO;
        for (int i = 0; i < albumCount; i++) {
            NSArray *item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
            NSRange range = [self dbRangeForParentItem:item];
            if (NSLocationInRange(dbIndexToInsert, range)) {
                int albumLength = range.length - [dbIndexesToMove countOfIndexesInRange:range];
                if (albumLength == 0) {
                    tempDbIndexToInsert = location;
                } else if (dbIndexToInsert == range.location) {
                    tempDbIndexToInsert = location;
                } else if (dbIndexToInsert == range.location + range.length - 1) {
                    tempDbIndexToInsert = location + albumLength;
                } else {
                    tempDbIndexToInsert = location + albumLength - 1;
                }
            }
            if (range.length - [dbIndexesToMove countOfIndexesInRange:range] == 0) {
                prevAlbumMissing = YES;
                continue;
            }
            PRItem *listItem = [_listItemsDescription itemAtIndex:range.location-1];
            NSString *artist = nil;
            NSString *album = nil;
            [[[_core conn] library] zValueForItem:listItem attr:PRItemAttrArtist out:&artist];
            [[[_core conn] library] zValueForItem:listItem attr:PRItemAttrAlbum out:&album];
            BOOL shouldMergeWithPrevAlbum = prevAlbumMissing && [artist noCaseCompare:prevArtist] == NSOrderedSame && [album noCaseCompare:prevAlbum] == NSOrderedSame;
            prevArtist = artist;
            prevAlbum = album;
            prevAlbumMissing = NO;
            int oldLocation = location;
            location += range.length - [dbIndexesToMove countOfIndexesInRange:range];
            if (shouldMergeWithPrevAlbum) {
                continue;
            }
            [tempAlbums addObject:@{@"expanded":@([_nowPlayingTableView isItemExpanded:item]),
               @"range":[NSValue valueWithRange:NSMakeRange(oldLocation, range.length - [dbIndexesToMove countOfIndexesInRange:range])], 
               @"missing":@([dbIndexesToMove countOfIndexesInRange:range])}];
        }
        
        // Calculate collapsed/uncollapsed using tempAlbums and dbIndexToInsert as beforeArray and afterArray
        NSMutableArray *beforeArray = [NSMutableArray array];
        NSMutableArray *afterArray = [NSMutableArray array];
        int albumCount2 = [tempAlbums count];
        for (int i = 0; i < albumCount2; i++) {
            NSRange range = [[[tempAlbums objectAtIndex:i] objectForKey:@"range"] rangeValue];
            if (range.location == tempDbIndexToInsert) {
                break;
            }
            [beforeArray addObject:[[tempAlbums objectAtIndex:i] objectForKey:@"expanded"]];
            if (NSLocationInRange(tempDbIndexToInsert, range)) {
                break;
            }
        }
        if (tempDbIndexToInsert <= location) {
            for (int i = albumCount2 - 1; i >= 0 ; i--) {
                [afterArray addObject:[[tempAlbums objectAtIndex:i] objectForKey:@"expanded"]];
                NSRange range = [[[tempAlbums objectAtIndex:i] objectForKey:@"range"] rangeValue];
                if (NSLocationInRange(tempDbIndexToInsert, range)) {
                    break;
                }
            }
        }
        
        // Move dbIndexesToMove to dbIndexToInsert
        [[_db playlists] moveItemsAtIndexes:dbIndexesToMove toIndex:dbIndexToInsert inList:[_nowPlayingDescription currentList]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_nowPlayingDescription currentList]];
        [_nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [_nowPlayingTableView collapseItem:nil];
        
        // Collapse/uncollapse using beforeArray and afterArray;
        albumCount = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < [beforeArray count]; i++) {
            id item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
            if ([[beforeArray objectAtIndex:i] boolValue]) {
                [_nowPlayingTableView expandItem:item];
            } else {
                [_nowPlayingTableView collapseItem:item];
            }
        }
        for (int i = 0; i < [afterArray count]; i++) {
            id item = [self itemForItem:[NSIndexPath indexPathForAlbum:albumCount - i - 1]];
            if ([[afterArray objectAtIndex:i] boolValue]) {
                [_nowPlayingTableView expandItem:item];
            } else {
                [_nowPlayingTableView collapseItem:item];
            }
        }
    } else {
        // Adding
        NSArray *files = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
        int dbRow;
        if (!item) {
            dbRow = [self dbRowForItem:[NSIndexPath indexPathForAlbum:index]];
        } else if ([item length] == 1) {
            dbRow = [self dbRowForItem:item] + index;
        } else {
            dbRow = 1;
        }
        
        NSMutableArray *beforeArray = [NSMutableArray array];
        NSMutableArray *afterArray = [NSMutableArray array];
        int albumCount = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < albumCount; i++) {
            NSArray *item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
            NSRange range = [self dbRangeForParentItem:item];
            if (range.location == dbRow) {
                break;
            }
            [beforeArray addObject:[NSNumber numberWithBool:[_nowPlayingTableView isItemExpanded:item]]];
            if (NSLocationInRange(dbRow, range)) {
                break;
            }
        }
        if (dbRow <= [self dbRowCount]) {
            for (int i = albumCount - 1; i >= 0 ; i--) {
                NSArray *item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
                [afterArray addObject:[NSNumber numberWithBool:[_nowPlayingTableView isItemExpanded:item]]];
                NSRange range = [self dbRangeForParentItem:item];
                if (NSLocationInRange(dbRow, range)) {
                    break;
                }
            }
        }
        
        // Checks if adding single album
        BOOL singleAlbum = YES;
        if ([files count] > 1) {
            PRLibrary *library = [[_core conn] library];
            NSString *artist = nil;
            NSString *album = nil;
            [library zArtistValueForItem:files[0] out:&artist];
            [library zValueForItem:files[0] attr:PRItemAttrAlbum out:&album];
            for (NSNumber *i in files) {
                NSString *nextArtist = nil;
                NSString *nextAlbum = nil;
                [library zArtistValueForItem:i out:&nextArtist];
                [library zValueForItem:i attr:PRItemAttrAlbum out:&nextAlbum];
                if (![artist isEqualToString:nextArtist] || ![album isEqualToString:nextAlbum]) {
                    singleAlbum = NO;
                    break;
                }
            }
        }
        
        [[_db playlists] addItems:files atIndex:dbRow toList:[_nowPlayingDescription currentList]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_nowPlayingDescription currentList]];
        [_nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [_nowPlayingTableView collapseItem:nil];
        
        albumCount = [self outlineView:_nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < [beforeArray count]; i++) {
            id item = [self itemForItem:[NSIndexPath indexPathForAlbum:i]];
            if ([[beforeArray objectAtIndex:i] boolValue]) {
                [_nowPlayingTableView expandItem:item];
            } else {
                [_nowPlayingTableView collapseItem:item];
            }
        }
        for (int i = 0; i < [afterArray count]; i++) {
            id item = [self itemForItem:[NSIndexPath indexPathForAlbum:albumCount - i - 1]];
            if ([[afterArray objectAtIndex:i] boolValue]) {
                [_nowPlayingTableView expandItem:item];
            } else {
                [_nowPlayingTableView collapseItem:item];
            }
        }
        
        if (singleAlbum) {
            id item = [self itemForItem:[NSIndexPath indexPathForAlbum:[beforeArray count]]];
            [_nowPlayingTableView expandItem:item];
        }
    }
    return YES;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    [[NSCursor arrowCursor] set];
    if (operation == 0 && !NSMouseInRect([_nowPlayingTableView convertPointFromBase:[[_nowPlayingTableView window] convertScreenToBase:_dropPoint]], [_nowPlayingTableView bounds], YES)) {
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, _dropPoint, NSZeroSize, nil, nil, nil);
        [self removeSelected];
    }
}

- (void)draggedImage:(NSImage *)anImage movedTo:(NSPoint)point {
    _dropPoint = [NSEvent mouseLocation];
    if (!NSMouseInRect([_nowPlayingTableView convertPointFromBase:[[_nowPlayingTableView window] convertScreenToBase:_dropPoint]], [_nowPlayingTableView bounds], YES)) {
        [[NSCursor disappearingItemCursor] set];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

#pragma mark - NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item length] == 1;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
        return [[_listItemsDescription albumCounts] count];
    } else if ([item length] == 1) {
        return [[[_listItemsDescription albumCounts] objectAtIndex:[item indexAtPosition:0]] integerValue];
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    PRLibrary *library = [[_core conn] library];
    NSInteger row = [self dbRowForItem:item];
    PRItem *it = [_listItemsDescription itemAtIndex:row-1];
    
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
       NSNumber *drawBorder = @([item indexAtPosition:0] + 1 == [[_listItemsDescription albumCounts] count] || [_nowPlayingTableView isItemExpanded:item]);
        return @{@"title":artist, @"subtitle":album, @"item":item, @"drawBorder":drawBorder, @"target":self};
    } else {
        NSString *title = nil;
        [library zValueForItem:it attr:PRItemAttrTitle out:&title];
        NSImage *icon;
        NSImage *invertedIcon;
        if ([_nowPlayingDescription currentIndex] == row) {
            icon = [NSImage imageNamed:@"PRSpeakerIcon"];
            invertedIcon = [NSImage imageNamed:@"PRLightSpeakerIcon"];
        } else if ([[_nowPlayingDescription invalidItems] containsObject:it]) {
            icon = [NSImage imageNamed:@"Exclamation Point"];
            invertedIcon = [NSImage imageNamed:@"Exclamation Point"];
        } else {
            icon = [[NSImage alloc] init];
            invertedIcon = [[NSImage alloc] init];
        }
        PRListItem *listItem = [_listItemsDescription listItemAtIndex:row-1];
        NSArray *queue = nil;
        [[[_core conn] queue] zQueueArray:&queue];
        NSUInteger queueIndex = [queue indexOfObject:listItem];
        NSNumber *badge = (queue && queueIndex != NSNotFound) ? @(queueIndex + 1) : @0;
        return @{@"title":title, @"icon":icon, @"invertedIcon":invertedIcon, @"badge":badge, @"item":item, @"target":self};
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    NSIndexPath *newItem;
    if (!item) {
        newItem = [NSIndexPath indexPathForAlbum:index];
    } else {
        newItem = [NSIndexPath indexPathForAlbum:[item indexAtPosition:0] song:index];
    }
    return [self itemForItem:newItem];
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

#pragma mark NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _contextMenu) {
        [self contextMenuNeedsUpdate];
    } else {
        [self playlistMenuNeedsUpdate];
    }
}

@end
