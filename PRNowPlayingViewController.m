#import "PRNowPlayingViewController.h"
#import "PREnqueue.h"
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
#import "PRScroller.h"
#import "NSIndexSet+Extensions.h"

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
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PRPlaylistDidChangeNotification 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PRCurrentFileDidChangeNotification 
                                                  object:nil];
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
    [backgroundGradient setAlternateTopGradient:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    [backgroundGradient setAlternateBotGradient:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    
    [barGradient setColor:[NSColor colorWithCalibratedRed:234./255. green:238./255. blue:244./255. alpha:1.0]];
    [barGradient setTopBorder:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
        
    // LibraryTableView
//    [self setNextResponder:[nowPlayingTableView nextResponder]];
//    [nowPlayingTableView setNextResponder:self];
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
    
//    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
//        [scrollview setVerticalScroller:[[[PRScroller alloc] init] autorelease]];
//    }
    
    // context menu
    _contextMenu = [[NSMenu alloc] init];
    [_contextMenu setDelegate:self];
    [nowPlayingTableView setMenu:_contextMenu];
    
    // playlist menu
    playlistMenu = [[NSMenu alloc] init];
    [playlistMenu setDelegate:self];
        
    // clear buttons
    [clearButton setTarget:self];
    [clearButton setAction:@selector(clearPlaylist)];
    
    // volume slider
    [volumeSlider setMaxValue:1];
    [volumeSlider setMinValue:0];
    [volumeSlider bind:@"value" toObject:now withKeyPath:@"mov.volume" options:nil];
    [(BWTexturedSlider *)volumeSlider setIndicatorIndex:3];
    
    [now addObserver:self forKeyPath:@"currentPlaylist" options:0 context:nil];
    [now addObserver:self forKeyPath:@"currentFile" options:0 context:nil];
    [self observeValueForKeyPath:@"currentPlaylist" ofObject:now change:nil context:nil];
    [self observeValueForKeyPath:@"currentIndex" ofObject:now change:nil context:nil];
    
    _nowPlayingCell = [[PRNowPlayingCell alloc] initTextCell:@""];
    _nowPlayingHeaderCell = [[PRNowPlayingHeaderCell alloc] initTextCell:@""];
    
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [style setAlignment:NSCenterTextAlignment];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.8]];
    [shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont systemFontOfSize:14.0], NSFontAttributeName,
                                shadow, NSShadowAttributeName,
                                style, NSParagraphStyleAttributeName,
                                [NSColor colorWithCalibratedWhite:0.0 alpha:0.4], NSForegroundColorAttributeName, nil];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Drag songs here to play" attributes:attributes];
    [_dragLabel setAttributedStringValue:string];
    
    // playlist and current file obs
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateTableView)
                                                 name:PRTagsDidChangeNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(playlistDidChange:)
                                                 name:PRPlaylistDidChangeNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateTableView)
                                                 name:PRLibraryDidChangeNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(currentFileDidChange:)
                                                 name:PRCurrentFileDidChangeNotification 
                                               object:nil];
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
    [self playItem:[nowPlayingTableView itemAtRow:[nowPlayingTableView clickedRow]]];
    [nowPlayingTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[nowPlayingTableView clickedRow]] byExtendingSelection:FALSE];
}

- (void)playItem:(id)item
{
    int dbRow = [self dbRowForItem:item];
    [now playPlaylist:[now currentPlaylist] fileAtIndex:dbRow];
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
    [now postNotificationForCurrentPlaylist];
    [nowPlayingTableView expandItem:nil];
}

- (IBAction)delete:(id)sender
{
    [self removeSelected];
}

- (void)saveAsPlaylist:(id)sender
{
    int playlist = [[sender representedObject] intValue];
    [[db playlists] clearPlaylist:playlist];
    [[db playlists] copyFilesFromPlaylist:[now currentPlaylist] toPlaylist:playlist];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist] 
                                                         forKey:@"playlist"];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistDidChangeNotification 
                                                        object:self
                                                      userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification 
                                                        object:self
                                                      userInfo:nil];
}

