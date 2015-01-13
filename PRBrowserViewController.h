#import "PRViewController.h"
#import "PRPlaylists.h"
@class PRBridge;

@interface PRBrowserViewController : PRViewController
- (id)initWithBridge:(PRBridge *)bridge;
@property (nonatomic, weak) PRListID *currentList;
@property (weak, readonly) NSDictionary *info;
@property (weak, readonly) NSArray *selection;
// These methods will change the browser selection but not the currentList.
- (void)highlightItem:(PRItemID *)item;
- (void)highlightFiles:(NSArray *)items;
- (void)highlightArtist:(NSString *)artist;
- (void)browseToArtist:(NSString *)artist;
- (NSMenu *)browserHeaderMenu;
@end
