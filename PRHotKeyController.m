#import "PRHotKeyController.h"
#import "PRCore.h"
#import "PRMoviePlayer.h"
#import "PRNowPlayingController.h"
#import "PRDefaults.h"
#import <Carbon/Carbon.h>
#import <ShortcutRecorder/SRRecorderControl.h>


@implementation PRHotKeyController

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    [self updateHotKeys];
    return self;
}

- (void)setKeymask:(unsigned int)keymask code:(int)code forHotKey:(PRHotKey)hotKey {
    [[PRDefaults sharedDefaults] setKeyMask:keymask keyCode:code forHotKey:hotKey];
    [self updateHotKeys];
}

- (void)updateHotKeys {
    for (int i = PRPlayPauseHotKey; i <= PRRate5HotKey; i++) {
        UnregisterEventHotKey(_hotKeyRefs[i-1]);
        
        unsigned int keymask;
        int code;
        [[PRDefaults sharedDefaults] keyMask:&keymask keyCode:&code forHotKey:i];
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
        RegisterEventHotKey(code, keymask, hotKeyID, GetApplicationEventTarget(), 0, &_hotKeyRefs[i-i]);
    }
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
    case PRDecreaseVolumetHotKey:
        [[[core now] mov] decreaseVolume];
        break;
    case PRRate1HotKey:
    case PRRate2HotKey:
    case PRRate3HotKey:
    case PRRate4HotKey:
    case PRRate5HotKey:
        if ([[core now] currentItem]) {
            NSNumber *rating = [NSNumber numberWithInt:(hotkey.id-PRRate1HotKey+1)*20];
            [[[core db] library] setValue:rating forItem:[[core now] currentItem] attr:PRItemAttrRating];
            [[NSNotificationCenter defaultCenter] postItemsChanged:@[[[core now] currentItem]]];
        }
        break;
    }
    return noErr;
}
