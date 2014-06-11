#import "PRNowPlayingViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRNowPlayingViewSource.h"
#import "PRNowPlayingController.h"
#import "PRNowPlayingCell.h"
#import "PRNowPlayingHeaderCell.h"
#import "NSIndexSet+Extensions.h"
#import "PRTableView.h"
#import "PRGradientView.h"
#import "BWTexturedSlider.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRPlaylistsViewController.h"
#import "PRDefaults.h"
#import "PRQueue.h"
#import "NSIndexSet+Extensions.h"
#import "PROutlineView.h"
#import "PRMoviePlayer.h"
#import "PRCore.h"
#import "PRTableViewController.h"
#import "NSMenuItem+Extensions.h"
#import "NSTableView+Extensions.h"
#import "NSColor+Extensions.h"
#import "PRViewController.h"


@interface PRNowPlayingViewController () 
/* Action */
- (void)playItem:(id)item;
- (void)playSelected;
- (void)removeSelected;
- (void)addSelectedToQueue;
- (void)removeSelectedFromQueue;
- (void)showSelectedInLibrary;
- (void)revealSelectedInFinder;

/* Action Mouse */
- (void)play;

/* Action Menu */
- (void)saveAsNewPlaylist:(id)sender;
- (void)saveAsPlaylist:(id)sender;
- (void)saveAsPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context;
- (void)addToPlaylist:(id)sender;

/* Update */
- (void)updateTableView;
- (void)playlistMenuNeedsUpdate; // only called by menuNeedsUpdate:
- (void)contextMenuNeedsUpdate; // only called by menuNeedsUpdate:
- (void)playlistDidChange:(NSNotification *)notification;
- (void)currentFileDidChange:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;

/* Misc */
- (int)dbRowCount;
- (NSRange)dbRangeForParentItem:(id)item;
- (int)dbRowForItem:(id)item;
- (id)itemForDbRow:(int)row;
- (id)itemForItem:(id)item;
- (NSIndexSet *)selectedDbRows;
@end


@implementation PRNowPlayingViewController

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _parentItems = [[NSMutableDictionary alloc] init];
    _childItems = [[NSMutableDictionary alloc] init];
    _core = core;
    db = [core db];
    now = [core now];
    win = [core win];
    return self;
}

