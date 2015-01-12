#import "PRControlsViewController.h"
#import "PRAction.h"
#import "PRBridge.h"
#import "PRConnection.h"
#import "PRControlsView.h"
#import "PRCore.h"
#import "PRItemDescription.h"
#import "PRNowPlayingController.h"
#import "PRTimeFormatter.h"
#import "PRNowPlayingDescription.h"

@implementation PRControlsViewController {
    PRBridge *_bridge;
    PRControlsView *_view;
    PRNowPlayingDescription *_player;
    PRMoviePlayerDescription *_movie;
    PRItemDescription *_item;
    PRTimeFormatter *_formatter;
}

- (id)initWithBridge:(PRBridge *)bridge {
    if ((self = [super init])) {
        _bridge = bridge;
        _formatter = [[PRTimeFormatter alloc] init];
        [[NSNotificationCenter defaultCenter] observeBackendChanged:self sel:@selector(_backendDidChange:)];
    }
    return self;
}

- (void)loadView {
    _view = [[PRControlsView alloc] init];
    [self setView:_view];
    
    [[_view playButton] setTarget:self];
    [[_view playButton] setAction:@selector(_playButtonAction:)];
    [[_view nextButton] setTarget:self];
    [[_view nextButton] setAction:@selector(_nextButtonAction:)];
    [[_view previousButton] setTarget:self];
    [[_view previousButton] setAction:@selector(_previousButtonAction:)];
    [[_view volumeSlider] setTarget:self];
    [[_view volumeSlider] setAction:@selector(_volumeAction:)];
    [[_view progressSlider] setTarget:self];
    [[_view progressSlider] setAction:@selector(_progressAction:)];
    [[_view repeatButton] setTarget:self];
    [[_view repeatButton] setAction:@selector(_repeatAction:)];
    [[_view shuffleButton] setTarget:self];
    [[_view shuffleButton] setAction:@selector(_shuffleAction:)];
    [self _reloadData];
}

#pragma mark - Action

- (void)_playButtonAction:(id)sender {
    [_bridge performTask:PRPlayPauseTask()];
}

- (void)_nextButtonAction:(id)sender {
    [_bridge performTask:PRPlayNextTask()];
}

- (void)_previousButtonAction:(id)sender {
    [_bridge performTask:PRPlayPreviousTask()];
}

- (void)_volumeAction:(id)sender {
    [_bridge performTask:PRSetVolumeTask([[_view volumeSlider] floatValue])];
}

- (void)_progressAction:(id)sender {
    [_bridge performTask:PRSetTimeTask([[_view progressSlider] integerValue])];
}

- (void)_shuffleAction:(id)sender {
    [_bridge performTask:PRToggleShuffleTask()];
}

- (void)_repeatAction:(id)sender {
    [_bridge performTask:PRToggleRepeatTask()];
}

#pragma mark - Notifications

- (void)_backendDidChange:(NSNotification *)note {
    for (NSObject *i in [[note userInfo][@"changeset"] changes]) {
        if ([i isKindOfClass:[PRNowPlayingChange class]]) {
            [self _reloadData];
        } else if ([i isKindOfClass:[PRMovieChange class]]) {
            [self _reloadMovie];
        }
    }
}

#pragma mark - Internal

- (void)_reloadData {
    __block PRNowPlayingDescription *player = nil;
    __block PRItemDescription *item = nil;
    [_bridge performTaskSync:^(PRCore *core){
        player = [[core now] description];
        if ([player currentItem]) {
            [[[core conn] library] zItemDescriptionForItem:[player currentItem] out:&item];
        }
    }];
    _player = player;
    _item = item;
    
    [_view setTitleString:_item ? [NSString stringWithFormat:@"%@ - %@ - %@", [_item title], [_item artist], [_item album]] : @""];
    [_view setRepeat:[_player repeat]];
    [_view setShuffle:[_player shuffle]];
    
    [self _reloadMovie];
}

- (void)_reloadMovie {
    __block PRMoviePlayerDescription *movDescription = nil;
    [_bridge performTaskSync:^(PRCore *core){
        movDescription = [[core now] movDescription];
    }];
    _movie = movDescription;
    
    [[_view volumeSlider] setFloatValue:[_movie volume]];
    [[_view progressSlider] setMaxValue:[_movie duration]];
    [[_view progressSlider] setIntegerValue:[_movie currentTime]];
    [_view setIsPlaying:[_movie isPlaying]];
    
    NSString *timeStr = [_formatter stringForObjectValue:@([_movie currentTime])];
    NSString *durationStr = [_formatter stringForObjectValue:@([_movie duration])];
    [_view setSubtitleString:(_item && _movie) ? [NSString stringWithFormat:@"%@ / %@", timeStr, durationStr] : @""];
}

@end
