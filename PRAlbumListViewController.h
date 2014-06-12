#import "PRTableViewController.h"

@class PRSynchronizedScrollView;
@class PRAlbumTableView2;


@interface PRAlbumListViewController : PRTableViewController
/* Action */
- (void)selectAlbum;
- (void)playAlbum;

/* Misc */
- (BOOL)shouldDrawGridForRow:(int)row tableView:(NSTableView *)tableView;
- (void)cacheArtworkForItem:(PRItem *)item artworkInfo:(NSDictionary *)artworkInfo dirtyRect:(NSRect)dirtyRect;
@end