#import "PRControlsViewController.h"
#import "NSNotificationCenter+Extensions.h"
#import "PRPlaylists.h"
#import "PRAction.h"
#import "PRBridge_Front.h"
#import "PRConnection.h"
#import "PRControlsView.h"
#import "PRCore.h"
#import "PRItem.h"
#import "PRPlayer.h"
#import "PRPlayerState.h"
#import "PRTimeFormatter.h"

@implementation PRControlsViewController {
    PRBridge *_bridge;
    PRControlsView *_view;
    PRPlayerState *_playerState;
    PRMovieState *_movieState;
    PRItem *_item;
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
    __block PRPlayerState *player = nil;
    __block PRItem *item = nil;
    [_bridge performTaskSync:^(PRCore *core){
        player = [[core now] playerState];
        if ([player currentItem]) {
            [[[core conn] library] zItemDescriptionForItem:[player currentItem] out:&item];
        }
    }];
    _playerState = player;
    _item = item;
    
    [_view setTitleString:_item ? [NSString stringWithFormat:@"%@ - %@ - %@", [_item title], [_item artist], [_item album]] : @""];
    [_view setRepeat:[_playerState repeat]];
    [_view setShuffle:[_playerState shuffle]];
    
    [self _reloadMovie];
}

- (void)_reloadMovie {
    __block PRMovieState *movDescription = nil;
    [_bridge performTaskSync:^(PRCore *core){
        movDescription = [[core now] movieState];
    }];
    _movieState = movDescription;
    
    [[_view volumeSlider] setFloatValue:[_movieState volume]];
    [[_view progressSlider] setMaxValue:[_movieState duration]];
    [[_view progressSlider] setIntegerValue:[_movieState currentTime]];
    [_view setIsPlaying:[_movieState isPlaying]];
    
    NSString *timeStr = [_formatter stringForObjectValue:@([_movieState currentTime])];
    NSString *durationStr = [_formatter stringForObjectValue:@([_movieState duration])];
    [_view setSubtitleString:(_item && _movieState) ? [NSString stringWithFormat:@"%@ / %@", timeStr, durationStr] : @""];
}

@end
