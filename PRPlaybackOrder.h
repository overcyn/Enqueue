#import <Cocoa/Cocoa.h>
@class PRDb;


@interface PRPlaybackOrder : NSObject {
	PRDb *db;
}
/* Initialization */
- (id)initWithDb:(PRDb *)sqlDb;
- (void)create;
- (BOOL)initialize;

/* Validation */
- (BOOL)clean;

/* Accessors */
- (int)count;
- (void)appendListItem:(PRListItem *)listItem;
- (PRListItem *)listItemAtIndex:(int)index;
- (void)clear;

- (NSArray *)listItemsInList:(PRList *)list notInPlaybackOrderAfterIndex:(int)index;

/* Update */
- (BOOL)confirmPlaylistItemDelete:(NSError **)error;
@end
