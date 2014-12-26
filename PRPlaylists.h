#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRDb.h"

@class PRDb;
@class PRListDescription;
@class PRLibraryDescription;
@class PRBrowserDescription;


typedef NSNumber PRList;
typedef NSNumber PRListItem;

typedef NSString PRListType;
extern NSString * const PRListTypeLibrary;
extern NSString * const PRListTypeNowPlaying;
extern NSString * const PRListTypeStatic;
extern NSString * const PRListTypeSmart;

typedef NSString PRListAttr;
extern NSString * const PRListAttrTitle;
extern NSString * const PRListAttrType;
extern NSString * const PRListAttrRules;
extern NSString * const PRListAttrViewMode;
extern NSString * const PRListAttrListViewInfo;
extern NSString * const PRListAttrListViewSortAttr;
extern NSString * const PRListAttrListViewAscending;
extern NSString * const PRListAttrAlbumListViewInfo;
extern NSString * const PRListAttrAlbumListViewSortAttr;
extern NSString * const PRListAttrAlbumListViewAscending;
extern NSString * const PRListAttrSearch;
extern NSString * const PRListAttrBrowser1Attr;
extern NSString * const PRListAttrBrowser1Selection;
extern NSString * const PRListAttrBrowser2Attr;
extern NSString * const PRListAttrBrowser2Selection;
extern NSString * const PRListAttrBrowser3Attr;
extern NSString * const PRListAttrBrowser3Selection;
extern NSString * const PRListAttrBrowserInfo;

typedef NSString PRListSort;
extern PRListSort * const PRListSortArtistAlbum;
extern PRListSort * const PRListSortIndex;

typedef enum {
    PRBrowserPositionHorizontal = 0, 
    PRBrowserPositionVertical = 1, 
    PRBrowserPositionHidden = 2,
} PRBrowserPosition;

typedef int PRPlaylist;
typedef int PRPlaylistItem;

typedef enum {
    PRLibraryPlaylistType = 0,
    PRNowPlayingPlaylistType = 1,
    PRStaticPlaylistType = 2,
    PRSmartPlaylistType = 3,
    PRDuplicatePlaylistType = 4,
    PRMissingPlaylistType = 5,
} PRPlaylistType;

typedef enum {
    PRArtistAlbumSort = -1,
    PRPlaylistIndexSort = -2,
} PRSort;


@interface PRPlaylists : NSObject
// Initialization
- (id)initWithDb:(PRDb *)db;
- (instancetype)initWithConnection:(PRConnection *)connection;
- (void)create;
- (BOOL)initialize;
- (BOOL)cleanPlaylists;
- (BOOL)cleanPlaylistItems;

// Misc
+ (NSArray *)listAttrProperties;
+ (NSString *)columnNameForListAttr:(PRListAttr *)attr;
+ (PRCol *)columnTypeForListAttr:(PRListAttr *)attr;
+ (NSNumber *)internalForListType:(PRListType *)listType;
+ (PRListType *)listTypeForInternal:(NSNumber *)internal;
+ (NSString *)columnNameForSortAttr:(PRItemAttr *)sortAttr;
+ (NSNumber *)internalForSortAttr:(PRItemAttr *)sortAttr;
+ (PRItemAttr *)sortAttrForInternal:(NSNumber *)internal;

// List Setters
- (NSArray *)lists;
- (PRList *)libraryList;
- (PRList *)nowPlayingList;
- (id)valueForList:(PRList *)list attr:(PRListAttr *)attr;

// zList Getters
- (BOOL)zLists:(NSArray **)outValue;
- (BOOL)zLibraryList:(PRList **)outValue;
- (BOOL)zNowPlayingList:(PRList **)outValue;
- (BOOL)zValueForList:(PRList *)list attr:(PRListAttr *)attr out:(id *)outValue;
- (BOOL)zListDescriptionForList:(PRList *)list out:(PRListDescription **)outValue;

- (BOOL)zLibraryDescriptionForList:(PRList *)list out:(PRLibraryDescription **)outValue;
- (BOOL)zBrowserDescriptionsForList:(PRList *)list out:(NSArray **)outValue; // Always returns 3


// List Setters
- (PRList *)addList;
- (PRList *)addStaticList;
- (PRList *)addSmartList;
- (void)removeList:(PRList *)list;
- (void)setValue:(id)value forList:(PRList *)list attr:(PRListAttr *)attr;

// zList Setters
- (BOOL)zAddList:(PRList **)outValue;
- (BOOL)zAddStaticList:(PRList **)outValue;
- (BOOL)zAddSmartList:(PRList **)outValue;
- (BOOL)zRemoveList:(PRList *)list;
- (BOOL)zSetValue:(id)value forList:(PRList *)list attr:(PRListAttr *)attr;
- (BOOL)zSetListDescription:(PRListDescription *)value forList:(PRList *)list;