- (void)loadView {
    PRGradientView *background = [[PRGradientView alloc] initWithFrame:NSMakeRect(0, 0, 210, 500)];
    [background setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [background setColor:[NSColor PRSidebarBackgroundColor]];
    [background setAltColor:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    [self setView:background];
    
    // outline view
    scrollview = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 210, 501)];
    [scrollview setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [scrollview setFocusRingType:NSFocusRingTypeNone];
    [scrollview setDrawsBackground:NO];
    [scrollview setBorderType:NSNoBorder];
    [scrollview setAutohidesScrollers:YES];
    [scrollview setHasVerticalScroller:YES];
    [[self view] addSubview:scrollview];
    
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
    nowPlayingTableView = [[PROutlineView alloc] initWithFrame:[scrollview bounds]];
    [nowPlayingTableView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [nowPlayingTableView setFocusRingType:NSFocusRingTypeNone];
    [nowPlayingTableView setBackgroundColor:[NSColor transparent]];
    [nowPlayingTableView setHeaderView:nil];
    [nowPlayingTableView setAllowsMultipleSelection:YES];
    [nowPlayingTableView setDoubleAction:@selector(play)];
    [nowPlayingTableView setIntercellSpacing:NSMakeSize(0, 0)];
    [nowPlayingTableView setTarget:self];
    [nowPlayingTableView setDataSource:self];
    [nowPlayingTableView setDelegate:self]; 
    [nowPlayingTableView registerForDraggedTypes:@[PRFilePboardType]];
    [nowPlayingTableView setVerticalMotionCanBeginDrag:NO];
    [nowPlayingTableView setAutoresizesOutlineColumn:NO];
    [nowPlayingTableView addTableColumn:column];
    [nowPlayingTableView setOutlineTableColumn:column];
    [scrollview setDocumentView:nowPlayingTableView];
    
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
    [nowPlayingTableView setMenu:_contextMenu];
    
    // key views
    [[self firstKeyView] setNextKeyView:nowPlayingTableView];
    [nowPlayingTableView setNextKeyView:[self lastKeyView]];
    
    // update
    [self menuNeedsUpdate:_playlistMenu];
    [self updateTableView];
    
    // restore collapse state
    NSIndexSet *collapseState = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsNowPlayingCollapseState];
    [nowPlayingTableView collapseItem:nil];
    if ([collapseState lastIndex] < [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil]) {
        [collapseState enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [nowPlayingTableView expandItem:[self itemForItem:@[[NSNumber numberWithInt:idx]]]];
        }];
    } else {
        [nowPlayingTableView expandItem:[self itemForItem:@[@0]]];
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

- (void)clearPlaylist {
    int count = [[db playlists] countForList:[now currentList]];
    if (count == 1 || [now currentIndex] == 0) {
        // if nothing playing or count == 1, clear playlist
        [now stop];
        [[db playlists] clearList:[now currentList]];
    } else {
        // otherwise delete all previous songs
        [[db playlists] clearList:[now currentList] exceptIndex:[now currentIndex]];
    }
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    [nowPlayingTableView expandItem:nil];
}

- (void)higlightPlayingFile {
    if (![now currentItem]) {
        return;
    }
    id currentItem = [self itemForDbRow:[now currentIndex]];
    NSArray *parentItem = [self itemForItem:@[[currentItem objectAtIndex:0]]];
    if (![nowPlayingTableView isItemExpanded:parentItem]) {
        [nowPlayingTableView collapseItem:nil];
    }
    [nowPlayingTableView expandItem:parentItem];
    [nowPlayingTableView scrollRowToVisiblePretty:[nowPlayingTableView rowForItem:currentItem]];
}

- (void)addItems:(NSArray *)items atIndex:(int)index {
    // Adding
    NSArray *files = items;
    int dbRow = index;
    
    NSMutableArray *beforeArray = [NSMutableArray array];
    NSMutableArray *afterArray = [NSMutableArray array];
    int albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
    for (int i = 0; i < albumCount; i++) {
        NSArray *item = [self itemForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil]];
        NSRange range = [self dbRangeForParentItem:item];
        if (range.location == dbRow) {
            break;
        }
        [beforeArray addObject:[NSNumber numberWithBool:[nowPlayingTableView isItemExpanded:item]]];
        if (NSLocationInRange(dbRow, range)) {
            break;
        }
    }
    if (dbRow <= [self dbRowCount]) {
        for (int i = albumCount - 1; i >= 0 ; i--) {
            NSArray *item = [self itemForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil]];
            [afterArray addObject:[NSNumber numberWithBool:[nowPlayingTableView isItemExpanded:item]]];
            NSRange range = [self dbRangeForParentItem:item];
            if (NSLocationInRange(dbRow, range)) {
                break;
            }
        }
    }
    
    // Checks if adding single album
    BOOL singleAlbum = YES;
    if ([files count] > 1) {
        NSString *artist = [[db library] artistValueForItem:[files objectAtIndex:0]];
        NSString *album = [[db library] valueForItem:[files objectAtIndex:0] attr:PRItemAttrAlbum];
        for (NSNumber *i in files) {
            NSString *nextArtist = [[db library] artistValueForItem:i];
            NSString *nextAlbum = [[db library] valueForItem:i attr:PRItemAttrAlbum];
            if (![artist isEqualToString:nextArtist] || ![album isEqualToString:nextAlbum]) {
                singleAlbum = NO;
            }
        }
    }
    
    [[db playlists] addItems:files atIndex:dbRow toList:[now currentList]];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    [nowPlayingTableView collapseItem:nil];
    
    albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
    for (int i = 0; i < [beforeArray count]; i++) {
        id item = [self itemForItem:@[[NSNumber numberWithInt:i]]];
        if ([[beforeArray objectAtIndex:i] boolValue]) {
            [nowPlayingTableView expandItem:item];
        } else {
            [nowPlayingTableView collapseItem:item];
        }
    }
    for (int i = 0; i < [afterArray count]; i++) {
        id item = [self itemForItem:@[[NSNumber numberWithInt:albumCount - i - 1]]];
        if ([[afterArray objectAtIndex:i] boolValue]) {
            [nowPlayingTableView expandItem:item];
        } else {
            [nowPlayingTableView collapseItem:item];
        }
    }
    
    if (singleAlbum) {
        id item = [self itemForItem:@[[NSNumber numberWithInt:[beforeArray count]]]];
        [nowPlayingTableView expandItem:item];
    }
}

