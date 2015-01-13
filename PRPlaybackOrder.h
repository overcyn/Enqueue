#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRDb;


@interface PRPlaybackOrder : NSObject
/* Initialization */
- (id)initWithDb:(PRDb *)sqlDb;
- (instancetype)initWithConnection:(PRConnection *)connection;
- (void)create;
- (BOOL)initialize;

/* Validation */
- (BOOL)clean;

/* Accessors */
- (BOOL)zCount:(NSInteger *)outValue;
- (BOOL)zAppendListItem:(PRListItemID *)listItem;
- (BOOL)zListItemAtIndex:(NSInteger)index out:(PRListItemID **)outValue;
- (BOOL)zClear;
- (BOOL)zListItemsInList:(PRListID *)list notInPlaybackOrderAfterIndex:(int)index out:(NSArray **)outValue;

- (int)count;
- (void)appendListItem:(PRListItemID *)listItem;
- (PRListItemID *)listItemAtIndex:(int)index;
- (void)clear;

- (NSArray *)listItemsInList:(PRListID *)list notInPlaybackOrderAfterIndex:(int)index;

/* Update */
- (BOOL)confirmPlaylistItemDelete:(NSError **)error;
@end
