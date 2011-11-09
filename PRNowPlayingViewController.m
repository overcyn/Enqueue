#import "PRNowPlayingViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
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

@implementation PRNowPlayingViewController

// ========================================
// Initialization
// ========================================

- (id)      initWithDb:(PRDb *)db_ 
  nowPlayingController:(PRNowPlayingController *)now_ 
  mainWindowController:(PRMainWindowController *)mainWindowController_
{
    self = [super initWithNibName:@"PRNowPlayingView" bundle:nil];
    if (!self) {
        return nil;
    }
    
    _parentItems = [[NSMutableDictionary dictionary] retain];
    _childItems = [[NSMutableDictionary dictionary] retain];
    db = [db_ retain];
    now = [now_ retain];
    win = [mainWindowController_ retain];
    return self;
}

- (void)dealloc
{
    [now removeObserver:self forKeyPath:@"shuffle"];
    [now removeObserver:self forKeyPath:@"repeat"];
    [now removeObserver:self forKeyPath:@"currentPlaylist"];
    [now removeObserver:self forKeyPath:@"currentIndex"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [playlistMenu release];
    [db release];
    [now release];
    [win release];
    [super dealloc];
}

- (void)awakeFromNib
{
    // background    
    [backgroundGradient setTopGradient:[NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0]];
    [backgroundGradient setBotGradient:[NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0]];
    [backgroundGradient setAltTopGradient:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    [backgroundGradient setAltBotGradient:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    
    [barGradient setColor:[NSColor colorWithCalibratedRed:234./255. green:238./255. blue:244./255. alpha:1.0]];
    [barGradient setTopBorder:[NSColor colorWithCalibratedWhite:0.65 alpha:1.0]];
    [barGradient setTopBorder2:[NSColor colorWithCalibratedWhite:0.97 alpha:1.0]];
    
    [divider1 setColor:[NSColor colorWithCalibratedWhite:0.7 alpha:1.0]];
    [divider2 setColor:[NSColor colorWithCalibratedWhite:0.7 alpha:1.0]];
        
    // LibraryTableView
    [nowPlayingTableView setDoubleAction:@selector(play)];
    [nowPlayingTableView setIntercellSpacing:NSMakeSize(0, 0)];
    [nowPlayingTableView setTarget:self];
    [nowPlayingTableView setDataSource:self];
    [nowPlayingTableView setDelegate:self]; 
    [nowPlayingTableView registerForDraggedTypes:[NSArray arrayWithObject:PRFilePboardType]];
    [nowPlayingTableView setVerticalMotionCanBeginDrag:FALSE];
    [nowPlayingTableView setAutoresizesOutlineColumn:FALSE];
//    [nowPlayingTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:TRUE];
//    [nowPlayingTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:FALSE];
//    [nowPlayingTableView setSlideback:FALSE];
//    [nowPlayingTableView setHighlightColor:[NSColor alternateSelectedControlColor]];
//    [nowPlayingTableView setSecondaryHighlightColor:[NSColor colorWithCalibratedRed:134./255 green:151./255 blue:185./255 alpha:0.7]];
        
    // context menu
    _contextMenu = [[NSMenu alloc] init];
    [_contextMenu setDelegate:self];
    [nowPlayingTableView setMenu:_contextMenu];
    
    // playlist menu
    playlistMenu = [[NSMenu alloc] init];
    [playlistMenu setDelegate:self];
    [playlistMenu setAutoenablesItems:FALSE];
    [settingsButton setMenu:playlistMenu];
        
    // clear buttons
    [clearButton setTarget:self];
    [clearButton setAction:@selector(clearPlaylist)];
    
    // volume slider
    [volumeSlider setMaxValue:1];
    [volumeSlider setMinValue:0];
    [volumeSlider bind:@"value" toObject:now withKeyPath:@"mov.volume" options:nil];
    [speakerButton setTarget:self];
    [speakerButton setAction:@selector(mute)];
    
    _nowPlayingCell = [[PRNowPlayingCell alloc] initTextCell:@""];
    _nowPlayingHeaderCell = [[PRNowPlayingHeaderCell alloc] initTextCell:@""];
        
    // playlist and current file obs
    [[NSNotificationCenter defaultCenter] observeFilesChanged:self sel:@selector(updateTableView)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(currentFileDidChange:)];
    [[NSNotificationCenter defaultCenter] observeVolumeChanged:self sel:@selector(volumeChanged:)];
    
    [self volumeChanged:nil];
    
    [self updateTableView];
    [nowPlayingTableView collapseItem:nil];
    NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:0]]];
    [nowPlayingTableView expandItem:parentItem];
}

