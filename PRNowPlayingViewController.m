#import "PRNowPlayingViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRNowPlayingViewSource.h"
#import "PRNowPlayingController.h"
#import "PRNowPlayingCell.h"
#import "NSIndexSet+Extensions.h"
#import "PRTableView.h"
#import "PRGradientView.h"
#import "BWTexturedSlider.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRPlaylistsViewController.h"
#import "PRUserDefaults.h"
#import "PRQueue.h"


@implementation PRNowPlayingViewController

// ========================================
// Initialization
// ========================================

- (id)      initWithDb:(PRDb *)db_ 
  nowPlayingController:(PRNowPlayingController *)now_ 
  mainWindowController:(PRMainWindowController *)mainWindowController_
{
	if ((self = [super initWithNibName:@"PRNowPlayingView" bundle:nil])) {
		db = [db_ retain];
		now = [now_ retain];
        win = [mainWindowController_ retain];
	}
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
    [nowPlayingMenu release];
    [selectedRows release];
    [tableIndexes release];
    [db release];
    [now release];
    [win release];
    [super dealloc];
}

- (void)awakeFromNib
{
    // background
    [shadowView setTopGradient:[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]];
    [shadowView setBotGradient:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
    
    [gradientView setTopGradient:[NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0]];
    [gradientView setBotGradient:[NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0]];
    [gradientView setAlternateTopGradient:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    [gradientView setAlternateBotGradient:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    
    [gradientView2 setColor:[NSColor colorWithCalibratedRed:234./255. green:238./255. blue:244./255. alpha:1.0]];
    [gradientView2 setTopBorder:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    
    [gradientView3 setColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
    [gradientView4 setColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
    
	// LibraryTableView
    [self setNextResponder:[nowPlayingTableView nextResponder]];
    [nowPlayingTableView setNextResponder:self];
	[nowPlayingTableView setRowHeight:34];
	[nowPlayingTableView setDoubleAction:@selector(play)];
	[nowPlayingTableView setTarget:self];
	[nowPlayingTableView setDataSource:self];
	[nowPlayingTableView setDelegate:self];	
	[[nowPlayingTableView tableColumnWithIdentifier:@"title"] setDataCell:[[[PRNowPlayingCell alloc] init] autorelease]];
	[nowPlayingTableView registerForDraggedTypes:[NSArray arrayWithObject:PRFilePboardType]];
	[nowPlayingTableView setVerticalMotionCanBeginDrag:FALSE];
    [nowPlayingTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:TRUE];
    [nowPlayingTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:FALSE];
    [nowPlayingTableView setSlideback:FALSE];
    [nowPlayingTableView setHighlightColor:[NSColor alternateSelectedControlColor]];
    [nowPlayingTableView setSecondaryHighlightColor:[NSColor colorWithCalibratedRed:134./255 green:151./255 blue:185./255 alpha:0.7]];
	
	// LibraryTableView Context menu
	nowPlayingMenu = [[NSMenu alloc] init];
	[nowPlayingMenu setDelegate:self];
	[nowPlayingTableView setMenu:nowPlayingMenu];
	
    // playlist menu
    playlistMenu = [[NSMenu alloc] init];
    [playlistMenu setDelegate:self];
    [playlistButton setMenu:playlistMenu];
    [self playlistMenuNeedsUpdate];
    
    [playlistTitleEditor setTarget:self];
    [playlistTitleEditor setAction:@selector(doNothing)];
    [playlistTitleEditor setDelegate:self];
    
	// clear buttons
	[clearButton setTarget:self];
	[clearButton setAction:@selector(clearPlaylist)];
    
    // volume slider
    [volumeSlider setMaxValue:1];
	[volumeSlider setMinValue:0];
	[volumeSlider bind:@"value" toObject:now withKeyPath:@"mov.volume" options:nil];
    [(BWTexturedSlider *)volumeSlider setIndicatorIndex:3];
    
    // shuffle and repeat buttons
    NSDictionary *options = 
        [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:FALSE] 
                                    forKey:NSConditionallySetsEnabledBindingOption];
    [shuffle bind:@"target" toObject:now withKeyPath:@"toggleShuffle" options:options];
	[repeat bind:@"target" toObject:now withKeyPath:@"toggleRepeat" options:options];
    [now addObserver:self forKeyPath:@"shuffle" options:0 context:nil];
    [now addObserver:self forKeyPath:@"repeat" options:0 context:nil];
    [now addObserver:self forKeyPath:@"currentPlaylist" options:0 context:nil];
    [now addObserver:self forKeyPath:@"currentFile" options:0 context:nil];
    [self observeValueForKeyPath:@"shuffle" ofObject:now change:nil context:nil];
    [self observeValueForKeyPath:@"repeat" ofObject:now change:nil context:nil];
    [self observeValueForKeyPath:@"currentPlaylist" ofObject:now change:nil context:nil];
    [self observeValueForKeyPath:@"currentIndex" ofObject:now change:nil context:nil];
    
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
}

// ========================================
// Action
// ========================================

- (void)play
{
	int row = [self dbRowForTableRow:[nowPlayingTableView clickedRow]];
	if (row == -1) {
		row = [self dbRowForTableRow:[nowPlayingTableView clickedRow] + 1];
	}
    if (row > [self numberOfRowsInTableView:nil] || row < 1) {
        return;
    }
    
	[now playPlaylist:[now currentPlaylist] fileAtIndex:row];
}

- (void)addSelectedToQueue
{
    [self removeSelectedFromQueue];
    NSIndexSet *dbRows = [self dbRowIndexesForTableRowIndexes:[nowPlayingTableView selectedRowIndexes]];
    int count = [[db playlists] countForPlaylist:[now currentPlaylist]];
    NSUInteger index = [dbRows firstIndex];
    while (index != NSNotFound) {
        if (index > count) {
            return;
        }
        if (index == [now currentIndex]) {
            index = [dbRows indexGreaterThanIndex:index];
            continue;
        }
        PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:index inPlaylist:[now currentPlaylist]];
        [[db queue] appendPlaylistItem:playlistItem _error:nil];
        index = [dbRows indexGreaterThanIndex:index];
    }
}

- (void)removeSelectedFromQueue
{
    NSIndexSet *dbRows = [self dbRowIndexesForTableRowIndexes:[nowPlayingTableView selectedRowIndexes]];
    int count = [[db playlists] countForPlaylist:[now currentPlaylist]];
    NSUInteger index = [dbRows firstIndex];
    while (index != NSNotFound) {
        if (index > count) {
            return;
        }
        PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:index inPlaylist:[now currentPlaylist]];
        [[db queue] removePlaylistItem:playlistItem _error:nil];
        index = [dbRows indexGreaterThanIndex:index];
    }
}

- (void)clearQueue
{
    [[db queue] clearQueue];
}

- (void)addToPlaylist:(id)sender
{
    NSInteger currentIndex = 0;
    NSIndexSet *dbRowIndexes = [self dbRowIndexesForTableRowIndexes:[nowPlayingTableView selectedRowIndexes]];
	while ((currentIndex = [dbRowIndexes indexGreaterThanOrEqualToIndex:currentIndex]) != NSNotFound) {
        PRFile file_ = [[db playlists] fileAtIndex:currentIndex forPlaylist:[now currentPlaylist]];
        [[db playlists] appendFile:file_ toPlaylist:[[sender representedObject] intValue]];
		currentIndex++;
	}
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[sender representedObject] forKey:@"playlist"];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistDidChangeNotification 
                                                        object:self 
                                                      userInfo:userInfo];
}

- (void)playSelected
{
	int row = [self dbRowForTableRow:[[nowPlayingTableView selectedRowIndexes] firstIndex]];
	if (row != -1) {
		[now playPlaylist:[now currentPlaylist] fileAtIndex:row];
	}
}

- (void)removeSelected
{
	if ([selectedRows containsIndex:[now currentIndex]]) {
		[now stop];
	}
	[[db playlists] removeFilesAtIndexes:selectedRows fromPlaylist:[now currentPlaylist]];
	[now postNotificationForCurrentPlaylist];
	[nowPlayingTableView selectRowIndexes:[[[NSIndexSet alloc] init] autorelease]
					 byExtendingSelection:FALSE];
	
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
}

- (void)revealInFinder
{
    int row = [self dbRowForTableRow:[[nowPlayingTableView selectedRowIndexes] firstIndex]];
	
    PRFile file_ = [[db playlists] fileAtIndex:row forPlaylist:[now currentPlaylist]];
    NSString *URLString;
	[[db library] value:&URLString forFile:file_ attribute:PRPathFileAttribute _error:nil];
    
	[[NSWorkspace sharedWorkspace] selectFile:[[NSURL URLWithString:URLString] path] inFileViewerRootedAtPath:nil];
}

- (void)showInLibrary
{
    int row = [self dbRowForTableRow:[[nowPlayingTableView selectedRowIndexes] firstIndex]];
    PRFile file_ = [[db playlists] fileAtIndex:row forPlaylist:[now currentPlaylist]];
    [win setCurrentMode:PRLibraryMode];
    [win setCurrentPlaylist:[[db playlists] libraryPlaylist]];
    [[win libraryViewController] highlightFile:file_];
}

- (IBAction)delete:(id)sender
{
    [selectedRows release];
    selectedRows = [[self dbRowIndexesForTableRowIndexes:[nowPlayingTableView selectedRowIndexes]] retain];
    [self removeSelected];
}

- (void)getInfo
{
    [self showInLibrary];
    [[win libraryViewController] infoViewToggle];
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
// Update
// ========================================

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if (object == now && [keyPath isEqualToString:@"shuffle"]) {
        if ([now shuffle]) {
            [shuffle setImage:[NSImage imageNamed:@"PRShuffleIcon.png"]];
        } else {
            [shuffle setImage:[NSImage imageNamed:@"PRShuffleOffIcon.png"]];
        }
    } else if (object == now && [keyPath isEqualToString:@"repeat"]) {
        if ([now repeat]) {
            [repeat setImage:[NSImage imageNamed:@"PRRepeatIcon.png"]];
        } else {
            [repeat setImage:[NSImage imageNamed:@"PRRepeatOffIcon.png"]];
        }
    } else if (object == now && [keyPath isEqualToString:@"currentPlaylist"]) {
        [self updateTableView];
        [self playlistMenuNeedsUpdate];
        [playlistButton setNeedsDisplay:TRUE];
    } else if (object == now && [keyPath isEqualToString:@"currentFile"]) {
        // reload data & scroll to current row
        [nowPlayingTableView reloadData];
        [nowPlayingTableView scrollRowToVisible:[self tableRowForDbRow:[now currentIndex]]];
    }
}

- (void)updateTableView
{
    NSPoint point = [nowPlayingTableView visibleRect].origin;
    point.y -= 2;

	// refresh nowPlayingViewSource
	[[db nowPlayingViewSource] refreshWithPlaylist:[now currentPlaylist] sort:0 ascending:FALSE _error:NULL];
	
	// refresh tableIndexes
    [tableIndexes release];
	tableIndexes = [[NSMutableIndexSet indexSet] retain];
    NSArray *array;
	[[db nowPlayingViewSource] arrayOfAlbumCounts:&array _error:nil];
	int count = 1;
	for (NSNumber *i in array) {
		[tableIndexes addIndexesInRange:NSMakeRange(count, [i intValue])];
		count = count + [i intValue] + 1;
	}
	tableCount = count - 1;
	[nowPlayingTableView reloadData];
	
	// scroll to current row
    [nowPlayingTableView scrollPoint:point];
}

- (void)playlistDidChange:(NSNotification *)notification
{
    [self playlistMenuNeedsUpdate];
    if ([[[notification userInfo] valueForKey:@"playlist"] intValue] == [now currentPlaylist]) {
		[self updateTableView];
	}
}

- (void)currentFileDidChange:(NSNotification *)notification
{
    // reload data & scroll to current row
	[nowPlayingTableView reloadData];
	[nowPlayingTableView scrollRowToVisible:[self tableRowForDbRow:[now currentIndex]]];
}

- (void)doNothing
{
    [[playlistTitleEditor window] selectNextKeyView:nil];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    [playlistButton setHidden:FALSE];
    [[playlistTitleEditor window] endEditingFor:playlistTitleEditor];
	[playlistTitleEditor setHidden:TRUE];
    [playlistTitleEditor validateEditing];
    [playlistTitleEditor abortEditing];
    [[db playlists] setValue:[playlistTitleEditor stringValue] 
                 forPlaylist:[now currentPlaylist] 
                   attribute:PRTitlePlaylistAttribute];
    [now postNotificationForCurrentPlaylist];
}

// ========================================
// TableView Delegate
// ========================================

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == nowPlayingTableView) {
		int index = 0;
		NSMutableIndexSet *selectionIndexes = 
          [[[NSMutableIndexSet alloc] initWithIndexSet:[nowPlayingTableView selectedRowIndexes]] autorelease];
		
		while ([selectionIndexes indexGreaterThanOrEqualToIndex:index] != NSNotFound) {
			if ([self dbRowForTableRow:index] == -1) {
				[selectionIndexes removeIndex:index];
			}
			index++;
		}
		[nowPlayingTableView selectRowIndexes:selectionIndexes byExtendingSelection:FALSE]; 
	}
}


