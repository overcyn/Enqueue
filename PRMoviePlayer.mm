#import "PRMoviePlayer.h"
#import "PRUserDefaults.h"
#import "NSNotificationCenter+Extensions.h"
#import "NSOperationQueue+Extensions.h"
#import <AudioUnit/AudioUnit.h>
#include <cmath>
#include <libkern/OSAtomic.h>
#include <SFBAudioEngine/AudioPlayer.h>
#include <SFBAudioEngine/AudioDecoder.h>
#include <CoreAudio/CoreAudio.h>
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
@property (readwrite) PRMovieQueueState queueState;
@property (readonly) void *player;

/* Notifications */
- (void)preGainDidChange:(NSNotification *)notification;
- (void)volumeDidChange:(NSNotification *)note;
- (void)EQDidChange:(NSNotification *)note;
- (void)hogOutputDidChange:(NSNotification *)note;

/* Update */
- (void)update;
- (void)updateVolume;
- (void)updateHogOutput;
- (void)updateEQ;
- (void)modifyEQ;
- (void)enableEQ;
- (void)disableEQ;
@end


@implementation PRMoviePlayer

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    player = new AudioPlayer();
    
    _UIUpdateTimer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(update) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_UIUpdateTimer forMode:NSRunLoopCommonModes];
        
    [[NSNotificationCenter defaultCenter] observePreGainChanged:self sel:@selector(preGainDidChange:)];
    [[NSNotificationCenter defaultCenter] observeEQChanged:self sel:@selector(EQDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlayingChanged:self sel:@selector(playingDidChange:)];
    [[NSNotificationCenter defaultCenter] observeVolumeChanged:self sel:@selector(volumeDidChange:)];
    [NSNotificationCenter addObserver:self selector:@selector(hogOutputDidChange:) name:PRHogOutputDidChangeNotification object:nil];
    
    [self updateEQ];
    [self updateHogOutput];
    [self updateVolume];
    [self setQueueState:PRMovieQueueEmpty];
    
    PLAYER->SetRingBufferCapacity(32768*4);
    PLAYER->SetRingBufferWriteChunkSize(4096);
    
    [self devices];
    
	return self;
}

- (void)dealloc {
    [_UIUpdateTimer invalidate];
    [_transitionTimer invalidate];
    
    delete PLAYER;
    [_UIUpdateTimer release];
    [_transitionTimer release];
    [super dealloc];
}

#pragma mark - Playback

- (BOOL)play:(NSString *)file {
    // clear queue & stop
    [self setQueueState:PRMovieQueueEmpty];
    PLAYER->Pause();
    PLAYER->Stop();
    PLAYER->ClearQueuedDecoders();
    
    // invalidate transition timer and reset volume
    [_transitionTimer invalidate];
    [_transitionTimer release];
    _transitionTimer = nil;
    transitionState = PRNeitherTransitionState;
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
    [[NSNotificationCenter defaultCenter] postPlayingChanged];
}

- (void)pause {
    if ([self isPlaying]) {
        if (transitionState != PRPlayingTransitionState) {
            transitionVolume = 1;
        }
        transitionState = PRPausingTransitionState;
        PLAYER->SetVolume(transitionVolume * [self volume]);
        [self transitionCallback:nil];
    }
}

- (void)unpause {
    if (![self isPlaying]) {
        if (transitionState != PRPausingTransitionState) {
            transitionVolume = 0;
        }
        transitionState = PRPlayingTransitionState;
        PLAYER->SetVolume(transitionVolume * [self volume]);
        PLAYER->Play();
        [self transitionCallback:nil];
    }
    [[NSNotificationCenter defaultCenter] postPlayingChanged];
}

- (void)seekForward {
	PLAYER->SeekForward();
}

- (void)seekBackward {
	PLAYER->SeekBackward();
}

#pragma mark - Playback Private

