#import <Foundation/Foundation.h>
#import "PRLibrary.h"


@interface PRLastfmFile : NSObject {
    PRItemID *_item;
    NSDate *_startDate;
    NSDate *_playDate;
    NSTimeInterval _playTime;
    BOOL _playing;
}
- (id)initWithItem:(PRItemID *)item;
- (void)play;
- (void)pause;

@property (readonly) PRItemID *item;
@property (readonly) NSDate *startDate;
@property (readonly) NSTimeInterval playTime;
@end