- (BOOL)                      tableView:(NSTableView *)tableView
  shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn
									row:(NSInteger)row 
{
	return FALSE;
}

- (CGFloat)tableView:(NSTableView *)tableView 
		 heightOfRow:(NSInteger)row
{
	if ([self dbRowForTableRow:row] == -1) {
		return 34;
	} else {
		return 17; // default 17
	}
    
}

// ========================================
// TableView DragAndDrop
// ========================================

- (BOOL)     tableView:(NSTableView *)tableView 
  writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
		  toPasteboard:(NSPasteboard *)pboard
{
	// Get DbRowIndexes
    [selectedRows release];
    selectedRows = [[self dbRowIndexesForTableRowIndexes:rowIndexes] retain];
    if ([selectedRows count] == 0) {
        if ([rowIndexes count] != 1) {
            return FALSE;
        }
        NSMutableIndexSet *newSelection = [NSMutableIndexSet indexSet];
        int i = [rowIndexes firstIndex] + 1;
        int index = [self dbRowForTableRow:i];
        while (index != -1) {
            [newSelection addIndex:index];
            i++;
            index = [self dbRowForTableRow:i];
        }
        [selectedRows release];
        selectedRows = [newSelection retain];
        
        if ([selectedRows count]== 0) {
            return FALSE;
        }
	}
	
	// Get selected files
	NSInteger currentIndex = [selectedRows firstIndex];
	PRFile file;
	NSMutableArray *files = [NSMutableArray array];
	while (currentIndex != NSNotFound) {
		[[db nowPlayingViewSource] file:&file forRow:currentIndex _error:nil];
		[files addObject:[NSNumber numberWithInt:file]];
        currentIndex = [selectedRows indexGreaterThanIndex:currentIndex];
	}
	
	// archive files and save to pasteboard
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                files, @"files",
                                selectedRows, @"rows",
                                nil];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	[pboard declareTypes:[NSArray arrayWithObject:PRFilePboardType] owner:self];
    [pboard setData:data forType:PRFilePboardType];
	return TRUE;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
				validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(NSInteger)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	// retarget drag operations below a header
	if (row != 0 && [self dbRowForTableRow:row - 1] == -1) {
		[nowPlayingTableView setDropRow:row - 1 dropOperation:NSTableViewDropAbove];
        return NSDragOperationEvery;
	}
    
	if (op == NSTableViewDropAbove) {
		return NSDragOperationEvery;
	} else {
		return NSDragOperationNone;
	}
}