#pragma mark - Action Priv

- (void)playItem:(id)item {
    [now playItemAtIndex:[self dbRowForItem:item]];
}

- (void)playSelected {
    if ([[self selectedDbRows] count] == 0) {
        return;
    }
    [now playItemAtIndex:[[self selectedDbRows] firstIndex]];
}

- (void)removeSelected {
    NSIndexSet *dbRows = [self selectedDbRows];
    
    int albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
    NSMutableArray *array = [NSMutableArray array];
    BOOL prevAlbumMissing = NO;
    for (int i = 0; i < albumCount; i++) {
        NSArray *item = [self itemForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil]];
        NSRange range = [self dbRangeForParentItem:item];
        if (range.length == [dbRows countOfIndexesInRange:range]) {
            prevAlbumMissing = YES;
            continue;
        } else {
            PRItem *item_ = [[db playlists] itemAtIndex:range.location forList:[now currentList]];
            NSString *artist = [[db library] valueForItem:item_ attr:PRItemAttrArtist];
            NSString *album = [[db library] valueForItem:item_ attr:PRItemAttrAlbum];
            NSString *prevArtist = [[array lastObject] objectForKey:@"artist"];
            NSString *prevAlbum = [[array lastObject] objectForKey:@"album"];
            if (!(prevAlbumMissing && [artist noCaseCompare:prevArtist] == NSOrderedSame && [album noCaseCompare:prevAlbum] == NSOrderedSame)) {
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:[nowPlayingTableView isItemExpanded:item]], @"expanded", 
                                      artist, @"artist",
                                      album, @"album", nil];
                [array addObject:info];
            }
            prevAlbumMissing = NO;
        }
    }
    
    if ([dbRows containsIndex:[now currentIndex]]) {
        [now stop];
    }
    [[db playlists] removeItemsAtIndexes:dbRows fromList:[now currentList]];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    
    for (int i = 0; i < [array count]; i++) {
        if ([[[array objectAtIndex:i] objectForKey:@"expanded"] boolValue]) {
            [nowPlayingTableView expandItem:[self itemForItem:@[[NSNumber numberWithInt:i]]]];
        } else {
            [nowPlayingTableView collapseItem:[self itemForItem:@[[NSNumber numberWithInt:i]]]];
        }
    }
}

- (void)revealSelectedInFinder {
    NSIndexSet *dbRows = [self selectedDbRows];
    if ([dbRows count] == 0) {
        return;
    }
    PRItem *item = [[db playlists] itemAtIndex:[dbRows firstIndex] forList:[now currentList]];
    NSString *path = [[db library] valueForItem:item attr:PRItemAttrPath];
    [[NSWorkspace sharedWorkspace] selectFile:[[NSURL URLWithString:path] path] inFileViewerRootedAtPath:nil];
}

- (void)showSelectedInLibrary {
    NSIndexSet *dbRows = [self selectedDbRows];
    if ([dbRows count] == 0) {
        return;
    }
    PRItem *item = [[db playlists] itemAtIndex:[dbRows firstIndex] forList:[now currentList]];
    [win setCurrentMode:PRLibraryMode];
    [[win libraryViewController] setCurrentList:[[db playlists] libraryList]];
    [[[win libraryViewController] currentViewController] highlightItem:item];
}

