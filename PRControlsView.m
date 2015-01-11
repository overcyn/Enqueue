#import "PRControlsView.h"
#import "PRGradientView.h"

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
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _playButton = [[NSButton alloc] init];
        [self addSubview:_playButton];
        
        _nextButton = [[NSButton alloc] init];
        [self addSubview:_nextButton];
        
        _previousButton = [[NSButton alloc] init];
        [self addSubview:_previousButton];
        
        _shuffleButton = [[NSButton alloc] init];
        [self addSubview:_shuffleButton];
        
        _repeatButton = [[NSButton alloc] init];
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

- (NSString *)titleString {
    return [_titleLabel stringValue];
}

- (void)setTitleString:(NSString *)value {
    [_titleLabel setStringValue:value];
}

#pragma mark - NSView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    CGRect b = [self bounds];
    CGFloat x = 30;
    CGFloat maxX = CGRectGetMaxX(b) - 30;
    {
        CGRect f = [_nextButton frame];
        f.size.width = 45;
        f.size.height = 45;
        f.origin.x = x;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        [_nextButton setFrame:f];
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
        CGRect f = [_previousButton frame];
        f.size.width = 45;
        f.size.height = 45;
        f.origin.x = x;
        f.origin.y = roundf(b.origin.y + (b.size.height - f.size.height)/2);
        [_previousButton setFrame:f];
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
        f.size.width = maxX - x;
        f.size.height = 25;
        f.origin.x = x;
        f.origin.y = b.origin.y + b.size.height - f.size.height;
        [_titleLabel setFrame:f];
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
