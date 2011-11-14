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
	if (!(self = [super initWithNibName:@"PRAlbumListView" bundle:nil])) {return nil;}
    db = db_;
    now = now_;
    libraryViewController = libraryViewController_;
    refreshing = FALSE;
    monitorSelection = TRUE;
    currentPlaylist = -1;
    
    cachedArtwork = [[NSCache alloc] init];
    [cachedArtwork setCountLimit:50];
	return self;
}

- (void)dealloc
{
    [tableIndexes release];
    [albumCountArray release];
    [albumSumCountArray release];
    [cachedArtwork release];
    [super dealloc];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
    [albumTableView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.93 alpha:1.0]];
	[albumTableView setDataSource:self];
	[albumTableView setDelegate:self];
	[albumTableView setTarget:self];
	[albumTableView setAction:@selector(selectAlbum)];
	[albumTableView setNextResponder__:(PRAlbumTableView2 *)libraryTableView];
	[albumTableView setDoubleAction:@selector(playAlbum)];
	[[albumTableView headerView] setMenu:headerMenu];
	
	[(PRSynchronizedScrollView *)libraryScrollView2 setSynchronizedScrollView:albumScrollView];
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

- (void)reloadData:(BOOL)force
{	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	// update libSrc
    int tables = [[db libraryViewSource] refreshWithPlaylist:currentPlaylist force:force];
	
    // update albumCountArray, tableIndexes & libraryCount
	libraryCount = 0;
    [albumCountArray release];
    albumCountArray = [[[db libraryViewSource] albumCounts] retain];
    [tableIndexes release];
	tableIndexes = [[NSMutableIndexSet indexSet] retain];
	for (NSNumber *i in albumCountArray) {
		[tableIndexes addIndexesInRange:NSMakeRange(libraryCount, [i intValue])];
		if ([i intValue] < 10) {
			libraryCount += 10 + 1;
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
    monitorSelection = FALSE;
    NSIndexSet *indexSet;
    if ((tables & PRLibraryView) == PRLibraryView) {
        [libraryTableView reloadData];
        [albumTableView reloadData];
    }
    if ((tables & PRBrowser1View) == PRBrowser1View) {
        [browser1TableView reloadData];
        indexSet = [[db libraryViewSource] selectionForBrowser:1];
        if (![indexSet isEqualToIndexSet:[browser1TableView selectedRowIndexes]]) {
            [browser1TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }
    if ((tables & PRBrowser2View) == PRBrowser2View) {
        [browser2TableView reloadData];
        indexSet = [[db libraryViewSource] selectionForBrowser:2];
        if (![indexSet isEqualToIndexSet:[browser2TableView selectedRowIndexes]]) {
            [browser2TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }
    if ((tables & PRBrowser3View) == PRBrowser3View) {
        [browser3TableView reloadData];
        indexSet = [[db libraryViewSource] selectionForBrowser:3];
        if (![indexSet isEqualToIndexSet:[browser3TableView selectedRowIndexes]]) {
            [browser3TableView selectRowIndexes:indexSet byExtendingSelection:FALSE];
        }
    }	
	refreshing = FALSE;
    monitorSelection = TRUE;
	
    // update cachedArt
    [cachedArtwork removeAllObjects];
    
	// post notification
	[[NSNotificationCenter defaultCenter] postLibraryViewChanged];
    [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
    
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
    [now stop];
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
        PRFile file = [[db libraryViewSource] fileForRow:currentIndex + 1];
        [[db playlists] appendFile:file toPlaylist:[now currentPlaylist]];
	}
	
    [[NSNotificationCenter defaultCenter] postPlaylistFilesChanged:[now currentPlaylist]];
	[now playItemAtIndex:1];
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
		int dbRow = [[albumSumCountArray objectAtIndex:tableRow] intValue];
		PRFile file = [[db libraryViewSource] fileForRow:dbRow];
        
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:db forKey:@"db"];
		[dict setObject:[NSNumber numberWithInt:file] forKey:@"file"];
        [dict setObject:[NSImage imageNamed:@"PRLightAlbumArt"] forKey:@"icon"];
                
        // asynchronous drawing
        NSImage *icon = [cachedArtwork objectForKey:[NSNumber numberWithInt:file]];
		if (icon) {
            [dict setObject:icon forKey:@"icon"];
        } else {
            NSMutableIndexSet *mfiles = [[[NSMutableIndexSet alloc] init] autorelease];
            for (int i = dbRow - [[albumCountArray objectAtIndex:tableRow] intValue] + 1; i < dbRow + 1; i++) {
                int guessedFile = [[db libraryViewSource] fileForRow:i];
                [mfiles addIndex:guessedFile];
            }
            NSDictionary *artworkInfo = [[db albumArtController] artworkInfoForFiles:mfiles];
            NSRect dirtyRect = [albumTableView rectOfRow:tableRow];            
            [[NSOperationQueue backgroundQueue] addBlock:^{[self cacheAlbumArtForFile:file artworkInfo:artworkInfo dirtyRect:dirtyRect];}];
        }
		return dict;
	} else {
		return [super tableView:tableView objectValueForTableColumn:tableColumn row:tableRow];
	}
}

- (void)cacheAlbumArtForFile:(int)file artworkInfo:(NSDictionary *)artworkInfo dirtyRect:(NSRect)dirtyRect
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSImage *icon = [[db albumArtController] artworkForArtworkInfo:artworkInfo];;    
    if (!icon) {
        icon = [NSImage imageNamed:@"PRLightAlbumArt"];
    }
    [cachedArtwork setObject:icon forKey:[NSNumber numberWithInt:file]];
    
    [[NSOperationQueue mainQueue] addBlock:^{[albumTableView setNeedsDisplayInRect:dirtyRect];}];
    [pool drain];
}

// ========================================
// TableView DragAndDrop
// ========================================

- (BOOL)     tableView:(NSTableView *)tableView
  writeRowsWithIndexes:(NSIndexSet *)rowIndexes
		  toPasteboard:(NSPasteboard*)pboard
{
	NSInteger currentIndex = 0;
	NSMutableArray *files = [NSMutableArray array];
	if (tableView == albumTableView) {
		int row = [rowIndexes firstIndex];
		if (row == 0) {
			currentIndex = 0;
		} else {
			currentIndex = [[albumSumCountArray objectAtIndex:(row - 1)] intValue];
		}
		int maxIndex = currentIndex + [[albumCountArray objectAtIndex:row] intValue];
		
		for (; currentIndex < maxIndex; currentIndex++) {
			PRFile file = [[db libraryViewSource] fileForRow:currentIndex + 1];
			NSNumber *fileNumber = [NSNumber numberWithInt:file];
			[files addObject:fileNumber];
		}
		
		// archive files and save to pasteboard
		if ([files count] == 0) {
			return FALSE;
		}
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:files];
		[pboard declareTypes:[NSArray arrayWithObject:PRFilePboardType] owner:self];
		[pboard setData:data forType:PRFilePboardType];
		return TRUE;
	} else if (tableView == libraryTableView) {
        if ([self dbRowForTableRow:[rowIndexes firstIndex]] == -1) {
            return FALSE;
        }
        return [super tableView:tableView writeRowsWithIndexes:rowIndexes toPasteboard:pboard];
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
		int sortColumn = [self sortColumn];
		int ascending = [self ascending];

        if (sortColumn == PRArtistAlbumSort) {
            ascending = !ascending;
        } else {
            ascending = TRUE;
        }
        
        [self setSortColumn:PRArtistAlbumSort];
        [self setAscending:ascending];
        [self loadTableColumns];
        [self reloadData:FALSE];
        [tableView selectColumnIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        return;
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
	NSInteger tableRow = [tableIndexes indexAtPosition:dbRow];
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