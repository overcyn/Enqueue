#import "PRAlbumListViewController.h"
#import "PRTableViewController.h"
#import "PRLibraryViewSource.h"
#import "PRSynchronizedScrollView.h"
#import "PRNowPlayingController.h"
#import "PRDb.h"
#import "PRAlbumArtController.h"
#import "PRAlbumTableView2.h"
#import "NSIndexSet+Extensions.h"
#import "PRPlaylists+Extensions.h"

@implementation PRAlbumListViewController

// ========================================
// Initialization
// ========================================

- (id)       initWithDb:(PRDb *)db_ 
   nowPlayingController:(PRNowPlayingController *)now_
  libraryViewController:(PRLibraryViewController *)libraryViewController_
{
	if ((self = [super initWithNibName:@"PRAlbumListView" bundle:nil])) {
        db = db_;
		now = now_;
		libraryViewController = libraryViewController_;
        refreshing = FALSE;
		currentPlaylist = -1;
        
        lock = [[NSLock alloc] init];
        cachedArt = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
    [tableIndexes release];
    [albumCountArray release];
    [albumSumCountArray release];
    [lock release];
    [cachedArt release];
    [super dealloc];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[albumTableView setDataSource:self];
	[albumTableView setDelegate:self];
	[albumTableView setTarget:self];
	[albumTableView setAction:@selector(selectAlbum)];
	[albumTableView setNextResponder__:(PRAlbumTableView2 *)libraryTableView];
	[albumTableView setDoubleAction:@selector(playAlbum)];
	[[albumTableView headerView] setMenu:headerMenu];
	
	[libraryScrollView2 setSynchronizedScrollView:albumScrollView];
	[albumScrollView setSynchronizedScrollView:libraryScrollView2];
}

// ========================================
// Accessors
// ========================================

- (int)sortColumn
{
    return [[db playlists] albumListViewSortColumnForPlaylist:currentPlaylist];
}

- (void)setSortColumn:(int)sortColumn
{
    [[db playlists] setAlbumListViewSortColumn:sortColumn forPlaylist:currentPlaylist];
}

- (BOOL)ascending
{
    return [[db playlists] albumListViewAscendingForPlaylist:currentPlaylist];
}

- (void)setAscending:(BOOL)ascending
{
    [[db playlists] setAlbumListViewAscending:ascending forPlaylist:currentPlaylist];
}

// ========================================
// Update
// ========================================

- (void)reloadData
{	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	// update libSrc
    int tables;
	[[db libraryViewSource] refreshWithPlaylist:currentPlaylist tablesToUpdate:&tables _error:nil];
	
    // update albumCountArray, tableIndexes & libraryCount
	libraryCount = 0;
    [albumCountArray release];
	[[db libraryViewSource] arrayOfAlbumCounts:&albumCountArray _error:nil];
    [albumCountArray retain];
    [tableIndexes release];
	tableIndexes = [[NSMutableIndexSet indexSet] retain];
	for (NSNumber *i in albumCountArray) {
		[tableIndexes addIndexesInRange:NSMakeRange(libraryCount, [i intValue])];
		if ([i intValue] < 10) {
			libraryCount += 11;
		} else {
			libraryCount += [i intValue] + 1;
		}
	}
	
	// update albumSumCountArray
	int count = 0;
    [albumSumCountArray release];
	albumSumCountArray = [[NSMutableArray alloc] initWithArray:albumCountArray];
	for (int i = 0; i < [albumSumCountArray count]; i++) {
		count = count + [[albumSumCountArray objectAtIndex:i] intValue];
		[albumSumCountArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:count]];
	}
    
	// reload tables
    refreshing = TRUE;
    NSIndexSet *indexSet;
    if ((tables & PRLibraryView) == PRLibraryView) {
        [libraryTableView reloadData];
        [albumTableView reloadData];
    }
    if ((tables & PRBrowser1View) == PRBrowser1View) {
        [browser1TableView reloadData];
        [[db libraryViewSource] selectionIndexSet:&indexSet forBrowser:1 withPlaylist:currentPlaylist _error:nil];
        if (![indexSet isEqualToIndexSet:[browser1TableView selectedRowIndexes]]) {
            [browser1TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }
    if ((tables & PRBrowser2View) == PRBrowser2View) {
        [browser2TableView reloadData];
        [[db libraryViewSource] selectionIndexSet:&indexSet forBrowser:2 withPlaylist:currentPlaylist _error:nil];
        if (![indexSet isEqualToIndexSet:[browser2TableView selectedRowIndexes]]) {
            [browser2TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }
    if ((tables & PRBrowser3View) == PRBrowser3View) {
        [browser3TableView reloadData];
        [[db libraryViewSource] selectionIndexSet:&indexSet forBrowser:3 withPlaylist:currentPlaylist _error:nil];
        if (![indexSet isEqualToIndexSet:[browser3TableView selectedRowIndexes]]) {
            [browser3TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }	
	refreshing = FALSE;
	
    // update cachedArt
    [cachedArt removeAllObjects];
    
	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:PRLibraryViewDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRLibraryViewSelectionDidChangeNotification object:self];
    
    [pool drain];
}

// ========================================
// Action
// ========================================

- (void)selectAlbum
{	
	if ([albumTableView clickedRow] == -1) {
		[libraryTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
		return;
	}	
	int row = [albumTableView clickedRow];
	NSRect rectOfRow = [albumTableView rectOfRow:row];
	NSPoint point = rectOfRow.origin;
    point.x += rectOfRow.size.width + 5;
	int rowAtPoint = [libraryTableView rowAtPoint:point];
	[libraryTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowAtPoint] byExtendingSelection:FALSE];
}

- (void)playAlbum
{
	if ([albumTableView clickedRow] == -1) {
		return;
	}
	[[db playlists] clearPlaylist:[now currentPlaylist]];
	
	int currentIndex;
	int row = [albumTableView clickedRow];
	if (row == 0) {
		currentIndex = 0;
	} else {
		currentIndex = [[albumSumCountArray objectAtIndex:(row - 1)] intValue];
	}
	int maxIndex = currentIndex + [[albumCountArray objectAtIndex:row] intValue];
    
	for (; currentIndex < maxIndex; currentIndex++) {
        PRFile file_;
		[[db libraryViewSource] file:&file_ forRow:currentIndex + 1 _error:NULL];
        [[db playlists] appendFile:file_ toPlaylist:[now currentPlaylist]];
	}
	
	[now playPlaylist:[now currentPlaylist] fileAtIndex:1];
	[now postNotificationForCurrentPlaylist];
}

// ========================================
// UI Misc
// ========================================

- (NSArray *)columnInfo
{
    return [[db playlists] albumListViewColumnInfoForPlaylist:currentPlaylist];
}

- (void)setColumnInfo:(NSArray *)columnInfo
{
    [[db playlists] setAlbumListViewColumnInfo:columnInfo forPlaylist:currentPlaylist];
}

- (NSTableColumn *)tableColumnForAttribute:(int)attribute
{
    if (attribute == PRArtistAlbumSort) {
        return [albumTableView tableColumnWithIdentifier:@"0"];
    } else {
        return [super tableColumnForAttribute:attribute];
    }
}

- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending
{
	// clear indicator and higlighted column image
	for (NSTableColumn *i in [libraryTableView tableColumns]) {
		[libraryTableView setIndicatorImage:nil inTableColumn:i];
	}
	for (NSTableColumn *i in [albumTableView tableColumns]) {
		[albumTableView setIndicatorImage:nil inTableColumn:i];
	}
	[libraryTableView setHighlightedTableColumn:nil];
	[albumTableView setHighlightedTableColumn:nil];
	
	// set highlighted column
	NSTableView *tableView = [tableColumn tableView];
	[tableView setHighlightedTableColumn:tableColumn];
	
	// set indicator image
	NSImage *indicatorImage;
	if (ascending) {
		indicatorImage = [NSImage imageNamed:@"NSAscendingSortIndicator"];
	} else {
		indicatorImage = [NSImage imageNamed:@"NSDescendingSortIndicator"];
	}
	[tableView setIndicatorImage:indicatorImage inTableColumn:tableColumn];	
}

// ========================================
// TableView DataSource
// ========================================

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{	
	if (tableView == libraryTableView) {
		return libraryCount;
	} else if (tableView == albumTableView) {
		return [albumCountArray count];
	} else {
		return [super numberOfRowsInTableView:tableView];
	}
}

- (id)            tableView:(NSTableView *)tableView 
  objectValueForTableColumn:(NSTableColumn *)tableColumn 
      			        row:(NSInteger)tableRow
{
	if (tableView == albumTableView) {
		PRFile file;
		
		int dbRow = [[albumSumCountArray objectAtIndex:tableRow] intValue];
		[[db libraryViewSource] file:&file forRow:dbRow _error:nil];
        
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:db forKey:@"db"];
		[dict setObject:[NSNumber numberWithInt:file] forKey:@"file"];
        [dict setObject:[NSImage imageNamed:@"PRLightAlbumArt"] forKey:@"icon"];
        
//        // synchronous drawing
//        [dict setObject:[NSImage imageNamed:@"PRLightAlbumArt"] forKey:@"icon"];
//        int guessedFile;
//        for (int i = dbRow - [[albumCountArray objectAtIndex:tableRow] intValue] + 1; i < dbRow + 1; i++) {
//            [libSrc file:&guessedFile forRow:i _error:nil];
//            if ([[db albumArtController] fileHasAlbumArt:guessedFile]) {
//                NSImage *icon;
//                [[db albumArtController] thumbnail:&icon forFile:guessedFile _error:nil];
//                [dict setObject:icon forKey:@"icon"];
//                break;
//            }
//            guessedFile = file;
//        }
        
        // asynchronous drawing
        [lock lock];
        NSImage *icon = [cachedArt objectForKey:[NSNumber numberWithInt:file]];
        [lock unlock];
		if (icon) {
            [dict setObject:icon forKey:@"icon"];
        } else {
            NSMutableIndexSet *mfiles = [[[NSMutableIndexSet alloc] init] autorelease];
            for (int i = dbRow - [[albumCountArray objectAtIndex:tableRow] intValue] + 1; i < dbRow + 1; i++) {
                int guessedFile;
                [[db libraryViewSource] file:&guessedFile forRow:i _error:nil];
                [mfiles addIndex:guessedFile];
            }
            NSIndexSet *files = [[[NSIndexSet alloc] initWithIndexSet:mfiles] autorelease];
            NSRect dirtyRect = [albumTableView rectOfRow:tableRow];
            
            NSMethodSignature *methodSignature = [[self class] instanceMethodSignatureForSelector:@selector(cacheAlbumArtForFile:files:dirtyRect:)];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            [invocation setTarget:self];
            [invocation setSelector:@selector(cacheAlbumArtForFile:files:dirtyRect:)];
            [invocation setArgument:&file atIndex:2];
            [invocation setArgument:&files atIndex:3];
            [invocation setArgument:&dirtyRect atIndex:4];
            [invocation retainArguments];
            [invocation performSelectorInBackground:@selector(invoke) withObject:nil];
        }
		return dict;
	} else {
		return [super tableView:tableView objectValueForTableColumn:tableColumn row:tableRow];
	}
}

- (void)cacheAlbumArtForFile:(int)file files:(NSIndexSet *)files dirtyRect:(NSRect)dirtyRect
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSImage *icon = nil;
    NSInteger guessedFile = [files firstIndex];
    while (guessedFile != NSNotFound) {
        if ([[db albumArtController] fileHasAlbumArt:guessedFile]) {
            [[db albumArtController] albumArt:&icon forFile:guessedFile _error:nil];
            break;
        }
        guessedFile = [files indexGreaterThanIndex:guessedFile];
    }
    
    if (!icon) {
        icon = [NSImage imageNamed:@"PRLightAlbumArt"];
    }
    
    [lock lock];
    if ([cachedArt count] > 20) {
        [cachedArt removeAllObjects];
    }
    [cachedArt setObject:icon forKey:[NSNumber numberWithInt:file]];
    [lock unlock];
    
    NSMethodSignature *methodSignature = [[NSTableView class] instanceMethodSignatureForSelector:@selector(setNeedsDisplayInRect:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:albumTableView];
    [invocation setSelector:@selector(setNeedsDisplayInRect:)];
    [invocation setArgument:&dirtyRect atIndex:2];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:FALSE];
    
    [pool drain];
}

// ========================================
// TableView DragAndDrop
// ========================================

- (BOOL)     tableView:(NSTableView *)tableView
  writeRowsWithIndexes:(NSIndexSet *)rowIndexes
		  toPasteboard:(NSPasteboard*)pboard
{
	NSData *data;
	NSInteger currentIndex = 0;
	PRFile file;
	NSMutableArray *files = [NSMutableArray array];
	NSNumber *fileNumber;
	
	if (tableView == albumTableView) {
		int row = [rowIndexes firstIndex];
		if (row == 0) {
			currentIndex = 0;
		} else {
			currentIndex = [[albumSumCountArray objectAtIndex:(row - 1)] intValue];
		}
		int maxIndex = currentIndex + [[albumCountArray objectAtIndex:row] intValue];
		
		for (; currentIndex < maxIndex; currentIndex++) {
			[[db libraryViewSource] file:&file forRow:currentIndex + 1 _error:nil];
			fileNumber = [NSNumber numberWithInt:file];
			[files addObject:fileNumber];
		}
		
		// archive files and save to pasteboard
		if ([files count] == 0) {
			return FALSE;
		}
		data = [NSKeyedArchiver archivedDataWithRootObject:files];
		[pboard declareTypes:[NSArray arrayWithObject:PRFilePboardType] owner:self];
		[pboard setData:data forType:PRFilePboardType];
		
		return TRUE;		
	} 
	
	return [super tableView:tableView writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
}

- (NSDragOperation)tableView:(NSTableView*)tableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	return NSDragOperationNone;
}

// ========================================
// TableView Delegate
// ========================================

//- (NSCell *)   tableView:(NSTableView *)tableView 
//  dataCellForTableColumn:(NSTableColumn *)tableColumn 
//					 row:(NSInteger)row
//{
//	if (tableView == libraryTableView && 
//		[self dbRowForTableRow:row] == -1) {
//		return [[[NSCell alloc] init] autorelease];
//	} else {
//		return [tableColumn dataCell];
//	}
//}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if (tableView == albumTableView) {
		int sortColumn = [[db playlists] albumListViewSortColumnForPlaylist:currentPlaylist];
		int ascending = [[db playlists] albumListViewAscendingForPlaylist:currentPlaylist];

        if (sortColumn == PRArtistAlbumSort) {
            ascending = !ascending;
        } else {
            ascending = TRUE;
        }
        
        [[db playlists] setValue:[NSNumber numberWithInt:PRArtistAlbumSort] 
                     forPlaylist:currentPlaylist 
                       attribute:PRAlbumListViewSortColumnPlaylistAttribute];
        [[db playlists] setValue:[NSNumber numberWithInt:ascending] 
                     forPlaylist:currentPlaylist 
                       attribute:PRAlbumListViewAscendingPlaylistAttribute];
		[self setCurrentPlaylist:currentPlaylist];
	}
	[super tableView:tableView didClickTableColumn:tableColumn];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	if (tableView == albumTableView) {
		if ([[albumCountArray objectAtIndex:row] intValue] < 10) {
			return (19 * 11) - 2; 
		} else {
			return 19 * ([[albumCountArray objectAtIndex:row] intValue] + 1) - 2; 
		}
	} else {
		return 17;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == libraryTableView) {
		int index = 0;
		NSMutableIndexSet *selectionIndexes = 
          [[[NSMutableIndexSet alloc] initWithIndexSet:[libraryTableView selectedRowIndexes]] autorelease];
		
		while ([selectionIndexes indexGreaterThanOrEqualToIndex:index] != NSNotFound) {
			if ([self dbRowForTableRow:index] == -1) {
				[selectionIndexes removeIndex:index];
			}
			index++;
		}
		[libraryTableView selectRowIndexes:selectionIndexes byExtendingSelection:FALSE];
	}
	[super tableViewSelectionDidChange:notification];
}

- (NSIndexSet *)             tableView:(NSTableView *)tableView
  selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	NSIndexSet *selectionIndexes = proposedSelectionIndexes;
	if (tableView == albumTableView) {
		selectionIndexes = [NSIndexSet indexSet];
	}
	return [super tableView:tableView selectionIndexesForProposedSelection:selectionIndexes];
}

- (int)dbRowForTableRow:(int)tableRow
{
	if (![tableIndexes containsIndex:tableRow]) {
		return -1;
	}
    return [tableIndexes countOfIndexesInRange:NSMakeRange(0, tableRow + 1)];
}

- (int)tableRowForDbRow:(int)dbRow
{
	NSInteger tableRow = [tableIndexes nthIndex:dbRow];
	if (tableRow == NSNotFound) {
		return -1;
	}
    return tableRow;
}

- (BOOL)shouldDrawGridForRow:(int)row tableView:(NSTableView *)tableView
{
	if (tableView == libraryTableView) {
		return ([self dbRowForTableRow:row + 1] != -1 && [self dbRowForTableRow:row] == -1);
	} else if (tableView == albumTableView) {
		return (row + 1) != [self numberOfRowsInTableView:albumTableView];
	} else {
		return FALSE;
	}
}

@end