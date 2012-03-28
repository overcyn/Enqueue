#import "PRAlbumListViewController.h"
#import "PRTableViewController.h"
#import "PRTableViewController+Private.h"
#import "PRLibraryViewSource.h"
#import "PRSynchronizedScrollView.h"
#import "PRNowPlayingController.h"
#import "PRDb.h"
#import "PRAlbumArtController.h"
#import "PRAlbumTableView2.h"
#import "NSIndexSet+Extensions.h"
#import "PRCore.h"

@implementation PRAlbumListViewController

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core {
	if (!(self = [super initWithNibName:@"PRAlbumListView" bundle:nil])) {return nil;}
    _core = core;
    db = [core db];
    now = [core now];
    refreshing = FALSE;
    _updatingTableViewSelection = TRUE;
    _currentList = nil;
    
    _cachedArtwork = [[NSCache alloc] init];
    [_cachedArtwork setCountLimit:50];
	return self;
}

- (void)dealloc {
    [tableIndexes release];
    [albumCountArray release];
    [albumSumCountArray release];
    [_cachedArtwork release];
    [super dealloc];
}

- (void)awakeFromNib {
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

- (PRItemAttr *)sortAttr {
    return [[db playlists] albumListViewSortAttrForList:_currentList];
}

- (void)setSortAttr:(NSString *)attr {
    [[db playlists] setAlbumListViewSortAttr:attr forList:_currentList];
}

- (BOOL)ascending {
    return [[db playlists] albumListViewAscendingForList:_currentList];
}

- (void)setAscending:(BOOL)ascending {
    [[db playlists] setAlbumListViewAscending:ascending forList:_currentList];
}

// ========================================
// Update

- (void)reloadData:(BOOL)force {		
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	// update libSrc
    int tables = [[db libraryViewSource] refreshWithList:_currentList force:force];
	
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
    
    // update cachedArt
    [_cachedArtwork removeAllObjects];
    
    // reload tables
    _updatingTableViewSelection = FALSE;
    if ((tables & PRLibraryView) == PRLibraryView) {
        [libraryTableView reloadData];
        [albumTableView reloadData];
    }
    if ((tables & PRBrowser1View) == PRBrowser1View) {
        [browser1TableView reloadData];
    }
    if ((tables & PRBrowser2View) == PRBrowser2View) {    
        [browser2TableView reloadData];
    }
    if ((tables & PRBrowser3View) == PRBrowser3View) {
        [browser3TableView reloadData];
    }
    [browser1TableView selectRowIndexes:[[db libraryViewSource] selectionForBrowser:1] byExtendingSelection:FALSE];
    [browser2TableView selectRowIndexes:[[db libraryViewSource] selectionForBrowser:2] byExtendingSelection:FALSE];
    [browser3TableView selectRowIndexes:[[db libraryViewSource] selectionForBrowser:3] byExtendingSelection:FALSE];
    _updatingTableViewSelection = TRUE;
	
    [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
    [pool drain];
}

// ========================================
// Action

- (void)selectAlbum {	
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

- (void)playAlbum {
	if ([albumTableView clickedRow] == -1) {
		return;
	}
    [now stop];
    [[db playlists] clearList:[now currentList]];
	
	int currentIndex;
	int row = [albumTableView clickedRow];
	if (row == 0) {
		currentIndex = 0;
	} else {
		currentIndex = [[albumSumCountArray objectAtIndex:(row - 1)] intValue];
	}
	int maxIndex = currentIndex + [[albumCountArray objectAtIndex:row] intValue];
    
	for (; currentIndex < maxIndex; currentIndex++) {
        PRItem *item = [[db libraryViewSource] itemForRow:currentIndex + 1];
        [[db playlists] appendItem:item toList:[now currentList]];
	}
	
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
	[now playItemAtIndex:1];
}

// ========================================
// UI Misc

- (NSArray *)columnInfo {
    return [[db playlists] albumListViewInfoForList:_currentList];
}

- (void)setColumnInfo:(NSArray *)columnInfo {
    [[db playlists] setAlbumListViewInfo:columnInfo forList:_currentList];
}

- (NSTableColumn *)tableColumnForAttr:(NSString *)attr {
    if ([attr isEqual:PRListSortArtistAlbum]) {
        return [albumTableView tableColumnWithIdentifier:@"0"];
    } else {
        return [super tableColumnForAttr:attr];
    }
}

- (void)highlightTableColumn:(NSTableColumn *)tableColumn ascending:(BOOL)ascending {
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {	
	if (tableView == libraryTableView) {
		return libraryCount;
	} else if (tableView == albumTableView) {
		return [albumCountArray count];
	} else {
		return [super numberOfRowsInTableView:tableView];
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)tableRow {
	if (tableView == albumTableView) {
		int dbRow = [[albumSumCountArray objectAtIndex:tableRow] intValue];
		PRItem *item = [[db libraryViewSource] itemForRow:dbRow];
        
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:db forKey:@"db"];
		[dict setObject:item forKey:@"file"];
        [dict setObject:[NSImage imageNamed:@"PRLightAlbumArt"] forKey:@"icon"];
                
        // asynchronous drawing
        NSImage *icon = [_cachedArtwork objectForKey:item];
		if (icon) {
            [dict setObject:icon forKey:@"icon"];
        } else {
			NSMutableArray *items = [NSMutableArray array];
            for (int i = dbRow - [[albumCountArray objectAtIndex:tableRow] intValue] + 1; i < dbRow + 1; i++) {
				[items addObject:[[db libraryViewSource] itemForRow:i]];
            }
            NSDictionary *artworkInfo = [[db albumArtController] artworkInfoForItems:items];
            NSRect dirtyRect = [albumTableView rectOfRow:tableRow];            
            [[NSOperationQueue backgroundQueue] addBlock:^{[self cacheArtworkForItem:item artworkInfo:artworkInfo dirtyRect:dirtyRect];}];
        }
		return dict;
	} else {
		return [super tableView:tableView objectValueForTableColumn:tableColumn row:tableRow];
	}
}

- (void)cacheArtworkForItem:(PRItem *)item artworkInfo:(NSDictionary *)artworkInfo dirtyRect:(NSRect)dirtyRect {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSImage *icon = [[db albumArtController] artworkForArtworkInfo:artworkInfo];;    
    if (!icon) {
        icon = [NSImage imageNamed:@"PRLightAlbumArt"];
    }
    [_cachedArtwork setObject:icon forKey:item];
    
    [[NSOperationQueue mainQueue] addBlock:^{[albumTableView setNeedsDisplayInRect:dirtyRect];}];
    [pool drain];
}

// ========================================
// TableView DragAndDrop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
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
			PRFile file = [[[db libraryViewSource] itemForRow:currentIndex + 1] intValue];
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

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
	return NSDragOperationNone;
}

// ========================================
// TableView Delegate

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

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	if (tableView == albumTableView) {
        if ([[self sortAttr] isEqual:PRListSortArtistAlbum]) {
            [self setAscending:[self ascending]];
        } else {
            [self setAscending:TRUE];
        }
        [self setSortAttr:PRListSortArtistAlbum];
        [self loadTableColumns];
        [self reloadData:FALSE];
        [tableView selectColumnIndexes:[NSIndexSet indexSet] byExtendingSelection:FALSE];
        return;
	}
	[super tableView:tableView didClickTableColumn:tableColumn];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
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

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if ([notification object] == libraryTableView) {
		int index = 0;
		NSMutableIndexSet *selectionIndexes = [[[NSMutableIndexSet alloc] initWithIndexSet:[libraryTableView selectedRowIndexes]] autorelease];
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

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)indexes {
	if (tableView == albumTableView) {
		return [NSIndexSet indexSet];
	}
	return [super tableView:tableView selectionIndexesForProposedSelection:indexes];
}

- (int)dbRowForTableRow:(int)tableRow {
	if (![tableIndexes containsIndex:tableRow]) {
		return -1;
	}
    return [tableIndexes countOfIndexesInRange:NSMakeRange(0, tableRow + 1)];
}

- (int)tableRowForDbRow:(int)dbRow {
	NSInteger tableRow = [tableIndexes indexAtPosition:dbRow];
	if (tableRow == NSNotFound) {
		return -1;
	}
    return tableRow;
}

- (BOOL)shouldDrawGridForRow:(int)row tableView:(NSTableView *)tableView {
	if (tableView == libraryTableView) {
		return ([self dbRowForTableRow:row + 1] != -1 && [self dbRowForTableRow:row] == -1);
	} else if (tableView == albumTableView) {
		return (row + 1) != [self numberOfRowsInTableView:albumTableView];
	} else {
		return FALSE;
	}
}

@end