- (void)transitionCallback:(NSTimer *)timer {
    switch (transitionState) {
        case PRNeitherTransitionState:
            break;
        case PRPlayingTransitionState:
            transitionVolume += 0.1;
            if (transitionVolume >= 1) {
                transitionVolume = 1;
                transitionState = PRNeitherTransitionState;
            } else {
                [_transitionTimer invalidate];
                [_transitionTimer release];
                _transitionTimer = [[NSTimer timerWithTimeInterval:0.025
                                                            target:self
                                                          selector:@selector(transitionCallback:)
                                                          userInfo:nil
                                                           repeats:FALSE] retain];
                [[NSRunLoop currentRunLoop] addTimer:_transitionTimer forMode:NSRunLoopCommonModes];
            }
            PLAYER->SetVolume(transitionVolume * [self volume]);
            break;
        case PRPausingTransitionState:
            transitionVolume -= 0.1;
            if (transitionVolume <= 0) {
                transitionVolume = 0;
                transitionState = PRNeitherTransitionState;
                PLAYER->Pause();
                [[NSNotificationCenter defaultCenter] postPlayingChanged];
            } else {
                [_transitionTimer invalidate];
                [_transitionTimer release];
                _transitionTimer = [[NSTimer timerWithTimeInterval:0.025
                                                            target:self
                                                          selector:@selector(transitionCallback:)
                                                          userInfo:nil
                                                           repeats:FALSE] retain];
                [[NSRunLoop currentRunLoop] addTimer:_transitionTimer forMode:NSRunLoopCommonModes];
            }
            PLAYER->SetVolume(transitionVolume * [self volume]);
            break;
        default:
            @throw NSInternalInconsistencyException;
            break;
    }
}

#pragma mark - Accessors

@dynamic isPlaying;
@dynamic volume;
@dynamic currentTime;
@dynamic duration;
@dynamic devices;
@dynamic currentDevice;

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

- (NSArray *)devices {
    UInt32 propertySize;
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioHardwarePropertyDevices;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize) != noErr) {
        return nil;
    }
    NSInteger numDevices = propertySize / sizeof(AudioDeviceID);
    AudioObjectID *deviceIDs = (AudioDeviceID *)calloc(numDevices, sizeof(AudioDeviceID));
    if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, deviceIDs) != noErr) {
        free(deviceIDs);
        return nil;
    }
    
    NSMutableArray *devices = [NSMutableArray array];
    for (NSInteger idx=0; idx<numDevices; idx++) {
        AudioObjectPropertyAddress deviceAddress;
        UInt32 dataSize;
        deviceAddress.mSelector = kAudioDevicePropertyStreams;
        deviceAddress.mScope = kAudioDevicePropertyScopeOutput;
        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
        if (AudioObjectGetPropertyDataSize(deviceIDs[idx], &deviceAddress, 0, NULL, &dataSize) != noErr ||
            (dataSize / sizeof(AudioStreamID)) < 1) {
            continue;
        }
        char deviceName[64];
        propertySize = sizeof(deviceName);
        deviceAddress.mSelector = kAudioDevicePropertyDeviceName;
        deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, deviceName) != noErr) {
            continue;
        }
        char manufacturerName[64];
        propertySize = sizeof(manufacturerName);
        deviceAddress.mSelector = kAudioDevicePropertyDeviceManufacturer;
        deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, manufacturerName) != noErr) {
            continue;
        }
        CFStringRef uidString;
        propertySize = sizeof(uidString);
        deviceAddress.mSelector = kAudioDevicePropertyDeviceUID;
        deviceAddress.mScope = kAudioObjectPropertyScopeGlobal;
        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, &uidString) != noErr) {
            continue;
        }
        [devices addObject:[NSString stringWithString:(NSString *)uidString]];
        CFRelease(uidString);
    }
    free(deviceIDs);
    return devices;
}

- (void)setCurrentDevice:(NSString *)device {
    
}

- (NSString *)currentDevice {
    
}

#pragma mark - Accessors Private

@synthesize player = player;
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

#pragma mark - Update Private

- (void)update {
    [[NSNotificationCenter defaultCenter] postTimeChanged];
    int timeLeft = [self duration] - [self currentTime];
    if ([self queueState] == PRMovieQueueEmpty && [self isPlaying] && timeLeft < 2000) {
        [[NSNotificationCenter defaultCenter] postMovieAlmostFinished];
    }
}

