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
#import "PRUserDefaults.h"
#import "PRQueue.h"
#import "NSIndexSet+Extensions.h"
#import "PROutlineView.h"
#import "PRMoviePlayer.h"
#import "PRCore.h"
#import "PRTableViewController.h"
#import "NSMenuItem+Extensions.h"
#import "NSTableView+Extensions.h"
#import "NSColor+Extensions.h"
#import "MAZeroingWeakRef.h"


@interface PRNowPlayingViewController () 
// TableView Actions
- (void)playItem:(id)item;
- (void)playSelected;
- (void)removeSelected;
- (void)addSelectedToQueue;
- (void)removeSelectedFromQueue;
- (void)addToPlaylist:(id)sender;
- (IBAction)delete:(id)sender;
- (void)showInLibrary;
- (void)revealInFinder;

// PlaylistMenu Actions
- (void)clearPlaylist;
- (void)saveAsPlaylist:(id)sender;
- (void)newPlaylist:(id)sender;

// Update
- (void)updateTableView;
- (void)playlistDidChange:(NSNotification *)notification;
- (void)currentFileDidChange:(NSNotification *)notification;

// Menu
- (void)playlistMenuNeedsUpdate;
- (void)contextMenuNeedsUpdate;

// Misc
- (int)dbRowCount;
- (NSRange)dbRangeForParentItem:(id)item;
- (int)dbRowForItem:(id)item;
- (id)itemForDbRow:(int)row;
- (id)itemForItem:(id)item;
- (NSIndexSet *)selectedDbRows;
@end


@implementation PRNowPlayingViewController

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _parentItems = [[NSMutableDictionary alloc] init];
    _childItems = [[NSMutableDictionary alloc] init];
    _core = core;
    db = [core db];;
    now = [core now];
    win = [core win];
    return self;
}

- (void)loadView {
    PRGradientView *background = [[[PRGradientView alloc] initWithFrame:NSMakeRect(0, 0, 210, 500)] autorelease];
    [background setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [background setColor:[NSColor PRSidebarBackgroundColor]];
    [background setAltColor:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    [self setView:background];
    
    scrollview = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 210, 501)];
    [scrollview setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [scrollview setFocusRingType:NSFocusRingTypeNone];
    [scrollview setDrawsBackground:FALSE];
    [scrollview setBorderType:NSNoBorder];
    [scrollview setAutohidesScrollers:TRUE];
    [[self view] addSubview:scrollview];
    
    NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"column"] autorelease];
    nowPlayingTableView = [[PROutlineView alloc] initWithFrame:NSMakeRect(0, 0, 210, 500)];
    [nowPlayingTableView setFocusRingType:NSFocusRingTypeNone];
    [nowPlayingTableView setBackgroundColor:[NSColor transparent]];
    [nowPlayingTableView setHeaderView:nil];
    [nowPlayingTableView setAllowsMultipleSelection:TRUE];
    [nowPlayingTableView setDoubleAction:@selector(play)];
    [nowPlayingTableView setIntercellSpacing:NSMakeSize(0, 0)];
    [nowPlayingTableView setTarget:self];
    [nowPlayingTableView setDataSource:self];
    [nowPlayingTableView setDelegate:self]; 
    [nowPlayingTableView registerForDraggedTypes:[NSArray arrayWithObject:PRFilePboardType]];
    [nowPlayingTableView setVerticalMotionCanBeginDrag:FALSE];
    [nowPlayingTableView setAutoresizesOutlineColumn:FALSE];
    [nowPlayingTableView addTableColumn:column];
    [nowPlayingTableView setOutlineTableColumn:column];
    [scrollview setDocumentView:nowPlayingTableView];
    
    // header view
    _headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 50, 30)];
    
    _playlistMenu = [[NSMenu alloc] init];
    [_playlistMenu setAutoenablesItems:FALSE];
    [_playlistMenu setDelegate:self];
    _menuButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(18, 3, 25, 25)];
    [[_menuButton cell] setArrowPosition:NSPopUpNoArrow];
    [_menuButton setMenu:_playlistMenu];
    [_menuButton setPullsDown:TRUE];
    [_menuButton setBordered:FALSE];
    [_headerView addSubview:_menuButton];
    
    _clearButton = [[NSButton alloc] initWithFrame:NSMakeRect(1, 3, 25, 25)];
    [_clearButton setImage:[NSImage imageNamed:@"Trash"]];
    [_clearButton setBordered:FALSE];
    [_clearButton setTarget:self];
    [_clearButton setAction:@selector(clearPlaylist)];
    [_clearButton setButtonType:NSMomentaryChangeButton];
    [_headerView addSubview:_clearButton];
    
    // context menu
    _contextMenu = [[NSMenu alloc] init];
    [_contextMenu setDelegate:self];
    [_contextMenu setAutoenablesItems:FALSE];
    [nowPlayingTableView setMenu:_contextMenu];
        
    // playlist and current file obs
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(updateTableView)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(currentFileDidChange:)];
    
    [self playlistMenuNeedsUpdate];
    [self updateTableView];
    [nowPlayingTableView collapseItem:nil];
    NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:0]]];
    [nowPlayingTableView expandItem:parentItem];
}

