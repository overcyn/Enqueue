#import "PRKeyboardShortcuts.h"
#import "PRCore.h"
#import "SPMediaKeyTap.h"
#import "PRUserDefaults.h"
#import "PRNowPlayingController.h"


@implementation PRKeyboardShortcuts

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _tap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    [_tap startWatchingMediaKeys];
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{kMediaKeyUsingBundleIdentifiersDefaultsKey:[SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers]}];
    return self;
}

- (void)dealloc {
    [_tap release];
    [super dealloc];
}

- (void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event {
    if ([event type] != NSSystemDefined || [event subtype] != SPSystemDefinedEventMediaKeys) {
        return;
    }
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    //	int keyRepeat = (keyFlags & 0x1);
    
	if (keyState == 1 && [[PRUserDefaults userDefaults] mediaKeys]) {
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

@end