// ListItem Setters
- (void)addItems:(NSArray *)items atIndex:(int)index toList:(PRList *)list;
- (void)appendItem:(PRList *)item toList:(PRList *)list;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes fromList:(PRList *)list;
- (void)clearList:(PRList *)list;
- (void)clearList:(PRList *)list exceptIndex:(int)index;
- (void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(int)index inList:(PRList *)list;
- (void)appendItemsFromLibraryViewSourceToList:(PRList *)list;
- (void)copyItemsFromList:(PRList *)list toList:(PRList *)list;

// zListItem Setters
- (BOOL)zAddItems:(NSArray *)items atIndex:(int)index toList:(PRList *)list;
- (BOOL)zAppendItem:(PRList *)item toList:(PRList *)list;
- (BOOL)zRemoveItemsAtIndexes:(NSIndexSet *)indexes fromList:(PRList *)list;
- (BOOL)zClearList:(PRList *)list;
- (BOOL)zClearList:(PRList *)list exceptIndex:(NSInteger)index;
- (BOOL)zMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)index inList:(PRList *)list;
- (BOOL)zAppendItemsFromLibraryViewSourceToList:(PRList *)list;
- (BOOL)zCopyItemsFromList:(PRList *)list toList:(PRList *)list;

// ListItem Getters
- (int)countForList:(PRList *)list;
- (PRListItem *)listItemAtIndex:(int)index inList:(PRList *)list;
- (PRItem *)itemAtIndex:(int)index forList:(PRList *)list;
- (PRItem *)itemForListItem:(PRListItem *)listItem;
- (int)indexForListItem:(PRListItem *)listItem;
- (PRList *)listForListItem:(PRListItem *)listItem;
- (BOOL)list:(PRList *)list containsItem:(PRItem *)item;
- (NSIndexSet *)indexesOfItem:(PRItem *)item inList:(PRList *)list; 

// zListItem Getters
- (BOOL)zCountForList:(PRList *)list out:(NSInteger *)outValue;
- (BOOL)zListItemAtIndex:(int)index inList:(PRList *)list out:(PRListItem **)outValue;
- (BOOL)zItemAtIndex:(int)index forList:(PRList *)list out:(PRItem **)outValue;
- (BOOL)zItemForListItem:(PRListItem *)listItem out:(PRItem **)outValue;
- (BOOL)zIndexForListItem:(PRListItem *)listItem out:(NSInteger *)outValue;
- (BOOL)zListForListItem:(PRListItem *)listItem out:(PRList **)outValue;
- (BOOL)zList:(PRList *)list containsItem:(PRItem *)item out:(BOOL *)outValue;
- (BOOL)zIndexesOfItem:(PRItem *)item inList:(PRList *)list out:(NSIndexSet **)outValue;

// ListItem Getters Misc
- (NSArray *)playlistsViewSource;

// zListItem Getters Misc
- (BOOL)zPlaylistsViewSource:(NSArray **)outValue;

// Update
- (BOOL)propagateListDelete;
- (BOOL)propagateListItemDelete;

// ========================================

- (NSMutableDictionary *)browserInfoForList:(PRList *)list;
- (void)setBrowserInfo:(NSMutableDictionary *)info forList:(PRList *)list;
- (int)verticalForList:(PRList *)list;
- (void)setVertical:(int)vertical forList:(PRList *)list;
- (float)verticalBrowserWidthForList:(PRList *)list;
- (void)setVerticalBrowserWidth:(float)width forList:(PRList *)list;
- (float)horizontalBrowserHeightForList:(PRList *)list;
- (void)setHorizontalBrowserHeight:(float)height forList:(PRList *)list;

- (BOOL)listViewAscendingForList:(PRList *)list;
- (void)setListViewAscending:(BOOL)ascending forList:(PRList *)list;
- (BOOL)albumListViewAscendingForList:(PRList *)list;
- (void)setAlbumListViewAscending:(BOOL)ascending forList:(PRList *)list;

- (PRItemAttr *)listViewSortAttrForList:(PRList *)list;
- (void)setListViewSortAttr:(PRItemAttr *)attr forList:(PRList *)list;
- (PRItemAttr *)albumListViewSortAttrForList:(PRList *)list;
- (void)setAlbumListViewSortAttr:(PRItemAttr *)attr forList:(PRList *)list;

- (NSArray *)listViewInfoForList:(PRList *)list;
- (void)setListViewInfo:(NSArray *)columnInfo forList:(PRList *)list;
- (NSArray *)albumListViewInfoForList:(PRList *)list;
- (void)setAlbumListViewInfo:(NSArray *)columnInfo forList:(PRList *)list;

- (NSArray *)selectionForBrowser:(int)browser list:(PRList *)list;
- (void)setSelection:(NSArray *)selection forBrowser:(int)browser list:(PRList *)list;
- (PRItemAttr *)attrForBrowser:(int)browser list:(PRList *)list;
- (void)setAttr:(PRItemAttr *)attr forBrowser:(int)browser list:(PRList *)list;

- (PRListType *)typeForList:(PRList *)list;
- (void)setType:(PRListType *)type forList:(PRList *)list;

- (NSString *)titleForList:(PRList *)list;
- (void)setTitle:(NSString *)title forList:(PRList *)list;

- (NSString *)searchForList:(PRList *)list;
- (void)setSearch:(NSString *)search forList:(PRList *)list;

- (int)viewModeForList:(PRList *)list;
- (void)setViewMode:(int)viewMode forList:(PRList *)list;

- (NSDictionary *)ruleForList:(PRList *)list;
- (void)setRule:(NSDictionary *)rule forList:(PRList *)list;
@end
