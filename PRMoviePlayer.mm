#import "PRMoviePlayer.h"
#import "PRUserDefaults.h"
#import "NSNotificationCenter+Extensions.h"
#import <AudioUnit/AudioUnit.h>
#include <cmath>
#include <libkern/OSAtomic.h>
#include <SFBAudioEngine/AudioPlayer.h>
#include <SFBAudioEngine/AudioDecoder.h>
#import "CAAUParameter.h"
#import "AUParamInfo.h"
#import "PREQ.h"


#define DSP_ENABLED 0
#define PLAYER (static_cast<AudioPlayer *>(player))
volatile static uint32_t sPlayerFlags = 0;


static void decodingStarted(void *context, const AudioDecoder *decoder);
static void renderingStarted(void *context, const AudioDecoder *decoder);
static void decodingFinished(void *context, const AudioDecoder *decoder);
static void renderingFinished(void *context, const AudioDecoder *decoder);


@interface PRMoviePlayer ()
/* Playback */
- (void)transitionCallback:(NSTimer *)timer_;

/* Accessors */
@property (readwrite, retain) NSTimer *transitionTimer;
@property (readwrite) PRMovieQueueState queueState;
@property (readonly) void *player;

/* Update */
- (void)preGainDidChange:(NSNotification *)notification;
- (void)EQChanged:(NSNotification *)note;
- (void)update;
@end


@implementation PRMoviePlayer

// ========================================
// Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    player = new AudioPlayer();
    
    // Update the UI 5 times per second in all run loop modes (so menus, etc. don't stop updates)
    timer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(update) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
//    BOOL err = PLAYER->AddEffect(kAudioUnitSubType_GraphicEQ, kAudioUnitManufacturer_Apple, 0, 0, &_au);
//    if (!err) {
//        NSLog(@"EQ Fail");
//    }
//    
//    OSStatus status = AudioUnitInitialize(_au);
//    if (status != 0) {
//        NSLog(@"Init:%d",(int)status);
//    }
//        
//    status = AudioUnitSetParameter(_au, kGraphicEQParam_NumberOfBands, kAudioUnitScope_Global, 0, 0, 0);
//    if (status != 0) {
//        NSLog(@"status:%d",(int)status);
//    }
    
//    // Public util
//    AUParamInfo info(_au, FALSE, FALSE); 
//    for(int i = 0; i < info.NumParams(); i++) {
//        AudioUnitParameterID paramID = info.ParamID(i);
//        const CAAUParameter *param = info.GetParamInfo(paramID);
//        
//        NSLog(@"param: %d",(int)paramID);
//        if (param) {
//            NSLog(@"name:%@",(NSString *)param->GetName());
//            NSLog(@"value:%f",param->GetValue());
//            AudioUnitParameterInfo paramInfo = param->ParamInfo();
//            NSLog(@"min:%f max:%f default:%f", paramInfo.minValue, paramInfo.maxValue, paramInfo.defaultValue);
//        }
//    }
    
    [[NSNotificationCenter defaultCenter] observePreGainChanged:self sel:@selector(preGainDidChange:)];
    [[NSNotificationCenter defaultCenter] observeEQChanged:self sel:@selector(EQChanged:)];
    [self preGainDidChange:nil];
    [self EQChanged:nil];
    [self setVolume:[self volume]];
    [self setQueueState:PRMovieQueueEmpty];
    
    PLAYER->SetRingBufferCapacity(32768*4);
    PLAYER->SetRingBufferWriteChunkSize(4096);
    
	return self;
}

- (void)dealloc {
    [timer invalidate];
    [self.transitionTimer invalidate];
    
    delete PLAYER;
    [timer release];
    [_transitionTimer release];
    [super dealloc];
}

// ========================================
// Playback

- (BOOL)play:(NSString *)file {
    // clear queue & stop
    [self setQueueState:PRMovieQueueEmpty];
    PLAYER->Pause();
    PLAYER->Stop();
    PLAYER->ClearQueuedDecoders();
    
    // invalidate transition timer and reset volume
    if ([self transitionTimer]) {
        [[self transitionTimer] invalidate];
        [self setTransitionTimer:nil];
        transitionState = PRNeitherTransitionState;
    }
    [self setVolume:[self volume]];
    
//    NSLog(@"capacity:%d, minchunksize:%d",PLAYER->GetRingBufferCapacity(), PLAYER->GetRingBufferWriteChunkSize());
    
    AudioDecoder *decoder = AudioDecoder::CreateDecoderForURL(reinterpret_cast<CFURLRef>([NSURL URLWithString:file]));
    if (!decoder) {
		return FALSE;
    }
    decoder->SetDecodingStartedCallback(decodingStarted, self);
    decoder->SetDecodingFinishedCallback(decodingFinished, self);
    decoder->SetRenderingStartedCallback(renderingStarted, self);
	decoder->SetRenderingFinishedCallback(renderingFinished, self);
    if (!decoder->Open() || !PLAYER->Enqueue(decoder)) {
        delete decoder;
        return FALSE;
    }
    return TRUE;
}