- (BOOL)tableView:(NSTableView *)tableView 
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row 
	dropOperation:(NSTableViewDropOperation)operation
{
	// get dragging data
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *filesData = [pboard dataForType:PRFilePboardType];
	
	if ([info draggingSource] == nowPlayingTableView) {
		NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
		NSIndexSet *rowIndexes = [dictionary objectForKey:@"rows"];
		if (row == 0) {
			row = 1;
		} else if ([self dbRowForTableRow:row] == -1) {
			row = [self dbRowForTableRow:row - 1] + 1;
		} else {
			row = [self dbRowForTableRow:row];
		}
        [[db playlists] moveItemsAtIndexes:rowIndexes toIndex:row inPlaylist:[now currentPlaylist]];
	} else {
		int index;
		NSArray *filesArray = [NSKeyedUnarchiver unarchiveObjectWithData:filesData];
		
		for (int i = 0; i < [filesArray count]; i++) {
			if (row == 0) {
				index = 1 + i;
			} else if ([self dbRowForTableRow:row] == -1){
				index = [self dbRowForTableRow:row - 1] + 1 + i;
			} else {
				index = [self dbRowForTableRow:row] + i;
			}
			
            [[db playlists] addFile:[[filesArray objectAtIndex:i] intValue] 
                            atIndex:index
                         toPlaylist:[now currentPlaylist]];

		}
	}
	[now postNotificationForCurrentPlaylist];
	[nowPlayingTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
	
	return TRUE;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    [[NSCursor arrowCursor] set];
    if (operation == 0) {
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return tableCount;
	
	int count;	
	[[db nowPlayingViewSource] count:&count _error:NULL];
	return count;
}

- (id)            tableView:(NSTableView *)tableView 
  objectValueForTableColumn:(NSTableColumn *)tableColumn 
			            row:(NSInteger)rowIndex
{	
	int actualRow = [self dbRowForTableRow:rowIndex];
	NSString *title = @"";
	NSString *subtitle = @"";
	NSImage *icon = [[[NSImage alloc] init] autorelease];
	NSImage *invertedIcon = [[[NSImage alloc] init] autorelease];
    NSNumber *badge = [NSNumber numberWithInt:0];
	int showSubtitle = TRUE;
	
	if (actualRow == -1) {
        PRFile file_;
		[[db nowPlayingViewSource] file:&file_ forRow:[self dbRowForTableRow:rowIndex + 1] _error:nil];
		[[db library] value:&subtitle forFile:file_ attribute:PRAlbumFileAttribute _error:nil];
        if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
            [[db library] value:&title forFile:file_ attribute:PRArtistAlbumArtistFileAttribute _error:nil];
        } else {
            [[db library] value:&title forFile:file_ attribute:PRArtistFileAttribute _error:nil];
        }
		
		if (!title || [title isEqualToString:@""]) {
			title = @"Unknown Artist";
		}
		if (!subtitle || [subtitle isEqualToString:@""]) {
			subtitle = @"Unknown Album";
		}
	} else {
        PRFile file_;
		[[db nowPlayingViewSource] file:&file_ forRow:actualRow _error:NULL];
		[[db library] value:&title forFile:file_ attribute:PRTitleFileAttribute _error:NULL];
		showSubtitle = FALSE;
		        
		if ([now currentIndex] == actualRow) {
			icon = [NSImage imageNamed:@"PRSpeakerIcon"];
			invertedIcon = [NSImage imageNamed:@"PRLightSpeakerIcon"];
		} else if ([[now invalidSongs] containsIndex:file_]) {
            icon = [NSImage imageNamed:@"Exclamation Point"];
			invertedIcon = [NSImage imageNamed:@"Exclamation Point"];
        } else {
			icon = [[[NSImage alloc] initWithSize:[[NSImage imageNamed:@"PRSpeakerIcon"] size]] autorelease];
			invertedIcon = icon;
		}
		if (!title) {
			title = @"";
		}
        
        PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:actualRow inPlaylist:[now currentPlaylist]];
        NSArray *queue;
        [[db queue] queueArray:&queue _error:nil];
        NSUInteger queueIndex = [queue indexOfObject:[NSNumber numberWithInt:playlistItem]];
        if (queueIndex != NSNotFound) {
            badge = [NSNumber numberWithInt:queueIndex + 1];
        }
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			title, @"title",
			subtitle, @"subtitle",
			[NSNumber numberWithBool:showSubtitle], @"showSubtitle",
			icon, @"icon",
			invertedIcon, @"invertedIcon",
            badge, @"badge",
			nil];
}

