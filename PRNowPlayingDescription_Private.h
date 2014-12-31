#import "PRNowPlayingDescription.h"

@interface PRNowPlayingDescription ()
@property (readwrite) NSArray *invalidItems;
@property (readwrite) PRList *currentList;
@property (readwrite) PRItem *currentItem;
@property (readwrite) NSInteger currentIndex;
@property (readwrite) BOOL shuffle;
@property (readwrite) NSInteger repeat;
@end

@interface PRMoviePlayerDescription ()
@property (readwrite) BOOL isPlaying;
@property (readwrite) CGFloat volume;
@property (readwrite) long currentTime;
@property (readwrite) long duration;
@end