// ========================================
// Accessors

@synthesize headerView = _headerView;

// ========================================
// Action

- (void)higlightPlayingFile {
    if (![now currentItem]) {
        return;
    }
    id currentItem = [self itemForDbRow:[now currentIndex]];
    NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[currentItem objectAtIndex:0]]];
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
    BOOL singleAlbum = TRUE;
    if ([files count] > 1) {
        NSString *artist = [[db library] artistValueForItem:[files objectAtIndex:0]];
        NSString *album = [[db library] valueForItem:[files objectAtIndex:0] attr:PRItemAttrAlbum];
        for (NSNumber *i in files) {
            NSString *nextArtist = [[db library] artistValueForItem:i];
            NSString *nextAlbum = [[db library] valueForItem:i attr:PRItemAttrAlbum];
            if (![artist isEqualToString:nextArtist] || ![album isEqualToString:nextAlbum]) {
                singleAlbum = FALSE;
            }
        }
    }
    
    [[db playlists] addItems:files atIndex:dbRow toList:[now currentList]];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
    [nowPlayingTableView collapseItem:nil];
    
    albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
    for (int i = 0; i < [beforeArray count]; i++) {
        id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:i]]];
        if ([[beforeArray objectAtIndex:i] boolValue]) {
            [nowPlayingTableView expandItem:item];
        } else {
            [nowPlayingTableView collapseItem:item];
        }
    }
    for (int i = 0; i < [afterArray count]; i++) {
        id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:albumCount - i - 1]]];
        if ([[afterArray objectAtIndex:i] boolValue]) {
            [nowPlayingTableView expandItem:item];
        } else {
            [nowPlayingTableView collapseItem:item];
        }
    }
    
    if (singleAlbum) {
        id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:[beforeArray count]]]];
        [nowPlayingTableView expandItem:item];
    }
}

// ========================================
// action

- (void)play {
    if ([nowPlayingTableView clickedRow] == -1) {
        return;
    }
    id item = [nowPlayingTableView itemAtRow:[nowPlayingTableView clickedRow]];
    [self playItem:item];
    int row = [nowPlayingTableView rowForItem:item];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
}

- (void)playItem:(id)item {
    int dbRow = [self dbRowForItem:item];
    [now playItemAtIndex:dbRow];
}

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

- (IBAction)delete:(id)sender {
    [self removeSelected];
}

