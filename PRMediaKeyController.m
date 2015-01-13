#import "PRMediaKeyController.h"
#import "PRCore.h"
#import "SPMediaKeyTap.h"
#import "PRDefaults.h"
#import "PRPlayer.h"


@implementation PRMediaKeyController

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _tap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        kMediaKeyUsingBundleIdentifiersDefaultsKey:[SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers]}];
    [self setEnabled:[self isEnabled]];
    return self;
}

- (void)dealloc {
    [_tap stopWatchingMediaKeys];
}

- (void)mediaKeyTap:(SPMediaKeyTap *)keyTap receivedMediaKeyEvent:(NSEvent *)event {
    if ([event type] != NSSystemDefined || [event subtype] != SPSystemDefinedEventMediaKeys) {
        return;
    }
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    
    if (keyState == 1 && [self isEnabled]) {
        switch (keyCode) {
        case NX_KEYTYPE_PLAY:
            [[_core now] playPause];
            return;
        case NX_KEYTYPE_FAST:
            [[_core now] playNext];
            return;
        case NX_KEYTYPE_REWIND:
            [[_core now] playPrevious];
            return;
        }
    }
}

@dynamic enabled;

- (BOOL)isEnabled {
    return [[PRDefaults sharedDefaults] boolForKey:PRDefaultsMediaKeys];
}

- (void)setEnabled:(BOOL)enabled {
    [[PRDefaults sharedDefaults] setBool:enabled forKey:PRDefaultsMediaKeys];
    if (enabled) {
        [_tap startWatchingMediaKeys];
    } else {
        [_tap stopWatchingMediaKeys];
    }
}

@end