// ========================================
// Action
// ========================================

- (void)play
{
    if ([nowPlayingTableView clickedRow] == -1) {
        return;
    }
    id item = [nowPlayingTableView itemAtRow:[nowPlayingTableView clickedRow]];
    [self playItem:item];
    int row = [nowPlayingTableView rowForItem:item];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
}

- (void)playItem:(id)item
{
    int dbRow = [self dbRowForItem:item];
    [now playItemAtIndex:dbRow];
}

- (void)clearPlaylist
{
    int count = [[db playlists] countForPlaylist:[now currentPlaylist]];
    if (count == 1 || [now currentIndex] == 0) {
        // if nothing playing or count == 1, clear playlist
        [now stop];
        [[db playlists] clearPlaylist:[now currentPlaylist]];
    } else {
        // otherwise delete all previous songs
        [[db playlists] clearPlaylist:[now currentPlaylist] exceptForIndex:[now currentIndex]];
    }
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
    [nowPlayingTableView expandItem:nil];
}

- (IBAction)delete:(id)sender
{
    [self removeSelected];
}

- (void)saveAsPlaylist:(id)sender
{
    int playlist = [[sender representedObject] intValue];
    NSString *title = [[db playlists] titleForPlaylist:playlist];
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to save this as \"%@\"?", title]];
    [alert setInformativeText:@"Existing playlist contents will be removed."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[win window] modalDelegate:self didEndSelector:@selector(saveAsPlaylistHandler:code:context:) contextInfo:[NSNumber numberWithInt:playlist]];
}

- (void)saveAsPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context
{
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    int playlist = [(NSNumber *)context intValue];
    [[db playlists] clearPlaylist:playlist];
    [[db playlists] copyFilesFromPlaylist:[now currentPlaylist] toPlaylist:playlist];
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:playlist];
}

- (void)newPlaylist:(id)sender
{
    PRPlaylist playlist = [[db playlists] addStaticPlaylist];
    [[db playlists] copyFilesFromPlaylist:[now currentPlaylist] toPlaylist:playlist];
    [[NSNotificationCenter defaultCenter] postPlaylistsChanged];
    
    [win setCurrentMode:PRPlaylistsMode];
    [[win playlistsViewController] renamePlaylist:playlist];
}

- (void)mute
{
    [[now mov] setVolume:0];
}

// ========================================
// Menu Action
// ========================================

- (void)playSelected
{
    if ([[self selectedDbRows] count] == 0) {
        return;
    }
    [now playItemAtIndex:[[self selectedDbRows] firstIndex]];
}

- (void)addSelectedToQueue
{
    [self removeSelectedFromQueue];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        if (dbRow != [now currentIndex]) {
            PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:dbRow inPlaylist:[now currentPlaylist]];
            [[db queue] appendPlaylistItem:playlistItem];
        }
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
}

- (void)removeSelectedFromQueue
{
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:dbRow inPlaylist:[now currentPlaylist]];
        [[db queue] removePlaylistItem:playlistItem];
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
}

- (void)clearQueue
{
    [[db queue] clear];
}

