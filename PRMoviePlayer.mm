#import "PRMoviePlayer.h"
#import <AudioUnit/AudioUnit.h>
#import <CoreAudio/CoreAudio.h>
#import <QuickTime/QuickTime.h>
#include <cmath>
#include <libkern/OSAtomic.h>
#include <SFBAudioEngine/AudioDecoder.h>
#include <SFBAudioEngine/AudioPlayer.h>
#import "AUParamInfo.h"
#import "CAAUParameter.h"
// #import "NSNotificationCenter+Extensions.h"
#import "NSObject+SPInvocationGrabbing.h"
#import "NSOperationQueue+Extensions.h"
#import "PRDefaults.h"
#import "PREQ.h"

typedef NS_ENUM(NSInteger, PRMoviePlayerTransitionState) {
    PRNeitherTransitionState,
    PRPlayingTransitionState,
    PRPausingTransitionState,
};

#define PLAYER                      (static_cast<AudioPlayer *>(_player))
#define ALMOST_FINISHED_FLAG        7
#define TRANSITION_VOLUME_STEP      0.1
#define TRANSITION_TIME_STEP        0.025
#define DEFAULT_BUFFER_CAPACITY     16384
#define DEFAULT_BUFFER_CHUCK_SIZE   2048

volatile static uint32_t moviePlayerFlags = 0;
static void decodingStarted(void *context, const AudioDecoder *decoder);
static void renderingStarted(void *context, const AudioDecoder *decoder);
static void decodingFinished(void *context, const AudioDecoder *decoder);
static void renderingFinished(void *context, const AudioDecoder *decoder);

OSStatus deviceListener(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void *inClientData);

NSString * const PRDeviceKeyName = @"PRDeviceKeyName";
NSString * const PRDeviceKeyManufacturer = @"PRDeviceKeyManufacturer";
NSString * const PRDeviceKeyUID = @"PRDeviceKeyUID";

@interface PRMoviePlayer ()
@end

@implementation PRMoviePlayer {
    void *_player;
    AudioUnit _equalizer;
    NSTimer    *_UIUpdateTimer;
    NSString *_lastQueued;
    
    float _transitionVolume;
    int _transitionState;
    NSTimer *_transitionTimer;
}

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    _player = new AudioPlayer();
    
    _UIUpdateTimer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(update) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_UIUpdateTimer forMode:NSRunLoopCommonModes];
    
    // [[NSNotificationCenter defaultCenter] observeEQChanged:self sel:@selector(EQDidChange:)];
    // [[NSNotificationCenter defaultCenter] observeBackendChanged:self sel:@selector(_backendDidChange:)];
    // KD:
//    AudioObjectPropertyAddress propertyAddress;
//    propertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
//    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
//    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
//    AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, deviceListener, self);
//    
//    propertyAddress.mSelector = kAudioHardwarePropertyDevices;
//    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
//    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
//    AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, deviceListener, self);
    
    [self updateEQ];
    [self updateHogOutput];
    [self setVolume:[self volume]];
    
    PLAYER->SetRingBufferCapacity(DEFAULT_BUFFER_CAPACITY*16);
    PLAYER->SetRingBufferWriteChunkSize(DEFAULT_BUFFER_CHUCK_SIZE*2);
	return self;
}

- (void)dealloc {
    [_UIUpdateTimer invalidate];
    [_transitionTimer invalidate];
    
    delete PLAYER;
}

#pragma mark - Accessors

@dynamic isPlaying;
@dynamic volume;
@dynamic currentTime;
@dynamic duration;

- (BOOL)isPlaying {
    if (_transitionState == PRPausingTransitionState) {
        return FALSE;
    } else if (_transitionState == PRPlayingTransitionState) {
        return TRUE;
    }
    return PLAYER->IsPlaying();
}

- (float)volume {
    return [[PRDefaults sharedDefaults] floatForKey:PRDefaultsVolume];
}

