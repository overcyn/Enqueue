#import "PRLastfmFile.h"

@implementation PRLastfmFile

- (id)initWithItem:(PRItem *)item {
    if (!(self = [super init])) {return nil;}
    _item = [item retain];
    _startDate = nil;
    _playDate = nil;
    _playTime = 0;
    _playing = FALSE;
    return self;
}

- (void)dealloc {
    [_item release];
    [_startDate release];
    [_playDate release];
    [super dealloc];
}

- (void)play {
    if (!_startDate) {
        _startDate = [[NSDate date] retain];
    }
    if (_playing) {
        return;
    }
    [_playDate release];
    _playDate = [[NSDate date] retain];
    
    _playing = TRUE;
}

- (void)pause {
    if (!_playing) {
        return;
    }
    _playTime += [[NSDate date] timeIntervalSinceDate:_playDate];
    _playing = FALSE;
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
