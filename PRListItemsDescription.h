#import <Foundation/Foundation.h>
#import "PRPlaylists.h"
@class PRConnection;

@interface PRListItemsDescription : NSObject
- (id)initWithListID:(PRListID *)list connection:(PRConnection *)conn;
@property (nonatomic, readonly) PRListID *list;
@property (nonatomic, readonly) NSInteger count;
- (PRItemID *)itemIDAtIndex:(NSInteger)index; // Zero based
- (PRListItemID *)listItemIDAtIndex:(NSInteger)index;
@end

@interface PRNowPlayingListItemsDescription : PRListItemsDescription
@property (nonatomic, readonly) NSArray *albumCounts;
- (NSInteger)indexForIndexPath:(NSIndexPath *)index; // Zero based
- (NSIndexPath *)indexPathForIndex:(NSInteger)index;
- (NSRange)rangeForIndexPath:(NSIndexPath *)index;
@end
