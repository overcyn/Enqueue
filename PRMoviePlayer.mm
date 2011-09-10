#import "PRMoviePlayer.h"
#import "PRUserDefaults.h"
#include <cmath>
#include <libkern/OSAtomic.h>
#include <SFBAudioEngine/AudioPlayer.h>
#include <SFBAudioEngine/AudioDecoder.h>

#define DSP_ENABLED 0
#define PLAYER (static_cast<AudioPlayer *>(player))

NSString * const PRIsPlayingDidChangeNotification = @"PRIsPlayingDidChangeNotification";
NSString * const PRMovieDidFinishNotification = @"PRMovieDidFinishNotification";

volatile static uint32_t sPlayerFlags = 0;

enum {
	ePlayerFlagRenderingStarted = 1 << 0,
	ePlayerFlagRenderingFinished = 1 << 1
};

static void decodingStarted(void *context, const AudioDecoder *decoder)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [(PRMoviePlayer *)context decodingStarted];
    [pool drain];
}

static void renderingStarted(void *context, const AudioDecoder *decoder)
{
    OSAtomicTestAndClearBarrier(7, &sPlayerFlags);
}

static void decodingFinished(void *context, const AudioDecoder *decoder)
{
    OSAtomicTestAndSetBarrier(7, &sPlayerFlags);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSNotification *notification = [NSNotification notificationWithName:PRMovieDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
                                                           withObject:notification 
                                                        waitUntilDone:FALSE];
    [pool drain];
}

static void renderingFinished(void *context, const AudioDecoder *decoder)
{
}


@implementation PRMoviePlayer

// ========================================
// Initialization
// ========================================

- (id)init
{
    if (!(self = [super init])) {return nil;}
    player = new AudioPlayer();
    PLAYER->EnableDigitalVolume(TRUE);
    PLAYER->EnableDigitalPreGain(TRUE);
    
    // Update the UI 5 times per second in all run loop modes (so menus, etc. don't stop updates)
    timer = [NSTimer timerWithTimeInterval:0.2 
                                    target:self 
                                  selector:@selector(update) 
                                  userInfo:nil 
                                   repeats:YES];
    
    // addTimer:forMode: will retain timer
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preGainDidChange:) name:PRPreGainDidChangeNotification object:nil];
    [self preGainDidChange:nil];
    [self setVolume:[self volume]];
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)openFileAndPlay:(NSString *)file
{
    AudioDecoder *decoder = AudioDecoder::CreateDecoderForURL(reinterpret_cast<CFURLRef>([NSURL URLWithString:file]));
    if(decoder == NULL) {
		return FALSE;
    }
    decoder->SetDecodingStartedCallback(decodingStarted, self);
    decoder->SetDecodingFinishedCallback(decodingFinished, self);
    decoder->SetRenderingStartedCallback(renderingStarted, self);
	decoder->SetRenderingFinishedCallback(renderingFinished, self);
    decoder->Open();
    if(ePlayerFlagRenderingStarted & sPlayerFlags) {
		OSAtomicTestAndClearBarrier(7 /* ePlayerFlagRenderingStarted */, &sPlayerFlags);
    } else {
        PLAYER->Stop();
    }
    PLAYER->ClearQueuedDecoders();
    if(!PLAYER->Enqueue(decoder)) {
        delete decoder;
        return FALSE;
    }
    [self setVolume:[self volume]];
    return TRUE;
}

- (void)pause
{
    if ([self isPlaying]) {
        if (self.transitionTimer && [self.transitionTimer isValid]) {
            [transitionTimer invalidate];
        }
        if (transitionState != PRPlayingTransitionState) {
            transitionVolume = 1;
        }
        transitionState = PRPausingTransitionState;
        PLAYER->SetDigitalVolume((pow(10, transitionVolume * [self volume]) - 1) / 9);
        self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                                target:self 
                                                              selector:@selector(transitionCallback:) 
                                                              userInfo:nil 
                                                               repeats:FALSE];
    }
    [self willChangeValueForKey:@"isPlaying"];
    [self didChangeValueForKey:@"isPlaying"];
}

- (void)playImmediately
{
    PLAYER->Play();
    [self setVolume:[self volume]];
    [self willChangeValueForKey:@"isPlaying"];
    [self didChangeValueForKey:@"isPlaying"];

}