- (void)newPlaylist:(id)sender
{
    PRPlaylist playlist = [[db playlists] addStaticPlaylist];
    [[db playlists] clearPlaylist:playlist];
    [[db playlists] copyFilesFromPlaylist:[now currentPlaylist] toPlaylist:playlist];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification 
                                                        object:self];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist] 
                                                         forKey:@"playlist"];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistDidChangeNotification 
                                                        object:self
                                                      userInfo:userInfo];
    
    [win setCurrentMode:PRPlaylistsMode];
    [[win playlistsViewController] renamePlaylist:playlist];
}

// ========================================
// Menu Action
// ========================================

- (void)playSelected
{
    if ([[self selectedDbRows] count] == 0) {
        return;
    }
    [now playPlaylist:[now currentPlaylist] fileAtIndex:[[self selectedDbRows] firstIndex]];
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
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[sender representedObject], @"playlist", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistDidChangeNotification object:self userInfo:userInfo];
}

- (void)getInfo
{
    [self showInLibrary];
    [[win libraryViewController] infoViewToggle];
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
    [now postNotificationForCurrentPlaylist];
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

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if (object == now && [keyPath isEqualToString:@"currentPlaylist"]) {
        [self updateTableView];
    }
}

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
        
        [_dragLabel setHidden:([[db playlists] countForPlaylist:[now currentPlaylist]] != 0)];
    }
}