// ========================================
// Menu Delegate
// ========================================

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if (menu == playlistMenu) {
        [self playlistMenuNeedsUpdate];
        return;
    }
    
	NSInteger clickedRow = [nowPlayingTableView clickedRow];
    [selectedRows release];
	if (clickedRow == -1) {
		selectedRows = [[NSIndexSet indexSet] retain];
	} else if ([nowPlayingTableView isRowSelected:clickedRow]) {
		selectedRows = [[self dbRowIndexesForTableRowIndexes:[nowPlayingTableView selectedRowIndexes]] retain];
	} else {
		selectedRows = [[NSIndexSet indexSetWithIndex:[self dbRowForTableRow:clickedRow]] retain];
	}
	
	for (NSMenuItem *i in [menu itemArray]) {
		[menu removeItem:i];
	}
	
	if (clickedRow != -1) {
		// right clicked on row(s)
		[menu addItemWithTitle:@"Play" action:@selector(playSelected) keyEquivalent:@""];
        
        NSArray *queue;
        [[db queue] queueArray:&queue _error:nil];
        
        BOOL add = FALSE;
        BOOL remove = FALSE;
        NSUInteger index = [selectedRows firstIndex];
        while (index != NSNotFound) {
            PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:index inPlaylist:[now currentPlaylist]];
            if ([queue containsObject:[NSNumber numberWithInt:playlistItem]]) {
                remove = TRUE;
            } else {
                add = TRUE;
            }
            index = [selectedRows indexGreaterThanIndex:index];
        }
        if (add) {
            [menu addItemWithTitle:@"Add to Queue" action:@selector(addSelectedToQueue) keyEquivalent:@""];
        }
        if (remove) {
            [menu addItemWithTitle:@"Remove From Queue" action:@selector(removeSelectedFromQueue) keyEquivalent:@""];
        }
        if ([queue count] > 0) {
            [menu addItemWithTitle:@"Clear Queue" action:@selector(clearQueue) keyEquivalent:@""];
        }
		[menu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *playlistMenuItem = 
          [[[NSMenuItem alloc] initWithTitle:@"Add to Playlist" action:nil keyEquivalent:@""] autorelease];
		NSMenu *playlistMenu_ = [[[NSMenu alloc] init] autorelease];
		[playlistMenuItem setSubmenu:playlistMenu_];
        [menu addItem:playlistMenuItem];
        
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
		
		[menu addItem:[NSMenuItem separatorItem]];
        [menu addItemWithTitle:@"Show in Library" action:@selector(showInLibrary) keyEquivalent:@""];
		[menu addItemWithTitle:@"Get Info" action:@selector(getInfo) keyEquivalent:@""];
        [menu addItemWithTitle:@"Reveal in Finder" action:@selector(revealInFinder) keyEquivalent:@""];

		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Remove" action:@selector(removeSelected) keyEquivalent:@""];
	} else {
		// Right clicked on empty row
	}
	
	for (NSMenuItem *i in [menu itemArray]) {
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
//	NSDictionary *attributes = 
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

- (int)dbRowForTableRow:(int)tableRow
{
	if (![tableIndexes containsIndex:tableRow]) {
		return -1;
	} else {
		return [tableIndexes countOfIndexesInRange:NSMakeRange(0, tableRow + 1)];
	}
}

- (int)tableRowForDbRow:(int)dbRow
{
	NSInteger tableRow = [tableIndexes nthIndex:dbRow];
	if (tableRow == NSNotFound) {
		return -1;
	} else {
		return tableRow;
	}
}

- (NSIndexSet *)dbRowIndexesForTableRowIndexes:(NSIndexSet *)tableRowIndexes
{
	NSInteger index = [tableRowIndexes firstIndex];
	NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
	while (index != NSNotFound) {
		if ([self dbRowForTableRow:index] != -1) {
			[rowIndexes addIndex:[self dbRowForTableRow:index]];
		}
		index = [tableRowIndexes indexGreaterThanIndex:index];
	}
	return [[[NSIndexSet alloc] initWithIndexSet:rowIndexes] autorelease];
}

@end
