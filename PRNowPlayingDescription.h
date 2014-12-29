#import <Foundation/Foundation.h>


@interface PRNowPlayingDescription : NSObject
@property (readonly) NSArray *invalidItems;
@property (readonly) PRList *currentList;
@property (readonly) PRItem *currentItem;
@property (readonly) int currentIndex; // 0 based
@property (readonly) BOOL shuffle;
@property (readonly) int repeat;
@end