- (void)addToPlaylist:(id)sender
{
    PRPlaylist playlist = [[sender representedObject] intValue];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        PRFile file = [[db playlists] fileAtIndex:dbRow forPlaylist:[now currentPlaylist]];
        [[db playlists] appendFile:file toPlaylist:playlist];
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[[sender representedObject] intValue]];
}

- (void)revealInFinder
{
    NSIndexSet *dbRows = [self selectedDbRows];
    if ([dbRows count] == 0) {
        return;
    }
    PRFile file_ = [[db playlists] fileAtIndex:[dbRows firstIndex] forPlaylist:[now currentPlaylist]];
    NSString *URLString = [[db library] valueForFile:file_ attribute:PRPathFileAttribute];
    [[NSWorkspace sharedWorkspace] selectFile:[[NSURL URLWithString:URLString] path] inFileViewerRootedAtPath:nil];
}

- (void)showInLibrary
{
    NSIndexSet *dbRows = [self selectedDbRows];
    if ([dbRows count] == 0) {
        return;
    }
    PRFile file_ = [[db playlists] fileAtIndex:[dbRows firstIndex] forPlaylist:[now currentPlaylist]];
    [win setCurrentMode:PRLibraryMode];
    [win setCurrentPlaylist:[[db playlists] libraryPlaylist]];
    [[win libraryViewController] highlightFile:file_];
}

- (void)removeSelected
{
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
            PRFile file = [[db playlists] fileAtIndex:range.location forPlaylist:[now currentPlaylist]];
            NSString *artist = [[db library] valueForFile:file attribute:PRArtistFileAttribute];
            NSString *album = [[db library] valueForFile:file attribute:PRAlbumFileAttribute];
            NSString *prevArtist = [[array lastObject] objectForKey:@"artist"];
            NSString *prevAlbum = [[array lastObject] objectForKey:@"album"];
            if (!(prevAlbumMissing && [artist noCaseCompare:prevArtist] == NSOrderedSame && [album noCaseCompare:prevAlbum] == NSOrderedSame)) {
                BOOL expanded = [nowPlayingTableView isItemExpanded:item];
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:expanded], @"expanded", 
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
    [[db playlists] removeFilesAtIndexes:dbRows fromPlaylist:[now currentPlaylist]];
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
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
// Update
// ========================================

- (void)updateTableView
{
    // refresh nowPlayingViewSource
    [[db nowPlayingViewSource] refreshWithPlaylist:[now currentPlaylist]];
    
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

- (void)playlistDidChange:(NSNotification *)notification
{
    if ([[[notification userInfo] valueForKey:@"playlist"] intValue] == [now currentPlaylist]) {
        [self updateTableView];
        [nowPlayingTableView collapseItem:nil];
        if ([now currentIndex] != 0) {
            NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[NSNumber numberWithInt:0]]];
            [nowPlayingTableView expandItem:parentItem];
        }
    }
}

- (void)currentFileDidChange:(NSNotification *)notification
{
    [(PROutlineView *)nowPlayingTableView reloadVisibleItems];
    if ([now currentIndex] != 0) {
        id currentItem = [self itemForDbRow:[now currentIndex]];
        NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[currentItem objectAtIndex:0]]];
        if (![nowPlayingTableView isItemExpanded:parentItem]) {
            [nowPlayingTableView collapseItem:nil];
        }
        [nowPlayingTableView expandItem:parentItem];
        [nowPlayingTableView scrollRowToVisible:[nowPlayingTableView rowForItem:currentItem]];
    }
}

- (void)volumeChanged:(NSNotification *)notification
{
    float volume = [[now mov] volume];
    NSImage *image = nil;
    if (volume == 0) {
        image = [NSImage imageNamed:@"NowSpeaker1"];
    } else if (volume < 0.33) {
        image = [NSImage imageNamed:@"NowSpeaker1"];
    } else if (volume < 0.66) {
        image = [NSImage imageNamed:@"NowSpeaker2"];
    } else {
        image = [NSImage imageNamed:@"NowSpeaker3"];
    }
    [speakerButton setImage:image];
}

