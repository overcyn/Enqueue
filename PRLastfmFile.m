#import "PRLastfmFile.h"

@implementation PRLastfmFile

- (id)initWithItem:(PRItem *)item {
    if (!(self = [super init])) {return nil;}
    _item = item;
    _startDate = nil;
    _playDate = nil;
    _playTime = 0;
    _playing = NO;
    return self;
}


- (void)play {
    if (!_startDate) {
        _startDate = [NSDate date];
    }
    if (_playing) {
        return;
    }
    _playDate = [NSDate date];
    
    _playing = YES;
}

- (void)pause {
    if (!_playing) {
        return;
    }
    _playTime += [[NSDate date] timeIntervalSinceDate:_playDate];
    _playing = NO;
}

@synthesize item = _item;
@synthesize startDate = _startDate;
@dynamic playTime;

- (NSTimeInterval)playTime {
    NSTimeInterval temp = 0;
    if (_playDate) {
        temp = [[NSDate date] timeIntervalSinceDate:_playDate];
    }
    return _playTime += temp;
}

@end