- (void)setVolume:(float)volume {
    [[PRDefaults sharedDefaults] setFloat:volume forKey:PRDefaultsVolume];
    if (_transitionState == PRNeitherTransitionState) {
        PLAYER->SetVolume([self volume]);
    }
    // [[NSNotificationCenter defaultCenter] postChanges:@[[[PRMovieChange alloc] init]]];
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

#pragma mark - Update Private

- (void)update {
    // PRMovieChange *change = [[PRMovieChange alloc] init];
    // [change setProgress:YES];
    // [[NSNotificationCenter defaultCenter] postChanges:@[change]];
    // if ([self isPlaying] && ([self duration] - [self currentTime]) < 2000 && !OSAtomicTestAndSetBarrier(ALMOST_FINISHED_FLAG, &moviePlayerFlags) ) {
    //     [[NSNotificationCenter defaultCenter] postMovieAlmostFinished];
    // }
}

#pragma mark - Notifications

- (void)_backendDidChange:(NSNotification *)note {
    // for (NSObject *i in [[note userInfo][@"changeset"] changes]) {
    //     if ([i isKindOfClass:[PRListChange class]]) {
    //         [self updateHogOutput];
    //     }
    // }
}

- (void)EQDidChange:(NSNotification *)note {
    [self updateEQ];
}

#pragma mark - Playback

- (BOOL)play:(NSString *)file {
    // clear queue & stop
    PLAYER->Pause();
    PLAYER->Stop();
    PLAYER->ClearQueuedDecoders();
    _lastQueued = nil;
    
    // invalidate transition timer and reset volume
    [_transitionTimer invalidate];
    _transitionTimer = nil;
    _transitionState = PRNeitherTransitionState;
    [self setVolume:[self volume]];
    
    AudioDecoder *decoder = AudioDecoder::CreateDecoderForURL((__bridge CFURLRef)([NSURL URLWithString:file]));
    if (!decoder) {
		return FALSE;
    }
    decoder->SetDecodingStartedCallback(decodingStarted, PLAYER);
    decoder->SetDecodingFinishedCallback(decodingFinished, PLAYER);
    decoder->SetRenderingStartedCallback(renderingStarted, PLAYER);
	decoder->SetRenderingFinishedCallback(renderingFinished, PLAYER);
    if (!decoder->Open() || !PLAYER->Enqueue(decoder)) {
        delete decoder;
        return FALSE;
    }
    return TRUE;
}

- (BOOL)queue:(NSString *)file {
    PLAYER->ClearQueuedDecoders();
    
    AudioDecoder *decoder = AudioDecoder::CreateDecoderForURL((__bridge CFURLRef)([NSURL URLWithString:file]));
    if (!decoder) {
		return FALSE;
    }
    decoder->SetDecodingStartedCallback(decodingStarted, PLAYER);
    decoder->SetDecodingFinishedCallback(decodingFinished, PLAYER);
    decoder->SetRenderingStartedCallback(renderingStarted, PLAYER);
	decoder->SetRenderingFinishedCallback(renderingFinished, PLAYER);
    if (!decoder->Open() || !PLAYER->Enqueue(decoder)) {
        delete decoder;
        return FALSE;
    }
    _lastQueued = file;
    return TRUE;
}

- (BOOL)playIfNotQueued:(NSString *)file {
    NSString *queued = nil;
    if (PLAYER->IsPending()) {
        queued = _lastQueued;
    } else if (PLAYER->IsPlaying()) {
        queued = [(__bridge NSURL *)PLAYER->GetPlayingURL() absoluteString];
    }
    if ([queued isEqualToString:file]) {
        _lastQueued = nil;
        return TRUE;
    }
    return [self play:file];
}

- (void)stop {
    PLAYER->Stop();
    // [[NSNotificationCenter defaultCenter] postChanges:@[[[PRMovieChange alloc] init]]];
}

- (void)pauseUnpause {
    if ([self isPlaying]) {
        if (_transitionState != PRPlayingTransitionState) {
            _transitionVolume = 1;
        }
        _transitionState = PRPausingTransitionState;
        PLAYER->SetVolume(_transitionVolume * [self volume]);
        [self transitionCallback:nil];
    } else {
        if (_transitionState != PRPausingTransitionState) {
            _transitionVolume = 0;
        }
        _transitionState = PRPlayingTransitionState;
        PLAYER->SetVolume(_transitionVolume * [self volume]);
        PLAYER->Play();
        [self transitionCallback:nil];
        // [[NSNotificationCenter defaultCenter] postChanges:@[[[PRMovieChange alloc] init]]];
    }
}

- (void)seekForward {
	PLAYER->SeekForward();
}

- (void)seekBackward {
	PLAYER->SeekBackward();
}

#pragma mark - Playback Private

- (void)transitionCallback:(NSTimer *)timer {
    switch (_transitionState) {
        case PRNeitherTransitionState:
            break;
        case PRPlayingTransitionState:
            _transitionVolume += TRANSITION_VOLUME_STEP;
            if (_transitionVolume >= 1) {
                _transitionVolume = 1;
                _transitionState = PRNeitherTransitionState;
            } else {
                [_transitionTimer invalidate];
                _transitionTimer = [NSTimer timerWithTimeInterval:TRANSITION_TIME_STEP
                                                            target:self
                                                          selector:@selector(transitionCallback:)
                                                          userInfo:nil
                                                           repeats:FALSE];
                [[NSRunLoop currentRunLoop] addTimer:_transitionTimer forMode:NSRunLoopCommonModes];
            }
            PLAYER->SetVolume(_transitionVolume * [self volume]);
            break;
        case PRPausingTransitionState:
            _transitionVolume -= TRANSITION_VOLUME_STEP;
            if (_transitionVolume <= 0) {
                _transitionVolume = 0;
                _transitionState = PRNeitherTransitionState;
                PLAYER->Pause();
                // [[NSNotificationCenter defaultCenter] postChanges:@[[[PRMovieChange alloc] init]]];
            } else {
                [_transitionTimer invalidate];
                _transitionTimer = [NSTimer timerWithTimeInterval:TRANSITION_TIME_STEP
                                                            target:self
                                                          selector:@selector(transitionCallback:)
                                                          userInfo:nil
                                                           repeats:FALSE];
                [[NSRunLoop currentRunLoop] addTimer:_transitionTimer forMode:NSRunLoopCommonModes];
            }
            PLAYER->SetVolume(_transitionVolume * [self volume]);
            break;
        default:
            @throw NSInternalInconsistencyException;
            break;
    }
}

#pragma mark - EQ Private

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

#pragma mark - Devices

@dynamic devices;
@dynamic currentDevice;

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
        CFStringRef name;
        propertySize = sizeof(name);
        deviceAddress.mSelector = kAudioDevicePropertyDeviceNameCFString;
        deviceAddress.mScope = kAudioDevicePropertyScopeOutput;
        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, &name) != noErr) {
            continue;
        }
        NSString *nameStr = (__bridge_transfer NSString *)name;
        CFStringRef manufacturer;
        propertySize = sizeof(manufacturer);
        deviceAddress.mSelector = kAudioDevicePropertyDeviceManufacturerCFString;
        deviceAddress.mScope = kAudioDevicePropertyScopeOutput;
        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, &manufacturer) != noErr) {
            continue;
        }
        NSString *manufacturerStr = (__bridge_transfer NSString *)manufacturer;
        CFStringRef UID;
        propertySize = sizeof(UID);
        deviceAddress.mSelector = kAudioDevicePropertyDeviceUID;
        deviceAddress.mScope = kAudioDevicePropertyScopeOutput;
        deviceAddress.mElement = kAudioObjectPropertyElementMaster;
        if (AudioObjectGetPropertyData(deviceIDs[idx], &deviceAddress, 0, NULL, &propertySize, &UID) != noErr) {
            continue;
        }
        NSString *UIDStr = (__bridge_transfer NSString *)UID;
        [devices addObject:@{PRDeviceKeyName:nameStr, PRDeviceKeyManufacturer:manufacturerStr, PRDeviceKeyUID:UIDStr}];
    }
    free(deviceIDs);
    return devices;
}