- (void)play
{
    if (![self isPlaying]) {
        if (self.transitionTimer && [self.transitionTimer isValid]) {
            [transitionTimer invalidate];
        }
        if (transitionState != PRPausingTransitionState) {
            transitionVolume = 0;
        }
        transitionState = PRPlayingTransitionState;
        PLAYER->SetDigitalVolume((pow(10, transitionVolume * [self volume]) - 1) / 9);
        PLAYER->Play();
        self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                                target:self 
                                                              selector:@selector(transitionCallback:) 
                                                              userInfo:nil 
                                                               repeats:FALSE];
    }
    [self willChangeValueForKey:@"isPlaying"];
    [self didChangeValueForKey:@"isPlaying"];
}

- (void)transitionCallback:(NSTimer *)timer_
{
    switch (transitionState) {
        case PRNeitherTransitionState:
            break;
        case PRPlayingTransitionState:
            transitionVolume += 0.1;
            if (transitionVolume >= 1) {
                transitionVolume = 1;
                transitionState = PRNeitherTransitionState;
            } else {
                self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.02
                                                                        target:self 
                                                                      selector:@selector(transitionCallback:) 
                                                                      userInfo:nil 
                                                                       repeats:FALSE];
            }
            PLAYER->SetDigitalVolume((pow(10, transitionVolume * [self volume]) - 1) / 9);
            break;
        case PRPausingTransitionState:
            transitionVolume -= 0.1;
            if (transitionVolume <= 0) {
                transitionVolume = 0;
                transitionState = PRNeitherTransitionState;
                PLAYER->Pause();
            } else {
                self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.02
                                                                        target:self 
                                                                      selector:@selector(transitionCallback:) 
                                                                      userInfo:nil 
                                                                       repeats:FALSE];
            }
            PLAYER->SetDigitalVolume((pow(10, transitionVolume * [self volume]) - 1) / 9);
            break;
        default:
            break;
    }
}

- (void)stop
{
    PLAYER->Stop();
}

- (void)playPause
{
    if ([self isPlaying]) {
        [self pause];
    } else { 
        [self play];
    }
}

- (void)seekForward
{
	PLAYER->SeekForward();
}

- (void)seekBackward
{
	PLAYER->SeekBackward();
}

// ========================================
// Accessors
// ========================================

@synthesize transitionTimer;

- (BOOL)isPlaying
{
    if (transitionState == PRPausingTransitionState) {
        return FALSE;
    }
    return PLAYER->IsPlaying();
}

- (BOOL)isStopped
{
    return !sPlayerFlags;
}

- (float)volume
{
    double volume;
    volume = [[PRUserDefaults userDefaults] volume];
    volume = log10(volume * 9 + 1);
    return volume;
}

- (void)setVolume:(float)volume
{
    volume = (pow(10, volume) - 1) / 9;
    [[PRUserDefaults userDefaults] setVolume:volume];
    PLAYER->SetDigitalVolume(volume);
}

- (void)increaseVolume
{
    float volume = [self volume] + 0.1;
    if (volume > 1.0) {
        volume = 1.0;
    }
    [self setVolume:volume];
}

- (void)decreaseVolume
{
    float volume = [self volume] - 0.1;
    if (volume < 0.0) {
        volume = 0.0;
    }
    [self setVolume:volume];
}

- (long)currentTime
{
    CFTimeInterval timeInterval;
    PLAYER->GetCurrentTime(timeInterval);
    return timeInterval * 1000;
}

- (void)setCurrentTime:(long)currentTime
{
    PLAYER->SeekToTime(currentTime / 1000);
}

- (long)duration
{
    CFTimeInterval duration;
    PLAYER->GetTotalTime(duration);
    return duration * 1000;
}

// ========================================
// Update
// ========================================

- (void)decodingStarted
{
    PLAYER->Play();
}

- (void)update
{
    [self willChangeValueForKey:@"currentTime"];
    [self didChangeValueForKey:@"currentTime"];
    [self willChangeValueForKey:@"duration"];
    [self didChangeValueForKey:@"duration"];
}

- (void)postMovieDidFinishNotification
{
    [self willChangeValueForKey:@"isPlaying"];
    [self didChangeValueForKey:@"isPlaying"];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRMovieDidFinishNotification object:self];
}

- (void)preGainDidChange:(NSNotification *)notification
{
    float preGain = [[PRUserDefaults userDefaults] preGain];
    PLAYER->SetDigitalPreGain(preGain);
}

@end