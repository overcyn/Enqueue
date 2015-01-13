#import <Foundation/Foundation.h>
@class PRConnection;

@interface PRListItemsDescription : NSObject
- (id)initWithList:(PRList *)list connection:(PRConnection *)conn;
@property (nonatomic, readonly) PRList *list;
@property (nonatomic, readonly) NSInteger count;
- (PRItem *)itemAtIndex:(NSInteger)index; // Zero based
- (PRListItem *)listItemAtIndex:(NSInteger)index;
@end

@interface PRNowPlayingListItemsDescription : PRListItemsDescription
@property (nonatomic, readonly) NSArray *albumCounts;
- (NSInteger)indexForIndexPath:(NSIndexPath *)index; // Zero based
- (NSIndexPath *)indexPathForIndex:(NSInteger)index;
- (NSRange)rangeForIndexPath:(NSIndexPath *)index;
@end
