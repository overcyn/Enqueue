#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
@class PRCore;


typedef enum {
    PRPlayPauseHotKey = 1,
    PRNextHotKey,
    PRPreviousHotKey,
    PRIncreaseVolumeHotKey,
    PRDecreaseVolumetHotKey,
    PRRate1HotKey,
    PRRate2HotKey,
    PRRate3HotKey,
    PRRate4HotKey,
    PRRate5HotKey,
} PRHotKey;


@interface PRHotKeyController : NSObject {
    EventHotKeyRef _hotKeyRefs[10];
    __weak PRCore *_core;
}
- (id)initWithCore:(PRCore *)core;
- (void)setKeymask:(unsigned int)keymask code:(int)code forHotKey:(PRHotKey)hotKey;
- (void)updateHotKeys;
@end

OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData);