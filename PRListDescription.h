#import <Foundation/Foundation.h>

@class PRDb;


@interface PRListDescription : NSObject
- (id)initWithList:(PRList *)list database:(PRDb *)db;
@property (nonatomic, readonly) PRList *list;
@property (nonatomic, readonly) NSInteger count;
- (PRItem *)itemAtIndex:(NSInteger)index; // Zero based
- (PRListItem *)listItemAtIndex:(NSInteger)index;
@end


@interface PRNowPlayingListDescription : PRListDescription
@property (nonatomic, readonly) NSArray *albumCounts;
- (NSInteger)indexForIndexPath:(NSIndexPath *)index; // One based
- (NSIndexPath *)indexPathForIndex:(NSInteger)index;
- (NSRange)rangeForIndexPath:(NSIndexPath *)index;
@end