- (void)saveAsPlaylist:(id)sender {
    int playlist = [[sender representedObject] intValue];
    NSString *title = [[db playlists] titleForList:[NSNumber numberWithInt:playlist]];
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to save this as \"%@\"?", title]];
    [alert setInformativeText:@"Existing playlist contents will be removed."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[win window] modalDelegate:self didEndSelector:@selector(saveAsPlaylistHandler:code:context:) contextInfo:[NSNumber numberWithInt:playlist]];
}

- (void)saveAsPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context {
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    PRList *list = context;
    [[db playlists] clearList:list];
    [[db playlists] copyItemsFromList:[now currentList] toList:list];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

- (void)newPlaylist:(id)sender {
    [[win playlistsViewController] duplicatePlaylist:[[now currentList] intValue]];
}

// ========================================
// menu Action

- (void)playSelected {
    if ([[self selectedDbRows] count] == 0) {
        return;
    }
    [now playItemAtIndex:[[self selectedDbRows] firstIndex]];
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

- (void)revealInFinder {
    NSIndexSet *dbRows = [self selectedDbRows];
    if ([dbRows count] == 0) {
        return;
    }
    PRItem *item = [[db playlists] itemAtIndex:[dbRows firstIndex] forList:[now currentList]];
    NSString *path = [[db library] valueForItem:item attr:PRItemAttrPath];
    [[NSWorkspace sharedWorkspace] selectFile:[[NSURL URLWithString:path] path] inFileViewerRootedAtPath:nil];
}

- (void)showInLibrary {
    NSIndexSet *dbRows = [self selectedDbRows];
    if ([dbRows count] == 0) {
        return;
    }
    PRItem *item = [[db playlists] itemAtIndex:[dbRows firstIndex] forList:[now currentList]];
    [win setCurrentMode:PRLibraryMode];
    [[win libraryViewController] setCurrentList:[[db playlists] libraryList]];
    [[[win libraryViewController] currentViewController] highlightFile:[item intValue]];
}

- (void)removeSelected {
    NSIndexSet *dbRows = [self selectedDbRows];
    
    int albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
    NSMutableArray *array = [NSMutableArray array];
    BOOL prevAlbumMissing = FALSE;
    for (int i = 0; i < albumCount; i++) {
        NSArray *item = [self itemForItem:[NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil]];
        NSRange range = [self dbRangeForParentItem:item];
        if (range.length == [dbRows countOfIndexesInRange:range]) {
            prevAlbumMissing = TRUE;
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
            prevAlbumMissing = FALSE;
        }
    }
    
    if ([dbRows containsIndex:[now currentIndex]]) {
        [now stop];
    }
    [[db playlists] removeItemsAtIndexes:dbRows fromList:[now currentList]];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
    
    for (int i = 0; i < [array count]; i++) {
        if ([[[array objectAtIndex:i] objectForKey:@"expanded"] boolValue]) {
            [nowPlayingTableView expandItem:[self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:i]]]];
        } else {
            [nowPlayingTableView collapseItem:[self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:i]]]];
        }
    }
}

// ========================================
// update

- (void)updateTableView {
    // refresh nowPlayingViewSource
    [[db nowPlayingViewSource] refresh];
    
    // refresh tableIndexes
    [_parentItems removeAllObjects];
    [_childItems removeAllObjects];
    
    [_albumCounts release];
    _albumCounts = [[[db nowPlayingViewSource] albumCounts] retain];
    [_dbRowForAlbum release];
    _dbRowForAlbum = [[NSMutableArray array] retain];
    [_albumIndexes release];
    _albumIndexes = [[NSMutableIndexSet indexSet] retain];
    
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

- (void)playlistDidChange:(NSNotification *)notification {
    if ([[[notification userInfo] valueForKey:@"playlist"] isEqual:[now currentList]]) {
        [self updateTableView];
        [nowPlayingTableView collapseItem:nil];
        if ([now currentIndex] != 0) {
            NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:0]]];
            [nowPlayingTableView expandItem:parentItem];
        }
    }
}