// ========================================
// OutlineView Delegate
// ========================================

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    [cell setHighlighted:[[outlineView selectedRowIndexes] containsIndex:[outlineView rowForItem:item]]];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    if ([(NSArray *)item count] == 1) {
        return 38.0;
    } else {
        return 19.0;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return FALSE;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return TRUE;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([(NSArray *)item count] == 1) {
        return _nowPlayingHeaderCell;
    }
    return _nowPlayingCell;
}

// ========================================
// OutlineView DragAndDrop
// ========================================

- (BOOL)outlineView:(NSOutlineView *)outlineView 
         writeItems:(NSArray *)items 
       toPasteboard:(NSPasteboard *)pboard
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self selectedDbRows]];
    [pboard declareTypes:[NSArray arrayWithObject:PRFilePboardType] owner:self];
    [pboard setData:data forType:PRFilePboardType];
    return TRUE;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView 
                  validateDrop:(id < NSDraggingInfo >)info 
                  proposedItem:(id)item_
            proposedChildIndex:(NSInteger)index
{
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

- (BOOL)outlineView:(NSOutlineView *)outlineView 
         acceptDrop:(id < NSDraggingInfo >)info 
               item:(id)item_
         childIndex:(NSInteger)index
{
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
            PRFile file = [[db playlists] fileAtIndex:range.location forPlaylist:[now currentPlaylist]];
            NSString *artist = [[db library] valueForFile:file attribute:PRArtistFileAttribute];
            NSString *album = [[db library] valueForFile:file attribute:PRAlbumFileAttribute];
            BOOL shouldMergeWithPrevAlbum = prevAlbumMissing && [artist noCaseCompare:prevArtist] == NSOrderedSame && [album noCaseCompare:prevAlbum] == NSOrderedSame;
            prevArtist = artist;
            prevAlbum = album;
            prevAlbumMissing = FALSE;
            int oldLocation = location;
            location += range.length - [dbIndexesToMove countOfIndexesInRange:range];
            if (shouldMergeWithPrevAlbum) {
                continue;
            }
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:[nowPlayingTableView isItemExpanded:item]], @"expanded", 
                                  [NSValue valueWithRange:NSMakeRange(oldLocation, range.length - [dbIndexesToMove countOfIndexesInRange:range])], @"range", 
                                  [NSNumber numberWithInt:[dbIndexesToMove countOfIndexesInRange:range]], @"missing", nil];
            [tempAlbums addObject:info];
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
        [[db playlists] moveItemsAtIndexes:dbIndexesToMove toIndex:dbIndexToInsert inPlaylist:[now currentPlaylist]];
        [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
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
        
        [[db playlists] addFiles:files atIndex:dbRow toPlaylist:[now currentPlaylist]];
        [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
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
    }
    
    return TRUE;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    [[NSCursor arrowCursor] set];
    if (operation == 0 && !NSMouseInRect([[nowPlayingTableView window] convertScreenToBase:dropPoint], [[[nowPlayingTableView superview] superview] frame], TRUE)) {
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, 
                              dropPoint, NSZeroSize, nil, nil, nil);
        [self removeSelected];
    }
}

- (void)draggedImage:(NSImage *)anImage movedTo:(NSPoint)point
{
    dropPoint = [NSEvent mouseLocation];
    if (!NSMouseInRect([[nowPlayingTableView window] convertScreenToBase:dropPoint], [[[nowPlayingTableView superview] superview] frame], TRUE)) {
        [[NSCursor disappearingItemCursor] set];
    } else {
        [[NSCursor arrowCursor] set];
    }
}