- (void)addSelectedToQueue {
    [self removeSelectedFromQueue];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        if (dbRow != [now currentIndex]) {
            [[db queue] appendListItem:[[db playlists] listItemAtIndex:dbRow inList:[now currentList]]];
        }
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
}

- (void)removeSelectedFromQueue {
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        [[db queue] removeListItem:[[db playlists] listItemAtIndex:dbRow inList:[now currentList]]];
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
}

- (void)clearQueue {
    [[db queue] clear];
}

#pragma mark - Action Mouse Priv

- (void)play {
    if ([nowPlayingTableView clickedRow] == -1) {
        return;
    }
    id item = [nowPlayingTableView itemAtRow:[nowPlayingTableView clickedRow]];
    [self playItem:item];
    int row = [nowPlayingTableView rowForItem:item];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

#pragma mark - Action Menu Priv

- (void)saveAsNewPlaylist:(id)sender {
    [[win playlistsViewController] duplicatePlaylist:[[now currentList] intValue]];
}

- (void)saveAsPlaylist:(id)sender {
    int playlist = [[sender representedObject] intValue];
    NSString *title = [[db playlists] titleForList:[NSNumber numberWithInt:playlist]];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to save this as \"%@\"?", title]];
    [alert setInformativeText:@"Existing playlist contents will be removed."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[win window] modalDelegate:self didEndSelector:@selector(saveAsPlaylistHandler:code:context:) contextInfo:(__bridge_retained void *)@(playlist)];
}

