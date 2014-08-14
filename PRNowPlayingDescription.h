#import <Foundation/Foundation.h>

@class PRListDescription;


@interface PRNowPlayingDescription : NSObject
@property (readonly) NSArray *invalidItems;
@property (readonly) PRListDescription *currentList;
@property (readonly) PRItem *currentItem;
@property (readonly) int currentIndex;
@property (readonly) BOOL shuffle;
@property (readonly) int repeat;
@end