- (BOOL)queue:(NSString *)file {
    if ([self queueState] == PRMovieQueueWaiting || [self queueState] == PRMovieQueuePlayed) {
        return FALSE;
    }
    [self setQueueState:PRMovieQueueWaiting];
    
    // clear queue
    PLAYER->ClearQueuedDecoders();
    
    AudioDecoder *decoder = AudioDecoder::CreateDecoderForURL(reinterpret_cast<CFURLRef>([NSURL URLWithString:file]));
    if (!decoder) {
		return FALSE;
    }
    decoder->SetDecodingStartedCallback(decodingStarted, self);
    decoder->SetDecodingFinishedCallback(decodingFinished, self);
    decoder->SetRenderingStartedCallback(renderingStarted, self);
	decoder->SetRenderingFinishedCallback(renderingFinished, self);
    if (!decoder->Open() || !PLAYER->Enqueue(decoder)) {
        delete decoder;
        return FALSE;
    }
    return TRUE;
}

- (BOOL)playIfNotQueued:(NSString *)file {
    BOOL success = FALSE;
    int queueState = [self queueState];
    [self setQueueState:PRMovieQueueEmpty];
    if (queueState == PRMovieQueueEmpty || queueState == PRMovieQueueWaiting) {
        success = [self play:file];
    } else if (queueState == PRMovieQueuePlayed) {
        NSURL *URL = (NSURL *)PLAYER->GetPlayingURL();
        if (!URL || ![[URL absoluteString] isEqualToString:file]) {
            success = [self play:file];
        } else {
            success = TRUE;
        }
    }
    return success;
}

- (void)stop {
    PLAYER->Stop();
}

- (void)pause {
    if ([self isPlaying]) {
        if (self.transitionTimer && [self.transitionTimer isValid]) {
            [self.transitionTimer invalidate];
        }
        if (transitionState != PRPlayingTransitionState) {
            transitionVolume = 1;
        }
        transitionState = PRPausingTransitionState;
        PLAYER->SetVolume(transitionVolume * [self volume]);
        self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.025
                                                                target:self 
                                                              selector:@selector(transitionCallback:) 
                                                              userInfo:nil 
                                                               repeats:FALSE];
    }
    [self willChangeValueForKey:@"isPlaying"];
    [self didChangeValueForKey:@"isPlaying"];
    [[NSNotificationCenter defaultCenter] postPlayingChanged];
}

- (void)unpause {
    if (![self isPlaying]) {
        if (self.transitionTimer && [self.transitionTimer isValid]) {
            [self.transitionTimer invalidate];
        }
        if (transitionState != PRPausingTransitionState) {
            transitionVolume = 0;
        }
        transitionState = PRPlayingTransitionState;
        PLAYER->SetVolume(transitionVolume * [self volume]);
        PLAYER->Play();
        self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.025
                                                                target:self 
                                                              selector:@selector(transitionCallback:) 
                                                              userInfo:nil 
                                                               repeats:FALSE];
    }
    [self willChangeValueForKey:@"isPlaying"];
    [self didChangeValueForKey:@"isPlaying"];
    [[NSNotificationCenter defaultCenter] postPlayingChanged];
}

- (void)seekForward {
	PLAYER->SeekForward();
}

- (void)seekBackward {
	PLAYER->SeekBackward();
}

// ========================================
// Playback Private

- (void)transitionCallback:(NSTimer *)timer_ {
    switch (transitionState) {
        case PRNeitherTransitionState:
            break;
        case PRPlayingTransitionState:
            transitionVolume += 0.1;
            if (transitionVolume >= 1) {
                transitionVolume = 1;
                transitionState = PRNeitherTransitionState;
            } else {
                self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.025
                                                                        target:self 
                                                                      selector:@selector(transitionCallback:) 
                                                                      userInfo:nil 
                                                                       repeats:FALSE];
            }
            PLAYER->SetVolume(transitionVolume * [self volume]);
            break;
        case PRPausingTransitionState:
            transitionVolume -= 0.1;
            if (transitionVolume <= 0) {
                transitionVolume = 0;
                transitionState = PRNeitherTransitionState;
                PLAYER->Pause();
            } else {
                self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:0.025
                                                                        target:self 
                                                                      selector:@selector(transitionCallback:) 
                                                                      userInfo:nil 
                                                                       repeats:FALSE];
            }
            PLAYER->SetVolume(transitionVolume * [self volume]);
            break;
        default:
            break;
    }
}

// ========================================
// Accessors

- (BOOL)isPlaying {
    if (transitionState == PRPausingTransitionState) {
        return FALSE;
    } else if (transitionState == PRPlayingTransitionState) {
        return TRUE;
    }
    return PLAYER->IsPlaying();
}

- (float)volume {
    return [[PRUserDefaults userDefaults] volume];
}

- (void)setVolume:(float)volume {
    [[PRUserDefaults userDefaults] setVolume:volume];
    PLAYER->SetVolume(volume);
    [[NSNotificationCenter defaultCenter] postVolumeChanged];
}

