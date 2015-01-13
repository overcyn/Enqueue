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
- (BOOL)zAppendListItem:(PRListItem *)listItem;
- (BOOL)zListItemAtIndex:(NSInteger)index out:(PRListItem **)outValue;
- (BOOL)zClear;
- (BOOL)zListItemsInList:(PRList *)list notInPlaybackOrderAfterIndex:(int)index out:(NSArray **)outValue;

- (int)count;
- (void)appendListItem:(PRListItem *)listItem;
- (PRListItem *)listItemAtIndex:(int)index;
- (void)clear;

- (NSArray *)listItemsInList:(PRList *)list notInPlaybackOrderAfterIndex:(int)index;

/* Update */
- (BOOL)confirmPlaylistItemDelete:(NSError **)error;
@end
