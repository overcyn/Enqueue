/*
     AudioPlayer states (this ignores queued decoders):
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

extern NSString * const PRDeviceKeyName;
extern NSString * const PRDeviceKeyManufacturer;
extern NSString * const PRDeviceKeyUID;


@interface PRMoviePlayer : NSObject {
    void *_player;
    AudioUnit _equalizer;
    NSTimer	*_UIUpdateTimer;
    NSString *_lastQueued;
    
    float _transitionVolume;
    int _transitionState;
    NSTimer *_transitionTimer;
}
/* Accessors */
@property (readonly) BOOL isPlaying;
@property (readwrite) float volume;
@property (readwrite) long currentTime;
@property (readonly) long duration;
- (void)increaseVolume;
- (void)decreaseVolume;

/* Playback */
- (BOOL)play:(NSString *)file;
- (BOOL)queue:(NSString *)file;
- (BOOL)playIfNotQueued:(NSString *)file;
- (void)stop;
- (void)pauseUnpause;
- (void)seekForward;
- (void)seekBackward;

/* Device */
@property (weak, readonly) NSArray *devices;
@property (readwrite, strong) NSString *currentDevice;

/* HogOutput */
@property (readwrite) BOOL hogOutput;
@end
