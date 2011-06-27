#import <Cocoa/Cocoa.h>

@class PRMovie;

// ========================================
// Constants

extern NSString * const PRIsPlayingDidChangeNotification;
extern NSString * const PRMovieDidFinishNotification;

enum {
    PRNeitherTransitionState,
    PRPlayingTransitionState,
    PRPausingTransitionState,
};

// ========================================
// PRMoviePlayer
// ========================================
@interface PRMoviePlayer : NSObject {
    void *player; // An instance of AudioPlayer
	NSTimer	*timer; // User interface update timer
    
    float transitionVolume;
    int transitionState;
    NSTimer *transitionTimer;
}

// ========================================
// Action

- (BOOL)openFileAndPlay:(NSString *)file;
- (void)playImmediately;
- (void)play;
- (void)pause;
- (void)stop;
- (void)playPause;
- (void)seekForward;
- (void)seekBackward;

// ========================================
// Update

- (void)preGainDidChange:(NSNotification *)notification;

// ========================================
// Accessors

@property (readwrite, retain) NSTimer *transitionTimer;

- (BOOL)isPlaying;
- (BOOL)isStopped;
- (float)volume;
- (void)setVolume:(float)newVolume;
- (void)increaseVolume;
- (void)decreaseVolume;
- (long)currentTime;
- (void)setCurrentTime:(long)currentTime;
- (long)duration;
 
@end


@interface PRMoviePlayer ()

- (void)update;
- (void)postMovieDidFinishNotification;

@end