- (void)currentFileDidChange:(NSNotification *)notification {
    [(PROutlineView *)nowPlayingTableView reloadVisibleItems];
    if ([now currentIndex] != 0) {
        id currentItem = [self itemForDbRow:[now currentIndex]];
        NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[currentItem objectAtIndex:0]]];
        if (![nowPlayingTableView isItemExpanded:parentItem]) {
            [nowPlayingTableView collapseItem:nil];
        }
        [nowPlayingTableView expandItem:parentItem];
        [nowPlayingTableView scrollRowToVisiblePretty:[nowPlayingTableView rowForItem:currentItem]];
    }
}

// ========================================
// menu

- (void)playlistMenuNeedsUpdate {
    NSMenu *menu = _playlistMenu;
    for (NSMenuItem *i in [menu itemArray]) {
        [menu removeItem:i];
    }
    // Title of the popup button
    NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
    [menuItem setImage:[NSImage imageNamed:@"Settings"]];
    [menu addItem:menuItem];
    
    // Save
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Save as..." action:nil keyEquivalent:@""] autorelease];
    [menuItem setEnabled:FALSE];
    [menu addItem:menuItem];
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:@" New Playlist          " action:@selector(newPlaylist:) keyEquivalent:@""] autorelease];
    [menuItem setImage:[NSImage imageNamed:@"Add"]];
    [menu addItem:menuItem];
    
    NSArray *playlistArray = [[db playlists] lists];
    for (NSNumber *i in playlistArray) {
        if (![[[db playlists] typeForList:i] isEqual:PRListTypeStatic]) {
            continue;
        }
        NSString *playlistTitle = [NSString stringWithFormat:@" %@", [[db playlists] titleForList:i]];
        menuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(saveAsPlaylist:) keyEquivalent:@""] autorelease];
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
    MAZeroingWeakRef *selfRef = [MAZeroingWeakRef refWithTarget:self];
    
    NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
    [item setTitle:@"Play"];
    [item setKeyEquivalent:[NSString stringWithCharacters:c length:1]];
    [item setKeyEquivalentModifierMask:0];
    [item setActionBlock:^{[[selfRef target] playSelected];}];
    [_contextMenu addItem:item];
    
    // Queue
    BOOL addToQueue = FALSE;
    BOOL removeFromQueue = FALSE;
    
    NSArray *queue = [[db queue] queueArray];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        PRListItem *listItem = [[db playlists] listItemAtIndex:dbRow inList:[now currentList]];
        if ([queue containsObject:listItem]) {
            removeFromQueue = TRUE;
        } else {
            addToQueue = TRUE;
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
    NSMenuItem *playlistMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Add to Playlist" action:nil keyEquivalent:@""] autorelease];
    NSMenu *playlistMenu_ = [[[NSMenu alloc] init] autorelease];
    [playlistMenuItem setSubmenu:playlistMenu_];
    [_contextMenu addItem:playlistMenuItem];
    
    NSArray *playlistArray = [[db playlists] lists];
    for (NSNumber *i in playlistArray) {
        if (![[[db playlists] typeForList:i] isEqual:PRListTypeStatic]) {
            continue;
        }
        NSString *playlistTitle = [NSString stringWithFormat:@" %@", [[db playlists] titleForList:i]];
        NSMenuItem *tempMenuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(addToPlaylist:) keyEquivalent:@""] autorelease];
        [tempMenuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        [tempMenuItem setRepresentedObject:i];
        [tempMenuItem setTarget:self];
        [playlistMenu_ addItem:tempMenuItem];
    }
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // Other
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Show in Library" action:@selector(showInLibrary) keyEquivalent:@""];
    [menuItem setTarget:self];
    [_contextMenu addItem:menuItem];
    menuItem = [[NSMenuItem alloc] initWithTitle:@"Reveal in Finder" action:@selector(revealInFinder) keyEquivalent:@""];
    [menuItem setTarget:self];
    [_contextMenu addItem:menuItem];
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    c[0] = NSDeleteCharacter;;
    item = [[[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeSelected) keyEquivalent:[NSString stringWithCharacters:c length:1]] autorelease];
    [item setTarget:self];
    [item setKeyEquivalentModifierMask:0];
    [_contextMenu addItem:item];
}

