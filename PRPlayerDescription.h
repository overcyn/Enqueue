#import <Foundation/Foundation.h>
#import "PRPlaylists.h"

@interface PRPlayerDescription : NSObject
@property (readonly) NSArray *invalidItems;
@property (readonly) PRListID *currentList;
@property (readonly) PRItemID *currentItem;
@property (readonly) NSInteger currentIndex; // 0 based
@property (readonly) BOOL shuffle;
@property (readonly) NSInteger repeat;
@end

@interface PRMovieDescription : NSObject
@property (readonly) BOOL isPlaying;
@property (readonly) CGFloat volume;
@property (readonly) long currentTime;
@property (readonly) long duration;
@end