- (void)currentFileDidChange:(NSNotification *)notification
{
    if ([now currentIndex] != 0) {
//        NSIndexSet *selectedRowIndexes = [nowPlayingTableView selectedRowIndexes];
        [self updateTableView];
        [nowPlayingTableView reloadItem:[self itemForDbRow:_prevRow]];
        [nowPlayingTableView reloadItem:[self itemForDbRow:[now currentIndex]]];
        _prevRow = [now currentIndex];
        
        if ([now shuffle]) {
//            [nowPlayingTableView collapseItem:nil];
        }
        id currentItem = [self itemForDbRow:[now currentIndex]];
        NSArray *parentItem = [self itemForItem:[NSArray arrayWithObject:[currentItem objectAtIndex:0]]];
        [nowPlayingTableView expandItem:parentItem];
        [nowPlayingTableView scrollRowToVisible:[nowPlayingTableView rowForItem:currentItem]];
//        [nowPlayingTableView selectRowIndexes:selectedRowIndexes byExtendingSelection:FALSE];
    }
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
        [now postNotificationForCurrentPlaylist];
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
        [now postNotificationForCurrentPlaylist];
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
    
    NSMenuItem *playlistMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Add to Playlist" action:nil keyEquivalent:@""] autorelease];
    NSMenu *playlistMenu_ = [[[NSMenu alloc] init] autorelease];
    [playlistMenuItem setSubmenu:playlistMenu_];
    [_contextMenu addItem:playlistMenuItem];
    
    NSArray *playlistArray = [[db playlists] playlists];
    for (NSNumber *i in playlistArray) {
        int playlistType = [[db playlists] typeForPlaylist:[i intValue]];
        if (playlistType != PRStaticPlaylistType || [i intValue] == [now currentPlaylist]) {
            continue;
        }
        NSString *playlistTitle = [[db playlists] titleForPlaylist:[i intValue]];
        NSMenuItem *tempMenuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(addToPlaylist:) keyEquivalent:@""] autorelease];
        [tempMenuItem setRepresentedObject:i];
        [tempMenuItem setTarget:self];
        [playlistMenu_ addItem:tempMenuItem];
    }
    [_contextMenu addItem:[NSMenuItem separatorItem]];
    [_contextMenu addItemWithTitle:@"Show in Library" action:@selector(showInLibrary) keyEquivalent:@""];
    [_contextMenu addItemWithTitle:@"Get Info" action:@selector(getInfo) keyEquivalent:@""];
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
//    [playlistMenu setShowsStateColumn:FALSE];
    [playlistMenu setAutoenablesItems:FALSE];
    
    // Title of the popup button
    NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
    [menuItem setTitle:@""];
    [menuItem setImage:[NSImage imageNamed:@"PRActionIcon"]];
    [playlistMenu addItem:menuItem];
    //    NSString *currentPlaylist;
    //    [[db playlists] value:&currentPlaylist 
    //              forPlaylist:[now currentPlaylist] 
    //                attribute:PRTitlePlaylistAttribute 
    //                   _error:nil];
    //    
    //    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    //    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    // NSDictionary *attributes = 
    //      [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"LucidaGrande-Bold" size:10],NSFontAttributeName,
    //       style ,NSParagraphStyleAttributeName, nil];
    //    [menuItem setAttributedTitle:[[[NSAttributedString alloc] initWithString:currentPlaylist attributes:attributes] autorelease]];
    
    //    menuItem = [[[NSMenuItem alloc] initWithTitle:@"New Playlist" action:@selector(a) keyEquivalent:@""] autorelease];
    //    [menuItem setTarget:self];
    //    [menuItem setAction:@selector(newStaticPlaylist)];
    //    [playlistMenu addItem:menuItem];
    //    if ([now currentPlaylist] == PRScratchPlaylistIndex) {
    //        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Save" action:@selector(a) keyEquivalent:@""] autorelease];
    //        [menuItem setTarget:self];
    //        [menuItem setAction:@selector(savePlaylist)];
    //        [playlistMenu addItem:menuItem];        
    //    } else {
    //        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Duplicate" action:@selector(a) keyEquivalent:@""] autorelease];
    //        [menuItem setTarget:self];
    //        [menuItem setAction:@selector(savePlaylist)];
    //        [playlistMenu addItem:menuItem];
    //    }
    //    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Rename" action:@selector(a) keyEquivalent:@""] autorelease];
    //    [menuItem setTarget:self];
    //    [menuItem setAction:@selector(renamePlaylist)];
    //    [menuItem setEnabled:([now currentPlaylist] != PRScratchPlaylistIndex)];
    //    [playlistMenu addItem:menuItem];
    //    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(a) keyEquivalent:@""] autorelease];
    //    [menuItem setTarget:self];
    //    [menuItem setAction:@selector(deletePlaylist)];
    //    [menuItem setEnabled:([now currentPlaylist] != PRScratchPlaylistIndex)];
    //    [playlistMenu addItem:menuItem];    
    //    [playlistMenu addItem:[NSMenuItem separatorItem]];
    //    
    //    [playlistMenu addItemWithTitle:@"Play" action:@selector(play) keyEquivalent:@""];
    //    [playlistMenu addItem:[NSMenuItem separatorItem]];
    
    // 'Playlists' Header
    NSMenu *loadMenu = [[[NSMenu alloc] init] autorelease];
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Load Playlist" action:nil keyEquivalent:@""] autorelease];
    //    [playlistMenu addItem:menuItem];
    [menuItem setSubmenu:loadMenu];
    
    NSArray *playlistArray = [[db playlists] playlists];
    for (NSNumber *i in playlistArray) {
        int playlistType = [[db playlists] typeForPlaylist:[i intValue]];
        if (playlistType != PRStaticPlaylistType || [i intValue] == [now currentPlaylist]) {
            continue;
        }
        NSString *playlistTitle = [[db playlists] titleForPlaylist:[i intValue]];
        menuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(loadPlaylist:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:i];
        [menuItem setTarget:self];
        [loadMenu addItem:menuItem];
    }
    NSMenu *saveMenu = [[[NSMenu alloc] init] autorelease];
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Save as Playlist" action:nil keyEquivalent:@""] autorelease];
    [playlistMenu addItem:menuItem];
    [menuItem setSubmenu:saveMenu];
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"New Playlist..." action:@selector(newPlaylist:) keyEquivalent:@""] autorelease];
    [menuItem setTarget:self];
    [saveMenu addItem:menuItem];
    [saveMenu addItem:[NSMenuItem separatorItem]];
    
    playlistArray = [[db playlists] playlists];
    for (NSNumber *i in playlistArray) {
        int playlistType = [[db playlists] typeForPlaylist:[i intValue]];
        if (playlistType != PRStaticPlaylistType || [i intValue] == [now currentPlaylist]) {
            continue;
        }
        NSString *playlistTitle = [[db playlists] titleForPlaylist:[i intValue]];
        menuItem = [[[NSMenuItem alloc] initWithTitle:playlistTitle action:@selector(saveAsPlaylist:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:i];
        [menuItem setTarget:self];
        [saveMenu addItem:menuItem];
    }
    
//    [playlistMenu addItem:[NSMenuItem separatorItem]];
//    [playlistMenu addItemWithTitle:@"Clear" action:@selector(clearPlaylist) keyEquivalent:@""];
    
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