// ========================================
// misc

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

// ========================================
// OutlineView Delegate

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
    return FALSE;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return TRUE;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    static NSCell *nowPlayingCell = nil;
    static NSCell *nowPlayingHeaderCell = nil;
    if (!nowPlayingCell || ! nowPlayingHeaderCell) {
        nowPlayingCell = [[PRNowPlayingCell alloc] initTextCell:@""];
        nowPlayingHeaderCell = [[PRNowPlayingHeaderCell alloc] initTextCell:@""];
    }
    if ([(NSArray *)item count] == 1) {
        return nowPlayingHeaderCell;
    }
    return nowPlayingCell;
}

// ========================================
// OutlineView DragAndDrop

- (BOOL)outlineView:(NSOutlineView *)view writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self selectedDbRows]];
    [pboard declareTypes:[NSArray arrayWithObject:PRFilePboardType] owner:self];
    [pboard setData:data forType:PRFilePboardType];
    return TRUE;
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
        BOOL prevAlbumMissing = FALSE;
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
                prevAlbumMissing = TRUE;
                continue;
            }
            PRListItem *listItem = [[db playlists] itemAtIndex:range.location forList:[now currentList]];
            NSString *artist = [[db library] valueForItem:listItem attr:PRItemAttrArtist];
            NSString *album = [[db library] valueForItem:listItem attr:PRItemAttrAlbum];
            BOOL shouldMergeWithPrevAlbum = prevAlbumMissing && [artist noCaseCompare:prevArtist] == NSOrderedSame && [album noCaseCompare:prevAlbum] == NSOrderedSame;
            prevArtist = artist;
            prevAlbum = album;
            prevAlbumMissing = FALSE;
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
        [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        [nowPlayingTableView collapseItem:nil];
        
        // Collapse/uncollapse using beforeArray and afterArray;
        albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < [beforeArray count]; i++) {
            id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:i]]];
            if ([[beforeArray objectAtIndex:i] boolValue]) {
                [nowPlayingTableView expandItem:item];
            } else {
                [nowPlayingTableView collapseItem:item];
            }
        }
        for (int i = 0; i < [afterArray count]; i++) {
            id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:albumCount - i - 1]]];
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
        BOOL singleAlbum = TRUE;
        if ([files count] > 1) {
            NSString *artist = [[db library] artistValueForItem:[files objectAtIndex:0]];
            NSString *album = [[db library] valueForItem:[files objectAtIndex:0] attr:PRItemAttrAlbum];
            for (NSNumber *i in files) {
                NSString *nextArtist = [[db library] artistValueForItem:i];
                NSString *nextAlbum = [[db library] valueForItem:i attr:PRItemAttrAlbum];
                if (![artist isEqualToString:nextArtist] || ![album isEqualToString:nextAlbum]) {
                    singleAlbum = FALSE;
                }
            }
        }
        
        [[db playlists] addItems:files atIndex:dbRow toList:[now currentList]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
        [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        [nowPlayingTableView collapseItem:nil];
        
        albumCount = [self outlineView:nowPlayingTableView numberOfChildrenOfItem:nil];
        for (int i = 0; i < [beforeArray count]; i++) {
            id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:i]]];
            if ([[beforeArray objectAtIndex:i] boolValue]) {
                [nowPlayingTableView expandItem:item];
            } else {
                [nowPlayingTableView collapseItem:item];
            }
        }
        for (int i = 0; i < [afterArray count]; i++) {
            id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:albumCount - i - 1]]];
            if ([[afterArray objectAtIndex:i] boolValue]) {
                [nowPlayingTableView expandItem:item];
            } else {
                [nowPlayingTableView collapseItem:item];
            }
        }
        
        if (singleAlbum) {
            id item = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:[beforeArray count]]]];
            [nowPlayingTableView expandItem:item];
        }
    }
    return TRUE;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    [[NSCursor arrowCursor] set];
    if (operation == 0 && !NSMouseInRect([nowPlayingTableView convertPointFromBase:[[nowPlayingTableView window] convertScreenToBase:dropPoint]], [nowPlayingTableView bounds], TRUE)) {
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, dropPoint, NSZeroSize, nil, nil, nil);
        [self removeSelected];
    }
}

