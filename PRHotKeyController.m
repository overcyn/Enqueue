#import "PRHotKeyController.h"
#import "PRCore.h"
#import "PRMoviePlayer.h"
#import "PRNowPlayingController.h"
#import "PRDefaults.h"
#import <Carbon/Carbon.h>
#import <ShortcutRecorder/SRRecorderControl.h>


@interface PRHotKeyController ()
- (void)updateHotKeys;
+ (NSDictionary *)defaultsKeyDictionary;
@end


@implementation PRHotKeyController

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    [self updateHotKeys];
    return self;
}

- (void)mask:(unsigned int *)mask code:(int *)code forHotKey:(PRHotKey)hotKey {
    NSArray *hotKeys = [[PRDefaults sharedDefaults] valueForKey:[PRHotKeyController defaultsKeyForHotKey:hotKey]];
    *mask = [[hotKeys objectAtIndex:0] unsignedIntValue];
    *code = [[hotKeys objectAtIndex:1] intValue];
    
}

- (void)setMask:(unsigned int)mask code:(int)code forHotKey:(PRHotKey)hotKey {
    [[PRDefaults sharedDefaults] setValue:@[[NSNumber numberWithUnsignedInt:mask],[NSNumber numberWithInt:code]] 
                                   forKey:[PRHotKeyController defaultsKeyForHotKey:hotKey]];
    [self updateHotKeys];
}

- (void)updateHotKeys {
    for (int i = PRPlayPauseHotKey; i <= PRRate5HotKey; i++) {
        UnregisterEventHotKey(_hotKeyRefs[i-1]);
        
        unsigned int mask;
        int code;
        [self mask:&mask code:&code forHotKey:i];
        if (code == -1) {
            continue;
        }
        
        EventTypeSpec eventType;
        eventType.eventClass=kEventClassKeyboard;
        eventType.eventKind=kEventHotKeyPressed;
        InstallApplicationEventHandler(&hotKeyHandler, 1, &eventType, _core, NULL);
        
        EventHotKeyID hotKeyID;
        hotKeyID.signature = 's';
        hotKeyID.id = i;
        RegisterEventHotKey(code, mask, hotKeyID, GetApplicationEventTarget(), 0, &_hotKeyRefs[i-i]);
    }
}

+ (NSString *)defaultsKeyForHotKey:(PRHotKey)hotKey {
    return [@[
        PRDefaultsPlayPauseHotKey,
        PRDefaultsNextHotKey,
        PRDefaultsPreviousHotKey,
        PRDefaultsIncreaseVolumeHotKey,
        PRDefaultsDecreaseVolumeHotKey,
        PRDefaultsRate0HotKey,
        PRDefaultsRate1HotKey,
        PRDefaultsRate2HotKey,
        PRDefaultsRate3HotKey,
        PRDefaultsRate4HotKey,
        PRDefaultsRate5HotKey] objectAtIndex:hotKey];
}

@end


OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
    PRCore *core = userData;
    EventHotKeyID hotkey;
    GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotkey), NULL, &hotkey);
    switch (hotkey.id) {
    case PRPlayPauseHotKey:
        [[core now] playPause];
        break;
    case PRNextHotKey:
        [[core now] playNext];
        break;
    case PRPreviousHotKey:
        [[core now] playPrevious];
        break;
    case PRIncreaseVolumeHotKey:
        [[[core now] mov] increaseVolume];
        break;
    case PRDecreaseVolumeHotKey:
        [[[core now] mov] decreaseVolume];
        break;
    case PRRate0HotKey:
    case PRRate1HotKey:
    case PRRate2HotKey:
    case PRRate3HotKey:
    case PRRate4HotKey:
    case PRRate5HotKey:
        if ([[core now] currentItem]) {
            NSNumber *rating = [NSNumber numberWithInt:(hotkey.id-PRRate0HotKey)*20];
            [[[core db] library] setValue:rating forItem:[[core now] currentItem] attr:PRItemAttrRating];
            [[NSNotificationCenter defaultCenter] postItemsChanged:@[[[core now] currentItem]]];
        }
        break;
    }
    return noErr;
}
