#import "PRViewController.h"

@interface PRBrowserViewController : PRViewController
- (id)initWithCore:(PRCore *)core;

@property (nonatomic, weak) PRList *currentList;
@property (weak, readonly) NSDictionary *info;
@property (weak, readonly) NSArray *selection;

// These methods will change the browser selection but not the currentList.
- (void)highlightItem:(PRItem *)item;
- (void)highlightFiles:(NSArray *)items;
- (void)highlightArtist:(NSString *)artist;
- (void)browseToArtist:(NSString *)artist;
- (NSMenu *)browserHeaderMenu;
@end