- (void)updateVolume {
    if (transitionState == PRNeitherTransitionState) {
        PLAYER->SetVolume([self volume]);
    }
}

- (void)updateHogOutput {
    if (![self isPlaying]) {
        if (PLAYER->OutputDeviceIsHogged()) {
            PLAYER->StopHoggingOutputDevice();
        }
    } else {
        if ([[PRUserDefaults userDefaults] hogOutput] != PLAYER->OutputDeviceIsHogged()) {
            if ([[PRUserDefaults userDefaults] hogOutput]) {
                PLAYER->StartHoggingOutputDevice();
            } else {
                PLAYER->StopHoggingOutputDevice();
            }
        }
    }
}

- (void)updateEQ {
    BOOL enabled = [[PRUserDefaults userDefaults] EQIsEnabled];
    if (enabled && !_equalizer) {
        [self enableEQ];
    } else if (!enabled && _equalizer) {
        [self disableEQ];
    } else if (enabled && _equalizer) {
        [self modifyEQ];
    }
}

- (void)modifyEQ {
    PREQ *EQ;
    if ([[PRUserDefaults userDefaults] isCustomEQ]) {
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
        OSStatus status = AudioUnitSetParameter(_equalizer, i, kAudioUnitScope_Global, 0, amp, 0);
        if (status != 0) {
            NSLog(@"EQ update failed:%d",(int)status);
        }
    }
}

- (void)enableEQ {
    OSStatus status;
    BOOL err = PLAYER->AddEffect(kAudioUnitSubType_GraphicEQ, kAudioUnitManufacturer_Apple, 0, 0, &_equalizer);
    if (!err) {
        NSLog(@"EQ addition failed");
        goto error;
    }
    status = AudioUnitInitialize(_equalizer);
    if (status != 0) {
        NSLog(@"EQ initialization failed:%d",(int)status);
        goto error;
    }
    status = AudioUnitSetParameter(_equalizer, kGraphicEQParam_NumberOfBands, kAudioUnitScope_Global, 0, 0, 0);
    if (status != 0) {
        NSLog(@"EQ set parameter failed:%d",(int)status);
        goto error;
    }
    [self updateEQ];
    return;
    
error:;
    PLAYER->RemoveEffect(_equalizer);
    _equalizer = nil;
    return;
}

- (void)disableEQ {
    BOOL succ = PLAYER->RemoveEffect(_equalizer);
    if (succ != TRUE) {
        NSLog(@"EQ removal failed");
    }
    _equalizer = nil;
}

#pragma mark - Notifications

- (void)playingDidChange:(NSNotification *)note {
    [self updateHogOutput];
}

- (void)preGainDidChange:(NSNotification *)note {
}

- (void)volumeDidChange:(NSNotification *)note {
    [self updateVolume];
}

- (void)EQDidChange:(NSNotification *)note {
    [self updateEQ];
}

- (void)hogOutputDidChange:(NSNotification *)note {
    [self updateHogOutput];
}


@end


static void decodingStarted(void *context, const AudioDecoder *decoder) {
//    NSLog(@"decodingStarted");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    @autoreleasepool {
        PRMoviePlayer *player = (PRMoviePlayer *)context;
        static_cast<AudioPlayer *>([player player])->Play();
        if ([player queueState] == PRMovieQueueWaiting) {
            [player setQueueState:PRMovieQueuePlayed];
        }
    }
}

static void renderingStarted(void *context, const AudioDecoder *decoder) {
//    NSLog(@"renderingStarted");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    @autoreleasepool {
        [[NSOperationQueue mainQueue] addBlock:^{
            [[NSNotificationCenter defaultCenter] postPlayingChanged];
        }];
    }
}

static void decodingFinished(void *context, const AudioDecoder *decoder) {
//    NSLog(@"decodingFinished");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    @autoreleasepool {
    }
}

static void renderingFinished(void *context, const AudioDecoder *decoder) {
//    NSLog(@"renderingFinished");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    @autoreleasepool {
        [[NSOperationQueue mainQueue] addBlock:^{
            [[NSNotificationCenter defaultCenter] postMovieFinished];
            [[NSNotificationCenter defaultCenter] postPlayingChanged];
        }];
    }
}
