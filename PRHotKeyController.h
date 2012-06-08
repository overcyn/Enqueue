#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
@class PRCore;


typedef enum {
    PRPlayPauseHotKey,
    PRNextHotKey,
    PRPreviousHotKey,
    PRIncreaseVolumeHotKey,
    PRDecreaseVolumeHotKey,
    PRRate0HotKey,
    PRRate1HotKey,
    PRRate2HotKey,
    PRRate3HotKey,
    PRRate4HotKey,
    PRRate5HotKey,
} PRHotKey;


@interface PRHotKeyController : NSObject {
    EventHotKeyRef _hotKeyRefs[11];
    __weak PRCore *_core;
}
- (id)initWithCore:(PRCore *)core;
- (void)mask:(unsigned int *)mask code:(int *)code forHotKey:(PRHotKey)hotKey;
- (void)setMask:(unsigned int)mask code:(int)code forHotKey:(PRHotKey)hotKey;
@end


OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData);
