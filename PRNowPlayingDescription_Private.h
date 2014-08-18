#import "PRNowPlayingDescription.h"


@interface PRNowPlayingDescription ()
@property (readwrite) NSArray *invalidItems;
@property (readwrite) PRList *currentList;
@property (readwrite) PRItem *currentItem;
@property (readwrite) int currentIndex;
@property (readwrite) BOOL shuffle;
@property (readwrite) int repeat;
@end
