#import <Cocoa/Cocoa.h>
#import "PRTableViewController.h"

@class PRSynchronizedScrollView, PRAlbumTableView2;

@interface PRAlbumListViewController : PRTableViewController
{
	IBOutlet PRSynchronizedScrollView *albumScrollView;
	IBOutlet PRSynchronizedScrollView *libraryScrollView2;
	IBOutlet PRAlbumTableView2 *albumTableView;
	
	int libraryCount; // number of rows in libraryTableView
	NSMutableIndexSet *tableIndexes; // rows in library table view which are filled
	NSArray *albumCountArray; // array of album counts
	NSMutableArray *albumSumCountArray; // array of sum of album counts
    
    // cached album art
    NSLock *lock;
    NSMutableDictionary *cachedArt;
}

// action
- (void)selectAlbum;
- (void)playAlbum;

- (BOOL)shouldDrawGridForRow:(int)row tableView:(NSTableView *)tableView;

- (void)cacheAlbumArtForFile:(int)file files:(NSIndexSet *)files dirtyRect:(NSRect)dirtyRect;

@end