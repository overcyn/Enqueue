#import <Foundation/Foundation.h>
#import "PRLibrary.h"


@interface PRLastfmFile : NSObject
{
    PRFile _file;
    NSDate *_startDate;
    NSDate *_playDate;
    NSTimeInterval _playTime;
    BOOL _playing;
}

- (id)initWithFile:(PRFile)file;
- (void)play;
- (void)pause;

@property (readonly) PRFile file;
@property (readonly) NSDate *startDate;
@property (readonly) NSTimeInterval playTime;

@end
