#import <Foundation/Foundation.h>
#import "PRLibrary.h"


@interface PRLastfmFile : NSObject {
    PRItem *_item;
    NSDate *_startDate;
    NSDate *_playDate;
    NSTimeInterval _playTime;
    BOOL _playing;
}
- (id)initWithItem:(PRItem *)item;
- (void)play;
- (void)pause;

@property (readonly) PRItem *item;
@property (readonly) NSDate *startDate;
@property (readonly) NSTimeInterval playTime;
@end
