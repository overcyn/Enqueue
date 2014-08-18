#import <Foundation/Foundation.h>


@interface PRNowPlayingDescription : NSObject
@property (readonly) NSArray *invalidItems;
@property (readonly) PRList *currentList;
@property (readonly) PRItem *currentItem;
@property (readonly) int currentIndex;
@property (readonly) BOOL shuffle;
@property (readonly) int repeat;
@end
