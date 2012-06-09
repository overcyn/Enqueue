/*
     AudioPlayer states:
     ... 
        eStopped
     DecodingStarted
        ePending
     RenderingStarted
        ePaused, ePlaying
     DecodingFinished
        ePlaying, ePaused
     RenderingFinished
        eStopped
     ...
 
    Proof that _lastQueued is always accurate in the ePending state. AudioPlayer will only be in the ePending in 2 situations.
    1. Immediately after Play() is called
    2. A song is Enqueue()'d and the last song finishes.
    In situation 1, _lastQueued is always cleared before Play()
    In situation 2, Enqueue()'d is only called from queue: which also sets _lastQueued
 
    Currently [PRMoviePlayer update] gets called twice because as soon as you queue up the next song DecodingStarted 
    gets called which clears the flags and update gets called again.
*/
#import <Cocoa/Cocoa.h>
#import <AudioUnit/AudioUnit.h>


enum {
    PRNeitherTransitionState,
    PRPlayingTransitionState,
    PRPausingTransitionState,
};


@interface PRMoviePlayer : NSObject {
    void *player;
    AudioUnit _equalizer;
    NSTimer	*_UIUpdateTimer;
    NSString *_lastQueued;
    
    float transitionVolume;
    int transitionState;
    NSTimer *_transitionTimer;
}
/* Playback */
- (BOOL)play:(NSString *)file;
- (BOOL)queue:(NSString *)file;
- (BOOL)playIfNotQueued:(NSString *)file;
- (void)stop;
- (void)pauseUnpause;
- (void)seekForward;
- (void)seekBackward;

/* Accessors */
@property (readonly) BOOL isPlaying;
@property (readwrite) float volume;
@property (readwrite) BOOL hogOutput;
@property (readwrite) long currentTime;
@property (readonly) long duration;
@property (readonly) NSArray *devices;
@property (readwrite, copy) NSString *currentDevice;
- (void)increaseVolume;
- (void)decreaseVolume;
@end