- (void)setCurrentDevice:(NSString *)device {
    [[PRDefaults sharedDefaults] setValue:device forKey:PRDefaultsOutputDeviceUID];
    [self updateDevice];
}

- (NSString *)currentDevice {
    NSString *playerDevice = [self playerDevice];
    NSString *savedDevice = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsOutputDeviceUID];
    NSString *defaultDevice = [self defaultDevice];
    
    // if cant get player device, return nil
    if (!playerDevice) {
        return nil;
    }
    
    // if not default device, return current device
    if (savedDevice) {
        return playerDevice;
    }
    
    // get default device. if failure, return current device
    if (!defaultDevice) {
        return playerDevice;
    }
    
    // if default device, return nil
    if ([defaultDevice isEqualToString:playerDevice]) {
        return nil;
    }
    
    // otherwise return current device
    return playerDevice;
}

#pragma mark - Devices Private

- (NSString *)playerDevice {
    CFStringRef playerDevice = nil;
    if (!PLAYER->CreateOutputDeviceUID(playerDevice) || playerDevice == nil) {
        return nil;
    }
    return (__bridge_transfer NSString *)playerDevice;
}

- (NSString *)defaultDevice {
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    AudioDeviceID defaultDeviceID;
    UInt32 propSize = sizeof(defaultDeviceID);
    if (AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propSize, &defaultDeviceID) != noErr) {
        return nil;
    }
    propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
	propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    CFStringRef deviceUID;
	UInt32 dataSize = sizeof(deviceUID);
	if (AudioObjectGetPropertyData(defaultDeviceID, &propertyAddress, 0, nullptr, &dataSize, &deviceUID) != noErr || deviceUID == nil) {
		return nil;
	}
    return (__bridge_transfer NSString *)deviceUID;
}

