#import "PRMoviePlayer.h"
#import "PRDefaults.h"
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
@property (readonly) void *player;

/* Notifications */
- (void)EQDidChange:(NSNotification *)note;

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
    
    [[NSNotificationCenter defaultCenter] observeEQChanged:self sel:@selector(EQDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlayingChanged:self sel:@selector(playingDidChange:)];
    
    [self updateEQ];
    [self updateHogOutput];
    [self updateVolume];
    
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
    if (PLAYER->IsPlaying()) {
        NSURL *URL = (NSURL *)PLAYER->GetPlayingURL();
        if (!URL || ![[URL absoluteString] isEqualToString:file]) {
            return [self play:file];
        } else {
            return TRUE;
        }
    } else {
        return [self play:file];
    }
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
@dynamic hogOutput;
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
    return [[PRDefaults sharedDefaults] floatForKey:PRDefaultsVolume];
}

- (void)setVolume:(float)volume {
    [[PRDefaults sharedDefaults] setFloat:volume forKey:PRDefaultsVolume];
    [self updateVolume];
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

- (BOOL)hogOutput {
    return [[PRDefaults sharedDefaults] boolForKey:PRDefaultsHogOutput];
}

- (void)setHogOutput:(BOOL)hogOutput {
    [[PRDefaults sharedDefaults] setBool:hogOutput forKey:PRDefaultsHogOutput];
    [self updateHogOutput];
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

#pragma mark - Update Private

- (void)update {
    [[NSNotificationCenter defaultCenter] postTimeChanged];
    int timeLeft = [self duration] - [self currentTime];
    if ([self isPlaying] && timeLeft < 1000 && !OSAtomicTestAndSetBarrier(7, &sPlayerFlags)) {
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
        if ([self hogOutput] != PLAYER->OutputDeviceIsHogged()) {
            if ([self hogOutput]) {
                PLAYER->StartHoggingOutputDevice();
            } else {
                PLAYER->StopHoggingOutputDevice();
            }
        }
    }
}

- (void)updateEQ {
    BOOL enabled = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCurrent] != nil;
    if (enabled && !_equalizer) {
        [self enableEQ];
    } else if (!enabled && _equalizer) {
        [self disableEQ];
    } else if (enabled && _equalizer) {
        [self modifyEQ];
    }
}

- (void)modifyEQ {
    PREQ *EQ = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCurrent];
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
    BOOL err = PLAYER->RemoveEffect(_equalizer);
    if (!err) {
        NSLog(@"EQ removal failed");
    }
    _equalizer = nil;
}

#pragma mark - Notifications

- (void)playingDidChange:(NSNotification *)note {
    [self updateHogOutput];
}

- (void)EQDidChange:(NSNotification *)note {
    [self updateEQ];
}

@end


static void decodingStarted(void *context, const AudioDecoder *decoder) {
//    NSLog(@"decodingStarted");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    @autoreleasepool {
        OSAtomicTestAndClearBarrier(7, &sPlayerFlags);
        PRMoviePlayer *player = (PRMoviePlayer *)context;
        static_cast<AudioPlayer *>([player player])->Play();
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
