#import "PRBrowserViewController.h"
#import "PRPlaylists.h"
@class PRSynchronizedScrollView;
@class PRAlbumTableView2;


@interface PRAlbumListViewController : PRBrowserViewController
/* Action */
- (void)selectAlbum;
- (void)playAlbum;

/* Misc */
- (BOOL)shouldDrawGridForRow:(int)row tableView:(NSTableView *)tableView;
- (void)cacheArtworkForItem:(PRItem *)item artworkInfo:(NSDictionary *)artworkInfo dirtyRect:(NSRect)dirtyRect;
@end