- (void)saveAsPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context {
    PRList *list = (__bridge_transfer PRList *)context;
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    [[db playlists] clearList:list];
    [[db playlists] copyItemsFromList:[now currentList] toList:list];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

- (void)addToPlaylist:(id)sender {
    PRList *list = [sender representedObject];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        [[db playlists] appendItem:[[db playlists] itemAtIndex:dbRow forList:[now currentList]] toList:list];
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

#pragma mark - Update Priv

- (void)updateTableView {
    // refresh nowPlayingViewSource
    [[db nowPlayingViewSource] refresh];
    
    // refresh tableIndexes
    [_parentItems removeAllObjects];
    [_childItems removeAllObjects];
    
    _albumCounts = [[db nowPlayingViewSource] albumCounts];
    _dbRowForAlbum = [NSMutableArray array];
    _albumIndexes = [NSMutableIndexSet indexSet];
    
    int dbRow = 1;
    [_dbRowForAlbum addObject:[NSNumber numberWithInt:dbRow]];
    [_albumIndexes addIndex:dbRow];
    for (int album = 0; album < [_albumCounts count]; album++) {
        dbRow += [[_albumCounts objectAtIndex:album] intValue];
        [_dbRowForAlbum addObject:[NSNumber numberWithInt:dbRow]];
        [_albumIndexes addIndex:dbRow];
    }
    [nowPlayingTableView reloadData];
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
    
    NSArray *playlistArray = [[db playlists] lists];
    for (NSNumber *i in playlistArray) {
        if (![[[db playlists] typeForList:i] isEqual:PRListTypeStatic]) {
            continue;
        }
        NSString *playlistTitle = [NSString stringWithFormat:@" %@", [[db playlists] titleForList:i]];
        menuItem = [[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(saveAsPlaylist:) keyEquivalent:@""];
        [menuItem setRepresentedObject:i];
        [menuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        [menu addItem:menuItem];
    }
    
    for (NSMenuItem *i in [menu itemArray]) {
        [i setTarget:self];
    }
}

- (void)contextMenuNeedsUpdate {
    for (NSMenuItem *i in [_contextMenu itemArray]) {
        [_contextMenu removeItem:i];
    }
    if ([nowPlayingTableView clickedRow] == -1) {
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
    
    NSArray *queue = [[db queue] queueArray];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        PRListItem *listItem = [[db playlists] listItemAtIndex:dbRow inList:[now currentList]];
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
    
    NSArray *playlistArray = [[db playlists] lists];
    for (NSNumber *i in playlistArray) {
        if (![[[db playlists] typeForList:i] isEqual:PRListTypeStatic]) {
            continue;
        }
        NSString *playlistTitle = [NSString stringWithFormat:@" %@", [[db playlists] titleForList:i]];
        NSMenuItem *tempMenuItem = [[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(addToPlaylist:) keyEquivalent:@""];
        [tempMenuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        [tempMenuItem setRepresentedObject:i];
        [tempMenuItem setTarget:self];
        [playlistMenu_ addItem:tempMenuItem];
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
    if ([[[notification userInfo] valueForKey:@"playlist"] isEqual:[now currentList]]) {
        [self updateTableView];
        [nowPlayingTableView collapseItem:nil];
        if ([now currentIndex] != 0) {
            NSArray *parentItem = [self itemForItem:@[[NSNumber numberWithInt:0]]];
            [nowPlayingTableView expandItem:parentItem];
        }
    }
}

- (void)currentFileDidChange:(NSNotification *)notification {
    [(PROutlineView *)nowPlayingTableView reloadVisibleItems];
    if ([now currentIndex] != 0) {
        id currentItem = [self itemForDbRow:[now currentIndex]];
        NSArray *parentItem = [self itemForItem:@[[currentItem objectAtIndex:0]]];
        if (![nowPlayingTableView isItemExpanded:parentItem]) {
            [nowPlayingTableView collapseItem:nil];
        }
        [nowPlayingTableView expandItem:parentItem];
        [nowPlayingTableView scrollRowToVisiblePretty:[nowPlayingTableView rowForItem:currentItem]];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // save collapse state
    NSMutableIndexSet *collapseState = [NSMutableIndexSet indexSet];
    NSUInteger count = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
    for (NSUInteger i = 0; i < count; i++) {
        if ([nowPlayingTableView isItemExpanded:[self itemForItem:@[[NSNumber numberWithInt:i]]]]) {
            [collapseState addIndex:i];
        }
    }
    [[PRDefaults sharedDefaults] setValue:collapseState forKey:PRDefaultsNowPlayingCollapseState];
}

#pragma mark - Misc Priv

- (int)dbRowCount {
    return [_albumIndexes lastIndex] - 1;
}

- (NSRange)dbRangeForParentItem:(id)item {
    return NSMakeRange([[_dbRowForAlbum objectAtIndex:[[item objectAtIndex:0] intValue]] intValue], 
                       [[_albumCounts objectAtIndex:[[item objectAtIndex:0] intValue]] intValue]);
}

- (int)dbRowForItem:(id)item {
    if (!item) {
        return 0;
    } else if ([(NSArray *)item count] == 1) {
        return [[_dbRowForAlbum objectAtIndex:[[item objectAtIndex:0] intValue]] intValue];
    } else {
        return [[_dbRowForAlbum objectAtIndex:[[item objectAtIndex:0] intValue]] intValue] + [[item objectAtIndex:1] intValue];
    }
}

- (int)countForAlbum:(int)album {
    return [[_albumCounts objectAtIndex:album] intValue];
}

- (id)itemForDbRow:(int)row {
    NSInteger i = [_albumIndexes firstIndex];
    NSInteger prevI = 0;
    int album = 0;
    while (i != NSNotFound) {
        if (i > row) {
            break;
        }
        album++;
        prevI = i;
        i = [_albumIndexes indexGreaterThanIndex:i];
    }
    NSArray *item = [NSArray arrayWithObjects:
                     [NSNumber numberWithInt:album-1],
                     [NSNumber numberWithInt:row - prevI], nil];
    return [self itemForItem:item];
}

- (id)itemForItem:(id)item {
    NSString *key;
    id new;
    if ([(NSArray *)item count] == 1) {
        key = [NSString stringWithFormat:@"%d",[[item objectAtIndex:0] intValue]];
        new = [_parentItems objectForKey:key];
        if (!new) {
            [_parentItems setObject:item forKey:key];
            new = item;
        }
    } else {
        key = [NSString stringWithFormat:@"%d-%d",[[item objectAtIndex:0] intValue], [[item objectAtIndex:1] intValue]];
        new = [_childItems objectForKey:key];
        if (!new) {
            [_childItems setObject:item forKey:key];
            new = item;
        }
    }
    return new;
}

- (NSIndexSet *)selectedDbRows {
    NSMutableIndexSet *selectedDbRows = [NSMutableIndexSet indexSet];
    NSIndexSet *selectedRowIndexes = [nowPlayingTableView selectedRowIndexes];
    NSInteger selectedRow = [selectedRowIndexes firstIndex];
    while (selectedRow != NSNotFound) {
        NSArray *item = [nowPlayingTableView itemAtRow:selectedRow];
        if ([item count] == 2) {
            [selectedDbRows addIndex:[self dbRowForItem:item]];
        } else {
            [selectedDbRows addIndexesInRange:NSMakeRange([self dbRowForItem:item], [self countForAlbum:[[item objectAtIndex:0] intValue]])];
        }
        selectedRow = [selectedRowIndexes indexGreaterThanIndex:selectedRow];
    }
    return selectedDbRows;
}

#pragma mark - OutlineView Delegate

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    [cell setHighlighted:[[outlineView selectedRowIndexes] containsIndex:[outlineView rowForItem:item]]];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([(NSArray *)item count] == 1) {
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
    if ([(NSArray *)item count] == 1) {
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
    NSArray *item = item_;
    if (index == NSOutlineViewDropOnItemIndex) {
        return NSDragOperationNone;
    }
    if ([item count] == 1 && 
        (![nowPlayingTableView isItemExpanded:item] ||
         index == [[_albumCounts objectAtIndex:[[item objectAtIndex:0] intValue]] intValue])) {
        [nowPlayingTableView setDropItem:nil dropChildIndex:[[item objectAtIndex:0] intValue] + 1];
    }
    return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView *)view acceptDrop:(id<NSDraggingInfo>)info item:(id)item_ childIndex:(NSInteger)index {
    NSArray *item = item_;
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *filesData = [pboard dataForType:PRFilePboardType];
    if ([info draggingSource] == nowPlayingTableView) {
        // Moving
        NSIndexSet *dbIndexesToMove = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
        
        // Calculate the index at which to move dbIndexesToMove as dbIndexToInsert
        int dbIndexToInsert;
        if (!item) {
            dbIndexToInsert = [self dbRowForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:index], nil]];
        } else if ([item count] == 1) {
            dbIndexToInsert = [self dbRowForItem:item] + index;
        } else {
            dbIndexToInsert = 1;
        }
        // convert dbIndexToInsert to tempDbIndexToInsert
        int tempDbIndexToInsert = dbIndexToInsert;
        
        // Calculate collapsed/uncollapsed with dbIndexesToMove removed as tempAlbums
        int location = 1;
        int albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
        NSMutableArray *tempAlbums = [NSMutableArray array];
        NSString *prevArtist = @"";
        NSString *prevAlbum = @"";
        BOOL prevAlbumMissing = NO;
        for (int i = 0; i < albumCount; i++) {
            NSArray *item = [self itemForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil]];
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
            PRListItem *listItem = [[db playlists] itemAtIndex:range.location forList:[now currentList]];
            NSString *artist = [[db library] valueForItem:listItem attr:PRItemAttrArtist];
            NSString *album = [[db library] valueForItem:listItem attr:PRItemAttrAlbum];
            BOOL shouldMergeWithPrevAlbum = prevAlbumMissing && [artist noCaseCompare:prevArtist] == NSOrderedSame && [album noCaseCompare:prevAlbum] == NSOrderedSame;
            prevArtist = artist;
            prevAlbum = album;
            prevAlbumMissing = NO;
            int oldLocation = location;
            location += range.length - [dbIndexesToMove countOfIndexesInRange:range];
            if (shouldMergeWithPrevAlbum) {
                continue;
            }
            [tempAlbums addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:[nowPlayingTableView isItemExpanded:item]], @"expanded", 
                                   [NSValue valueWithRange:NSMakeRange(oldLocation, range.length - [dbIndexesToMove countOfIndexesInRange:range])], @"range", 
                                   [NSNumber numberWithInt:[dbIndexesToMove countOfIndexesInRange:range]], @"missing", nil]];
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
        [[db playlists] moveItemsAtIndexes:dbIndexesToMove toIndex:dbIndexToInsert inList:[now currentList]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
        [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [nowPlayingTableView collapseItem:nil];
        
        // Collapse/uncollapse using beforeArray and afterArray;
        albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < [beforeArray count]; i++) {
            id item = [self itemForItem:@[[NSNumber numberWithInt:i]]];
            if ([[beforeArray objectAtIndex:i] boolValue]) {
                [nowPlayingTableView expandItem:item];
            } else {
                [nowPlayingTableView collapseItem:item];
            }
        }
        for (int i = 0; i < [afterArray count]; i++) {
            id item = [self itemForItem:@[[NSNumber numberWithInt:albumCount - i - 1]]];
            if ([[afterArray objectAtIndex:i] boolValue]) {
                [nowPlayingTableView expandItem:item];
            } else {
                [nowPlayingTableView collapseItem:item];
            }
        }
    } else {
        // Adding
        NSArray *files = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
        int dbRow;
        if (!item) {
            dbRow = [self dbRowForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:index], nil]];
        } else if ([item count] == 1) {
            dbRow = [self dbRowForItem:item] + index;
        } else {
            dbRow = 1;
        }
        
        NSMutableArray *beforeArray = [NSMutableArray array];
        NSMutableArray *afterArray = [NSMutableArray array];
        int albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < albumCount; i++) {
            NSArray *item = [self itemForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil]];
            NSRange range = [self dbRangeForParentItem:item];
            if (range.location == dbRow) {
                break;
            }
            [beforeArray addObject:[NSNumber numberWithBool:[nowPlayingTableView isItemExpanded:item]]];
            if (NSLocationInRange(dbRow, range)) {
                break;
            }
        }
        if (dbRow <= [self dbRowCount]) {
            for (int i = albumCount - 1; i >= 0 ; i--) {
                NSArray *item = [self itemForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil]];
                [afterArray addObject:[NSNumber numberWithBool:[nowPlayingTableView isItemExpanded:item]]];
                NSRange range = [self dbRangeForParentItem:item];
                if (NSLocationInRange(dbRow, range)) {
                    break;
                }
            }
        }
        
        // Checks if adding single album
        BOOL singleAlbum = YES;
        if ([files count] > 1) {
            NSString *artist = [[db library] artistValueForItem:[files objectAtIndex:0]];
            NSString *album = [[db library] valueForItem:[files objectAtIndex:0] attr:PRItemAttrAlbum];
            for (NSNumber *i in files) {
                NSString *nextArtist = [[db library] artistValueForItem:i];
                NSString *nextAlbum = [[db library] valueForItem:i attr:PRItemAttrAlbum];
                if (![artist isEqualToString:nextArtist] || ![album isEqualToString:nextAlbum]) {
                    singleAlbum = NO;
                }
            }
        }
        
        [[db playlists] addItems:files atIndex:dbRow toList:[now currentList]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
        [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [nowPlayingTableView collapseItem:nil];
        
        albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < [beforeArray count]; i++) {
            id item = [self itemForItem:@[[NSNumber numberWithInt:i]]];
            if ([[beforeArray objectAtIndex:i] boolValue]) {
                [nowPlayingTableView expandItem:item];
            } else {
                [nowPlayingTableView collapseItem:item];
            }
        }
        for (int i = 0; i < [afterArray count]; i++) {
            id item = [self itemForItem:@[[NSNumber numberWithInt:albumCount - i - 1]]];
            if ([[afterArray objectAtIndex:i] boolValue]) {
                [nowPlayingTableView expandItem:item];
            } else {
                [nowPlayingTableView collapseItem:item];
            }
        }
        
        if (singleAlbum) {
            id item = [self itemForItem:@[[NSNumber numberWithInt:[beforeArray count]]]];
            [nowPlayingTableView expandItem:item];
        }
    }
    return YES;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    [[NSCursor arrowCursor] set];
    if (operation == 0 && !NSMouseInRect([nowPlayingTableView convertPointFromBase:[[nowPlayingTableView window] convertScreenToBase:dropPoint]], [nowPlayingTableView bounds], YES)) {
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, dropPoint, NSZeroSize, nil, nil, nil);
        [self removeSelected];
    }
}

- (void)draggedImage:(NSImage *)anImage movedTo:(NSPoint)point {
    dropPoint = [NSEvent mouseLocation];
    if (!NSMouseInRect([nowPlayingTableView convertPointFromBase:[[nowPlayingTableView window] convertScreenToBase:dropPoint]], [nowPlayingTableView bounds], YES)) {
        [[NSCursor disappearingItemCursor] set];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

#pragma mark - OutlineView DataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([(NSArray *)item count] == 1) {
        return YES;
    }
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
        return [_albumCounts count];
    } else if ([(NSArray *)item count] == 1) {
        return [[_albumCounts objectAtIndex:[[item objectAtIndex:0] intValue]] intValue];
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([(NSArray *)item count] == 1) {
        int row = [self dbRowForItem:item];
        PRItem *it = [[db nowPlayingViewSource] itemForRow:row];
        NSString *album =  [[db library] valueForItem:it attr:PRItemAttrAlbum];
        NSString *artist = [[db library] valueForItem:it attr:PRItemAttrArtist];
        if ([artist isEqualToString:@""]) {
            artist = @"Unknown Artist";
        }
        if ([album isEqualToString:@""]) {
            album = @"Unknown Album";
        }
        if ([[[db library] valueForItem:it attr:PRItemAttrCompilation] boolValue] && [[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]) {
            artist = @"Compilation";
        }
        NSNumber *drawBorder = [NSNumber numberWithBool:[[item objectAtIndex:0] intValue] + 1 == [_albumCounts count] || [nowPlayingTableView isItemExpanded:item]];
        return @{@"title":artist, @"subtitle":album, @"item":item, @"drawBorder":drawBorder, @"target":self};
    } else {
        int row = [self dbRowForItem:item];
        PRItem *it = [[db nowPlayingViewSource] itemForRow:row];
        NSString *title = [[db library] valueForItem:it attr:PRItemAttrTitle];
        NSImage *icon;
        NSImage *invertedIcon;
        if ([now currentIndex] == row) {
            icon = [NSImage imageNamed:@"PRSpeakerIcon"];
            invertedIcon = [NSImage imageNamed:@"PRLightSpeakerIcon"];
        } else if ([[now invalidItems] containsObject:it]) {
            icon = [NSImage imageNamed:@"Exclamation Point"];
            invertedIcon = [NSImage imageNamed:@"Exclamation Point"];
        } else {
            icon = [[NSImage alloc] init];
            invertedIcon = [[NSImage alloc] init];
        }
        PRListItem *listItem = [[db playlists] listItemAtIndex:row inList:[now currentList]];
        NSUInteger queueIndex = [[[db queue] queueArray] indexOfObject:listItem];
        NSNumber *badge;
        if (queueIndex != NSNotFound) {
            badge = @(queueIndex + 1);
        } else {
            badge = @0;
        }
        return @{@"title":title, @"icon":icon, @"invertedIcon":invertedIcon, @"badge":badge, @"item":item, @"target":self};
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    NSArray *newItem;
    if (!item) {
        newItem = @[@(index)];
    } else {
        newItem = @[item[0], @(index)];
    }
    return [self itemForItem:newItem];
}

#pragma mark - PROutlineView Delegate

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
            [[_core now] playNext];
            didHandle = YES;
        } else if (c == 0xf702) {
            [[_core now] playPrevious];
            didHandle = YES;
        }
    }
    return didHandle;
}

#pragma mark - Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _contextMenu) {
        [self contextMenuNeedsUpdate];
    } else {
        [self playlistMenuNeedsUpdate];
    }
}

@end