- (void)updateDevice {
    NSString *playerDevice = [self playerDevice];
    NSString *savedDevice = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsOutputDeviceUID];
    NSString *defaultDevice = [self defaultDevice];
    
    // if can't get player or default device, set to default device
    if (!playerDevice || (!defaultDevice && !savedDevice)) {
        PLAYER->SetOutputDeviceUID(nil);
        // [[NSNotificationCenter defaultCenter] postNotificationName:PRDeviceDidChangeNotification object:nil];
        return;
    }
    
    // if current device equal to saved device, nothing to do but must post notification anyways.
    if (savedDevice != nil ? [playerDevice isEqualToString:savedDevice] : [playerDevice isEqualToString:defaultDevice]) {
        // [[NSNotificationCenter defaultCenter] postNotificationName:PRDeviceDidChangeNotification object:nil];
        return;
    }
    
    // otherwise try to set current device to saved device
    if (PLAYER->SetOutputDeviceUID((__bridge CFStringRef)savedDevice)) {
        // [[NSNotificationCenter defaultCenter] postNotificationName:PRDeviceDidChangeNotification object:nil];
        return;
    }
    
    // if failure try to set current device to default device
    if (PLAYER->SetOutputDeviceUID(nil)) {
        // [[NSNotificationCenter defaultCenter] postNotificationName:PRDeviceDidChangeNotification object:nil];
        return;
    }
    
    // if still failure just update the UI.
    // [[NSNotificationCenter defaultCenter] postNotificationName:PRDeviceDidChangeNotification object:nil];
}

#pragma mark - HogOutput

@dynamic hogOutput;

- (BOOL)hogOutput {
    return [[PRDefaults sharedDefaults] boolForKey:PRDefaultsHogOutput];
}

- (void)setHogOutput:(BOOL)hogOutput {
    [[PRDefaults sharedDefaults] setBool:hogOutput forKey:PRDefaultsHogOutput];
    [self updateHogOutput];
}

#pragma mark - HogOutput Private

- (void)updateHogOutput {
    // only hog when playing
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

@end


OSStatus deviceListener(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void *inClientData) {
    NSLog(@"blah");
    [(__bridge PRMoviePlayer *)inClientData updateDevice];
    return noErr;
}

static void decodingStarted(void *context, const AudioDecoder *decoder) {
//    NSLog(@"decodingStarted");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    @autoreleasepool {
        OSAtomicTestAndClear(ALMOST_FINISHED_FLAG, &moviePlayerFlags);
        static_cast<AudioPlayer *>(context)->Play();
    }
}

static void renderingStarted(void *context, const AudioDecoder *decoder) {
//    NSLog(@"renderingStarted");
//    CFShow(const_cast<CFURLRef>(const_cast<AudioDecoder *>(decoder)->GetURL()));
    @autoreleasepool {
        [[NSOperationQueue mainQueue] addBlock:^{
            // [[NSNotificationCenter defaultCenter] postChanges:@[[[PRMovieChange alloc] init]]];
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
            // [[NSNotificationCenter defaultCenter] postMovieFinished];
            // [[NSNotificationCenter defaultCenter] postChanges:@[[[PRMovieChange alloc] init]]];
        }];
    }
}