// ========================================
// TableView DataSource
// ========================================

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([(NSArray *)item count] == 1) {
        return TRUE;
    }
    return FALSE;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item) {
        return [_albumCounts count];
    } else if ([(NSArray *)item count] == 1) {
        return [[_albumCounts objectAtIndex:[[item objectAtIndex:0] intValue]] intValue];
    } else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([(NSArray *)item count] == 1) {
        int row = [self dbRowForItem:item];
        PRFile file = [[db nowPlayingViewSource] fileForRow:row];
        NSString *album = [[db library] valueForFile:file attribute:PRAlbumFileAttribute];
        NSString *artist = [[db library] comparisonArtistForFile:file];
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
        PRFile file = [[db nowPlayingViewSource] fileForRow:row];
        NSString *title = [[db library] valueForFile:file attribute:PRTitleFileAttribute]; 
        NSImage *icon;
        NSImage *invertedIcon;
        if ([now currentIndex] == row) {
            icon = [NSImage imageNamed:@"PRSpeakerIcon"];
            invertedIcon = [NSImage imageNamed:@"PRLightSpeakerIcon"];
        } else if ([[now invalidSongs] containsIndex:file]) {
            icon = [NSImage imageNamed:@"Exclamation Point"];
            invertedIcon = [NSImage imageNamed:@"Exclamation Point"];
        } else {
            icon = [[[NSImage alloc] init] autorelease];
            invertedIcon = [[[NSImage alloc] init] autorelease];
        }
        PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:row inPlaylist:[now currentPlaylist]];
        NSArray *queue = [[db queue] queueArray];
        NSUInteger queueIndex = [queue indexOfObject:[NSNumber numberWithInt:playlistItem]];
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

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    NSArray *newItem;
    if (!item) {
        newItem = [NSArray arrayWithObjects:[NSNumber numberWithInt:index], nil];
    } else {
        newItem = [NSArray arrayWithObjects:[item objectAtIndex:0], [NSNumber numberWithInt:index], nil];
    }
    return [self itemForItem:newItem];
}

// ========================================
// Menu Delegate
// ========================================

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if (menu == playlistMenu) {
        [self playlistMenuNeedsUpdate];
    } else if (menu == _contextMenu) {
        [self contextMenuNeedsUpdate];
    }
}

- (void)contextMenuNeedsUpdate
{
    for (NSMenuItem *i in [_contextMenu itemArray]) {
        [_contextMenu removeItem:i];
    }
    
    if ([nowPlayingTableView clickedRow] == -1) {
        return;
    }

    [_contextMenu addItemWithTitle:@"Play" action:@selector(playSelected) keyEquivalent:@""];
        
    // Queue
    BOOL addToQueue = FALSE;
    BOOL removeFromQueue = FALSE;
    
    NSArray *queue = [[db queue] queueArray];
    NSIndexSet *dbRows = [self selectedDbRows];
    NSInteger dbRow = [dbRows firstIndex];
    while (dbRow != NSNotFound) {
        PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:dbRow inPlaylist:[now currentPlaylist]];
        if ([queue containsObject:[NSNumber numberWithInt:playlistItem]]) {
            removeFromQueue = TRUE;
        } else {
            addToQueue = TRUE;
        }
        dbRow = [dbRows indexGreaterThanIndex:dbRow];
    }
    if (addToQueue) {
        [_contextMenu addItemWithTitle:@"Add to Queue" action:@selector(addSelectedToQueue) keyEquivalent:@""];
    }
    if (removeFromQueue) {
        [_contextMenu addItemWithTitle:@"Remove From Queue" action:@selector(removeSelectedFromQueue) keyEquivalent:@""];
    }
    if ([queue count] != 0) {
        [_contextMenu addItemWithTitle:@"Clear Queue" action:@selector(clearQueue) keyEquivalent:@""];
    }
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // Add To Playlist
    NSMenuItem *playlistMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Add to Playlist" action:nil keyEquivalent:@""] autorelease];
    NSMenu *playlistMenu_ = [[[NSMenu alloc] init] autorelease];
    [playlistMenuItem setSubmenu:playlistMenu_];
    [_contextMenu addItem:playlistMenuItem];
    
    NSArray *playlistArray = [[db playlists] playlists];
    for (NSNumber *i in playlistArray) {
        int playlistType = [[db playlists] typeForPlaylist:[i intValue]];
        if (playlistType != PRStaticPlaylistType) {
            continue;
        }
        NSString *playlistTitle = [NSString stringWithFormat:@" %@", [[db playlists] titleForPlaylist:[i intValue]]];
        NSMenuItem *tempMenuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(addToPlaylist:) keyEquivalent:@""] autorelease];
        [tempMenuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        [tempMenuItem setRepresentedObject:i];
        [tempMenuItem setTarget:self];
        [playlistMenu_ addItem:tempMenuItem];
    }
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    
    // Other
    [_contextMenu addItemWithTitle:@"Show in Library" action:@selector(showInLibrary) keyEquivalent:@""];
    [_contextMenu addItemWithTitle:@"Reveal in Finder" action:@selector(revealInFinder) keyEquivalent:@""];
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    [_contextMenu addItemWithTitle:@"Remove" action:@selector(removeSelected) keyEquivalent:@""];
    
    for (NSMenuItem *i in [_contextMenu itemArray]) {
        [i setTarget:self];
    }
}

