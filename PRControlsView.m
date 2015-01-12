#import "PRControlsView.h"
#import "PRGradientView.h"

#define SUBTITLE_WIDTH          (100)

@implementation PRControlsView {
    NSButton *_playButton;
    NSButton *_nextButton;
    NSButton *_previousButton;
    NSButton *_shuffleButton;
    NSButton *_repeatButton;
    NSSlider *_volumeSlider;
    NSSlider *_progressSlider;
    PRGradientView *_containerView;
    NSTextField *_titleLabel;
    NSTextField *_subtitleLabel;
    BOOL _isPlaying;
    BOOL _shuffle;
    NSInteger _repeat;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _playButton = [[NSButton alloc] init];
        [_playButton setTitle:@"Play"];
        [self addSubview:_playButton];
        
        _nextButton = [[NSButton alloc] init];
        [_nextButton setTitle:@"Next"];
        [self addSubview:_nextButton];
        
        _previousButton = [[NSButton alloc] init];
        [_previousButton setTitle:@"Previous"];
        [self addSubview:_previousButton];
        
        _shuffleButton = [[NSButton alloc] init];
        [_shuffleButton setTitle:@"sff off"];
        [self addSubview:_shuffleButton];
        
        _repeatButton = [[NSButton alloc] init];
        [_repeatButton setTitle:@"rep off"];
        [self addSubview:_repeatButton];
        
        _volumeSlider = [[NSSlider alloc] init];
        [_volumeSlider setMinValue:0];
        [_volumeSlider setMaxValue:1];
        [self addSubview:_volumeSlider];
        
        _containerView = [[PRGradientView alloc] init];
        [_containerView setColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]];
        [self addSubview:_containerView];
        
        _progressSlider = [[NSSlider alloc] init];
        [_progressSlider setMinValue:0];
        [_progressSlider setMaxValue:1];
        [self addSubview:_progressSlider];
        
        _titleLabel = [[NSTextField alloc] init];
        [_titleLabel setBezeled:NO];
        [_titleLabel setDrawsBackground:NO];
        [_titleLabel setEditable:NO];
        [_titleLabel setSelectable:NO];
        [[_titleLabel cell] setUsesSingleLineMode:YES];
        [self addSubview:_titleLabel];
        
        _subtitleLabel = [[NSTextField alloc] init];
        [_subtitleLabel setBezeled:NO];
        [_subtitleLabel setDrawsBackground:NO];
        [_subtitleLabel setEditable:NO];
        [_subtitleLabel setSelectable:NO];
        [_subtitleLabel setAlignment:NSRightTextAlignment];
        [[_subtitleLabel cell] setUsesSingleLineMode:YES];
        [self addSubview:_subtitleLabel];
    }
    return self;
}

#pragma mark - API

@synthesize playButton = _playButton;
@synthesize nextButton = _nextButton;
@synthesize previousButton = _previousButton;
@synthesize shuffleButton = _shuffleButton;
@synthesize repeatButton = _repeatButton;
@synthesize volumeSlider = _volumeSlider;
@synthesize progressSlider = _progressSlider;
@synthesize isPlaying = _isPlaying;
@synthesize shuffle = _shuffle;
@synthesize repeat = _repeat;

- (NSString *)titleString {
    return [_titleLabel stringValue];
}

- (void)setTitleString:(NSString *)value {
    [_titleLabel setStringValue:value];
}

- (NSString *)subtitleString {
    return [_subtitleLabel stringValue];
}

- (void)setSubtitleString:(NSString *)value {
    [_subtitleLabel setStringValue:value];
}

- (void)setIsPlaying:(BOOL)value {
    if (_isPlaying != value) {
        _isPlaying = value;
        [_playButton setTitle:_isPlaying ? @"Pause" : @"Play"];
    }
}

- (void)setShuffle:(BOOL)value {
    if (_shuffle != value) {
        _shuffle = value;
        [_shuffleButton setTitle:_shuffle ? @"sff on" : @"sff off"];
    }
}

- (void)setRepeat:(NSInteger)value {
    if (_repeat != value) {
        _repeat = value;
        [_repeatButton setTitle:_repeat ? @"rep on" : @"rep off"];
    }
}

#pragma mark - NSView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    CGRect b = [self bounds];
    CGFloat x = 30;
    CGFloat maxX = CGRectGetMaxX(b) - 30;
    {
        CGRect f = [_previousButton frame];
        f.size.width = 45;
        f.size.height = 45;
        f.origin.x = x;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        [_previousButton setFrame:f];
        x = CGRectGetMaxX(f) + 10;
    }
    {
        CGRect f = [_playButton frame];
        f.size.width = 45;
        f.size.height = 45;
        f.origin.x = x;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        [_playButton setFrame:f];
        x = CGRectGetMaxX(f) + 10;
    }
    {
        CGRect f = [_nextButton frame];
        f.size.width = 45;
        f.size.height = 45;
        f.origin.x = x;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        [_nextButton setFrame:f];
        x = CGRectGetMaxX(f) + 30;
    }
    {
        CGRect f = [_volumeSlider frame];
        f.size.width = 100;
        f.size.height = 50;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        f.origin.x = x;
        [_volumeSlider setFrame:f];
        x = CGRectGetMaxX(f) + 30;
    }
    {
        CGRect f = [_shuffleButton frame];
        f.size.width = 45;
        f.size.height = 45;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        f.origin.x = maxX - f.size.width;
        [_shuffleButton setFrame:f];
        maxX = CGRectGetMinX(f) - 10;
    }
    {
        CGRect f = [_repeatButton frame];
        f.size.width = 45;
        f.size.height = 45;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        f.origin.x = maxX - f.size.width;
        [_repeatButton setFrame:f];
        maxX = CGRectGetMinX(f) - 10;
    }
    {
        CGRect f = [_containerView frame];
        f.size.width = maxX - x;
        f.size.height = b.size.height;
        f.origin.y = b.origin.y;
        f.origin.x = x;
        [_containerView setFrame:f];
    }
    {
        CGRect f = [_titleLabel frame];
        f.size.width = maxX - x - SUBTITLE_WIDTH;
        f.size.height = 25;
        f.origin.x = x;
        f.origin.y = b.origin.y + b.size.height - f.size.height;
        [_titleLabel setFrame:f];
    }
    {
        CGRect f = [_subtitleLabel frame];
        f.size.width = SUBTITLE_WIDTH;
        f.size.height = 25;
        f.origin.x = maxX - SUBTITLE_WIDTH;
        f.origin.y = b.origin.y + b.size.height - f.size.height;
        [_subtitleLabel setFrame:f];
    }
    {
        CGRect f = [_progressSlider frame];
        f.size.width = maxX - x;
        f.size.height = 25;
        f.origin.y = b.origin.y + 5;
        f.origin.x = x;
        [_progressSlider setFrame:f];
    }
}

@end
