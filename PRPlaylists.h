#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
@class PRDb;
@class PRList;
@class PRLibraryDescription;
@class PRBrowserDescription;

typedef NSNumber PRListID;
typedef NSNumber PRListItemID;

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

typedef NS_ENUM(NSInteger, PRBrowserPosition) {
    PRBrowserPositionHorizontal = 0, 
    PRBrowserPositionVertical = 1, 
    PRBrowserPositionHidden = 2,
};

typedef NS_ENUM(NSInteger, PRSort) {
    PRArtistAlbumSort = -1,
    PRPlaylistIndexSort = -2,
};

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
- (PRListID *)libraryList;
- (PRListID *)nowPlayingList;

// zList Getters
- (BOOL)zListIDs:(NSArray **)outValue;
- (BOOL)zLibraryList:(PRListID **)outValue;
- (BOOL)zNowPlayingList:(PRListID **)outValue;
- (BOOL)zLists:(NSArray **)outValue;
- (BOOL)zListForListID:(PRListID *)list out:(PRList **)outValue;

- (BOOL)zLibraryDescriptionForListID:(PRListID *)list out:(PRLibraryDescription **)outValue;
- (BOOL)zBrowserDescriptionsForList:(PRListID *)list out:(NSArray **)outValue; // Always returns array of 3 PRBrowserDescriptions

// List Setters
- (void)setValue:(id)value forList:(PRListID *)list attr:(PRListAttr *)attr;

// zList Setters
- (BOOL)zAddList:(PRList **)outValue;
- (BOOL)zAddStaticList:(PRList **)outValue;
- (BOOL)zAddSmartList:(PRList **)outValue;
- (BOOL)zRemoveList:(PRListID *)list;
- (BOOL)zSetValue:(id)value forList:(PRListID *)list attr:(PRListAttr *)attr;
- (BOOL)zSetListDescription:(PRList *)value forList:(PRListID *)list;

// zListItem Setters
- (BOOL)zAddItems:(NSArray *)items atIndex:(int)index toList:(PRListID *)list;
- (BOOL)zAppendItem:(PRListID *)item toList:(PRListID *)list;
- (BOOL)zRemoveItemsAtIndexes:(NSIndexSet *)indexes fromList:(PRListID *)list;
- (BOOL)zClearList:(PRListID *)list;
- (BOOL)zClearList:(PRListID *)list exceptIndex:(NSInteger)index;
- (BOOL)zMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)index inList:(PRListID *)list;
- (BOOL)zAppendItemsFromLibraryViewSourceToList:(PRListID *)list;
- (BOOL)zCopyItemsFromList:(PRListID *)list toList:(PRListID *)list;

// ListItem Getters
- (int)countForList:(PRListID *)list;

// zListItem Getters
- (BOOL)zCountForList:(PRListID *)list out:(NSInteger *)outValue;
- (BOOL)zListItemAtIndex:(int)index inList:(PRListID *)list out:(PRListItemID **)outValue;
- (BOOL)zItemAtIndex:(int)index forList:(PRListID *)list out:(PRItemID **)outValue;
- (BOOL)zItemForListItem:(PRListItemID *)listItem out:(PRItemID **)outValue;
- (BOOL)zIndexForListItem:(PRListItemID *)listItem out:(NSInteger *)outValue;
- (BOOL)zListForListItem:(PRListItemID *)listItem out:(PRListID **)outValue;
- (BOOL)zList:(PRListID *)list containsItem:(PRItemID *)item out:(BOOL *)outValue;
- (BOOL)zIndexesOfItem:(PRItemID *)item inList:(PRListID *)list out:(NSIndexSet **)outValue;

// Update
- (BOOL)propagateListDelete;
- (BOOL)propagateListItemDelete;

@end