- (void)playlistMenuNeedsUpdate
{
    for (NSMenuItem *i in [playlistMenu itemArray]) {
        [playlistMenu removeItem:i];
    }
    
    // Title of the popup button
    NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
    [menuItem setImage:[NSImage imageNamed:@"NowSettings"]];
    [playlistMenu addItem:menuItem];
    
    // Save
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Save as..." action:nil keyEquivalent:@""] autorelease];
    [menuItem setEnabled:FALSE];
    [playlistMenu addItem:menuItem];
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:@" New Playlist          " action:@selector(newPlaylist:) keyEquivalent:@""] autorelease];
    [menuItem setImage:[NSImage imageNamed:@"Add"]];
    [playlistMenu addItem:menuItem];
    
    NSArray *playlistArray = [[db playlists] playlists];
    for (NSNumber *i in playlistArray) {
        if ([[db playlists] typeForPlaylist:[i intValue]] != PRStaticPlaylistType) {
            continue;
        }
        NSString *playlistTitle = [NSString stringWithFormat:@" %@",[[db playlists] titleForPlaylist:[i intValue]]];
        menuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(saveAsPlaylist:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:i];
        [menuItem setImage:[NSImage imageNamed:@"ListViewTemplate"]];
        [playlistMenu addItem:menuItem];
    }
    
    for (NSMenuItem *i in [playlistMenu itemArray]) {
        [i setTarget:self];
    }
}

// ========================================
// Misc
// ========================================

- (int)dbRowCount
{
    return [_albumIndexes lastIndex] - 1;
}

- (NSRange)dbRangeForParentItem:(id)item
{
    return NSMakeRange([[_dbRowForAlbum objectAtIndex:[[item objectAtIndex:0] intValue]] intValue], 
                       [[_albumCounts objectAtIndex:[[item objectAtIndex:0] intValue]] intValue]);
}

- (int)dbRowForItem:(id)item
{
    if (!item) {
        return 0;
    } else if ([(NSArray *)item count] == 1) {
        return [[_dbRowForAlbum objectAtIndex:[[item objectAtIndex:0] intValue]] intValue];
    } else {
        return [[_dbRowForAlbum objectAtIndex:[[item objectAtIndex:0] intValue]] intValue] + [[item objectAtIndex:1] intValue];
    }
}

- (int)countForAlbum:(int)album
{
    return [[_albumCounts objectAtIndex:album] intValue];
}

- (id)itemForDbRow:(int)row
{
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

- (id)itemForItem:(id)item
{
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

- (NSIndexSet *)selectedDbRows
{
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

@end