- (void)draggedImage:(NSImage *)anImage movedTo:(NSPoint)point {
    dropPoint = [NSEvent mouseLocation];
    if (!NSMouseInRect([nowPlayingTableView convertPointFromBase:[[nowPlayingTableView window] convertScreenToBase:dropPoint]], [nowPlayingTableView bounds], TRUE)) {
        [[NSCursor disappearingItemCursor] set];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

// ========================================
// OutlineView DataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([(NSArray *)item count] == 1) {
        return TRUE;
    }
    return FALSE;
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
        NSNumber *drawBorder = [NSNumber numberWithBool:[[item objectAtIndex:0] intValue] + 1 == [_albumCounts count] || [nowPlayingTableView isItemExpanded:item]];
        return [NSDictionary dictionaryWithObjectsAndKeys:
                artist, @"title",
                album, @"subtitle", 
                item, @"item",
                drawBorder, @"drawBorder", 
                self, @"target", nil];
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
            icon = [[[NSImage alloc] init] autorelease];
            invertedIcon = [[[NSImage alloc] init] autorelease];
        }
        PRListItem *listItem = [[db playlists] listItemAtIndex:row inList:[now currentList]];
        NSUInteger queueIndex = [[[db queue] queueArray] indexOfObject:listItem];
        NSNumber *badge;
        if (queueIndex != NSNotFound) {
            badge = [NSNumber numberWithInt:queueIndex + 1];
        } else {
            badge = [NSNumber numberWithInt:0];
        }
        return [NSDictionary dictionaryWithObjectsAndKeys:
                title, @"title",
                icon, @"icon", 
                invertedIcon, @"invertedIcon", 
                badge, @"badge",
                item, @"item",
                self, @"target", nil];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    NSArray *newItem;
    if (!item) {
        newItem = [NSArray arrayWithObjects:[NSNumber numberWithInt:index], nil];
    } else {
        newItem = [NSArray arrayWithObjects:[item objectAtIndex:0], [NSNumber numberWithInt:index], nil];
    }
    return [self itemForItem:newItem];
}

// ========================================
// PROutlineView Delegate

- (BOOL)outlineView:(PROutlineView *)outlineView keyDown:(NSEvent *)event {
    if ([[event characters] length] != 1) {
        return FALSE;
    }
    BOOL didHandle = FALSE;
    NSUInteger flags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    UniChar c = [[event characters] characterAtIndex:0];
    if (flags == 0) {
        if (c == 0x20) {
            [now playPause];
            didHandle = TRUE;
        } else if (c == 0x7F || c == 0xf728) {
            [self delete:nil];
            didHandle = TRUE;
        } else if (c == 0xd) {
            [self playSelected];
            didHandle = TRUE;
        }
    } else if (flags == (NSNumericPadKeyMask | NSFunctionKeyMask)) {
        if (c == 0xf703) {
            [now playNext];
            didHandle = TRUE;
        } else if (c == 0xf702) {
            [now playPrevious];
            didHandle = TRUE;
        }
    }
    return didHandle;
}

// ========================================
// Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == _contextMenu) {
        [self contextMenuNeedsUpdate];
    } else {
        [self playlistMenuNeedsUpdate];
    }
}

@end