- (void)increaseVolume {
    float volume = [self volume] + 0.1;
    if (volume > 1.0) {
        volume = 1.0;
    }
    [self setVolume:volume];
}

- (void)decreaseVolume {
    float volume = [self volume] - 0.1;
    if (volume < 0.0) {
        volume = 0.0;
    }
    [self setVolume:volume];
}

- (long)currentTime {
    CFTimeInterval timeInterval;
    PLAYER->GetCurrentTime(timeInterval);
    return timeInterval * 1000;
}

- (void)setCurrentTime:(long)currentTime {
    PLAYER->SeekToTime(currentTime / 1000);
}

- (long)duration {
    CFTimeInterval duration;
    PLAYER->GetTotalTime(duration);
    return duration * 1000;
}

// ========================================
// Accessors Private

@synthesize transitionTimer = _transitionTimer,
player = player;
@dynamic queueState;

- (PRMovieQueueState)queueState {
    if ((1 << 0) & sPlayerFlags) {
        return PRMovieQueueEmpty;
    } else if ((1 << 1) & sPlayerFlags) {
        return PRMovieQueueWaiting;
    } else if ((1 << 2) & sPlayerFlags) {
        return PRMovieQueuePlayed;
    }
    return PRMovieQueueEmpty;
}

- (void)setQueueState:(PRMovieQueueState)queueState {
    if (queueState == PRMovieQueueEmpty) {
        OSAtomicTestAndSetBarrier(7, &sPlayerFlags);
        OSAtomicTestAndClearBarrier(6, &sPlayerFlags);
        OSAtomicTestAndClearBarrier(5, &sPlayerFlags);
    } else if (queueState == PRMovieQueueWaiting) {
        OSAtomicTestAndClearBarrier(7, &sPlayerFlags);
        OSAtomicTestAndSetBarrier(6, &sPlayerFlags);
        OSAtomicTestAndClearBarrier(5, &sPlayerFlags);
    } else if (queueState == PRMovieQueuePlayed) {
        OSAtomicTestAndClearBarrier(7, &sPlayerFlags);
        OSAtomicTestAndClearBarrier(6, &sPlayerFlags);
        OSAtomicTestAndSetBarrier(5, &sPlayerFlags);
    }
}

// ========================================
// Update Private

- (void)update {
    [[NSNotificationCenter defaultCenter] postTimeChanged];
    [self willChangeValueForKey:@"duration"];
    [self didChangeValueForKey:@"duration"];
    [self willChangeValueForKey:@"currentTime"];
    [self didChangeValueForKey:@"currentTime"];
    
    int timeLeft = [self duration] - [self currentTime];
    if ([self queueState] == PRMovieQueueEmpty && [self isPlaying] && timeLeft < 2000) {
        [[NSNotificationCenter defaultCenter] postMovieAlmostFinished];
    }
}

- (void)preGainDidChange:(NSNotification *)note {
//    float preGain = [[PRUserDefaults userDefaults] preGain];
    PLAYER->SetPreGain(1.0);
}

- (void)EQChanged:(NSNotification *)note {
	/*
    PREQ *EQ;
    if (![[PRUserDefaults userDefaults] EQIsEnabled]) {
        EQ = [PREQ flat];
    } else if ([[PRUserDefaults userDefaults] isCustomEQ]) {
        EQ = [[[PRUserDefaults userDefaults] customEQs] objectAtIndex:[[PRUserDefaults userDefaults] EQIndex]];
    } else {
        EQ = [[PREQ defaultEQs] objectAtIndex:[[PRUserDefaults userDefaults] EQIndex]];
    }
    
    for (int i = 0; i < 10; i++) {
        float amp = [EQ ampForFreq:(PREQFreq)(i + 1)] + [EQ ampForFreq:PREQFreqPreamp];
        if (amp > 20) {
            amp = 20;
        } else if (amp < -20) {
            amp = -20;
        }
        OSStatus status = AudioUnitSetParameter(_au, i, kAudioUnitScope_Global, 0, amp, 0);
        if (status != 0) {
            NSLog(@"EQ failed:%d",(int)status);
        }
    }
	*/
}

@end


static void decodingStarted(void *context, const AudioDecoder *decoder) {
//    NSLog(@"decodingStarted");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    PRMoviePlayer *player = (PRMoviePlayer *)context;
    static_cast<AudioPlayer *>([player player])->Play();
    if ([player queueState] == PRMovieQueueWaiting) {
        [player setQueueState:PRMovieQueuePlayed];
    }
    [p drain];
}

static void renderingStarted(void *context, const AudioDecoder *decoder) {
//    NSLog(@"renderingStarted");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
}

static void decodingFinished(void *context, const AudioDecoder *decoder) {
//    NSLog(@"decodingFinished");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
}

static void renderingFinished(void *context, const AudioDecoder *decoder) {
//    NSLog(@"renderingFinished");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    [[NSOperationQueue mainQueue] addBlock:^{[[NSNotificationCenter defaultCenter] postMovieFinished];}];
    [p drain];
}
