#import <Foundation/Foundation.h>
#import "PRPlaylists.h"
#import "PRLibraryViewController.h"

typedef enum {
    PRBrowserPositionHorizontal = 0, 
    PRBrowserPositionVertical = 1, 
    PRBrowserPositionHidden = 2,
} PRBrowserPosition;

@interface PRPlaylists (PRPlaylists_Extensions)

- (NSMutableDictionary *)browserInfoForPlaylist:(PRPlaylist)playlist;
- (void)setBrowserInfo:(NSMutableDictionary *)browserInfo forPlaylist:(PRPlaylist)playlist;
- (int)isVerticalForPlaylist:(PRPlaylist)playlist;
- (void)setVertical:(int)vertical forPlaylist:(PRPlaylist)playlist;
- (float)verticalBrowser3WidthForPlaylist:(PRPlaylist)playlist;
- (void)setVerticalBrowser3Width:(float)width forPlaylist:(PRPlaylist)playlist;
- (float)horizontalBrowserHeightForPlaylist:(PRPlaylist)playlist;
- (void)setHorizontalBrowserHeight:(float)height forPlaylist:(PRPlaylist)playlist;

- (BOOL)listViewAscendingForPlaylist:(PRPlaylist)playlist;
- (void)setListViewAscending:(BOOL)ascending forPlaylist:(PRPlaylist)playlist;
- (BOOL)albumListViewAscendingForPlaylist:(PRPlaylist)playlist;
- (void)setAlbumListViewAscending:(BOOL)ascending forPlaylist:(PRPlaylist)playlist;

- (PRFileAttribute)listViewSortColumnForPlaylist:(PRPlaylist)playlist;
- (void)setListViewSortColumn:(PRFileAttribute)sortColumn forPlaylist:(PRPlaylist)playlist;
- (PRFileAttribute)albumListViewSortColumnForPlaylist:(PRPlaylist)playlist;
- (void)setAlbumListViewSortColumn:(PRFileAttribute)sortColumn forPlaylist:(PRPlaylist)playlist;

- (NSArray *)listViewColumnInfoForPlaylist:(PRPlaylist)playlist;
- (void)setListViewColumnInfo:(NSArray *)columnInfo forPlaylist:(PRPlaylist)playlist;
- (NSArray *)albumListViewColumnInfoForPlaylist:(PRPlaylist)playlist;
- (void)setAlbumListViewColumnInfo:(NSArray *)columnInfo forPlaylist:(PRPlaylist)playlist;

- (NSArray *)selectionForBrowser:(int)browser playlist:(PRPlaylist)playlist;
- (void)setSelection:(NSArray *)selection forBrowser:(int)browser playlist:(PRPlaylist)playlist;
- (NSArray *)browser1SelectionForPlaylist:(PRPlaylist)playlist;
- (void)setBrowser1Selection:(NSArray *)selection forPlaylist:(PRPlaylist)playlist;
- (NSArray *)browser2SelectionForPlaylist:(PRPlaylist)playlist;
- (void)setBrowser2Selection:(NSArray *)selection forPlaylist:(PRPlaylist)playlist;
- (NSArray *)browser3SelectionForPlaylist:(PRPlaylist)playlist;
- (void)setBrowser3Selection:(NSArray *)selection forPlaylist:(PRPlaylist)playlist;

- (int)attributeForBrowser:(int)browser playlist:(PRPlaylist)playlist;
- (void)setAttribute:(PRFileAttribute)attribute forBrowser:(int)browser playlist:(PRPlaylist)playlist;
- (int)browser1AttributeForPlaylist:(PRPlaylist)playlist;
- (void)setBrowser1Attribute:(PRFileAttribute)attribute forPlaylist:(PRPlaylist)playlist;
- (int)browser2AttributeForPlaylist:(PRPlaylist)playlist;
- (void)setBrowser2Attribute:(PRFileAttribute)attribute forPlaylist:(PRPlaylist)playlist;
- (int)browser3AttributeForPlaylist:(PRPlaylist)playlist;
- (void)setBrowser3Attribute:(PRFileAttribute)attribute forPlaylist:(PRPlaylist)playlist;

- (PRPlaylistType)typeForPlaylist:(PRPlaylist)playlist;
- (void)setType:(PRPlaylistType)type forPlaylist:(PRPlaylist)playlist;

- (NSString *)titleForPlaylist:(PRPlaylist)playlist;
- (void)setTitle:(NSString *)title forPlaylist:(PRPlaylist)playlist;

- (NSString *)searchForPlaylist:(PRPlaylist)playlist;
- (void)setSearch:(NSString *)search forPlaylist:(PRPlaylist)playlist;

- (PRLibraryViewMode)libraryViewModeForPlaylist:(PRPlaylist)playlist;
- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode forPlaylist:(PRPlaylist)playlist;

- (NSDictionary *)ruleForPlaylist:(PRPlaylist)playlist;
- (void)setRule:(NSDictionary *)rule forPlaylist:(PRPlaylist)playlist;

@end
