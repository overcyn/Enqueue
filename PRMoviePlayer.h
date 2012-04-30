#import <Cocoa/Cocoa.h>
#import <AudioUnit/AudioUnit.h>
@class PRMovie;


enum {
    PRNeitherTransitionState,
    PRPlayingTransitionState,
    PRPausingTransitionState,
};
typedef enum {
    PRMovieQueueEmpty,
    PRMovieQueueWaiting,
    PRMovieQueuePlayed,
} PRMovieQueueState;


@interface PRMoviePlayer : NSObject {
    void *player;
    AudioUnit _equalizer;
    
    float transitionVolume;
    int transitionState;
    NSTimer *_transitionTimer; // should only be accessed through accessor
    
    NSTimer	*_UIUpdateTimer;
    
    PRMovieQueueState _queueState; // should only be accessed through accessor
}
/* Playback */
- (BOOL)play:(NSString *)file;
- (BOOL)queue:(NSString *)file;
- (BOOL)playIfNotQueued:(NSString *)file;

- (void)stop;
- (void)unpause;
- (void)pause;
- (void)seekForward;
- (void)seekBackward;

/* Accessors */
@property (readonly) BOOL isPlaying;
@property (readwrite) float volume;
@property (readwrite) long currentTime;
@property (readonly) long duration;
@property (readwrite) BOOL hogOutput;
- (void)increaseVolume;
- (void)decreaseVolume;
@end

