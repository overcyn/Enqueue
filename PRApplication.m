#import "PRApplication.h"
#import "IOKit/hidsystem/ev_keymap.h"
#import "PRCore.h"
#import "PRNowPlayingController.h"
#import "PRUserDefaults.h"


@implementation PRApplication

// ========================================
// Media Keys
// ========================================

// rogueamoeba.com/utm/2007/09/29/
- (void)sendEvent: (NSEvent*)event
{
	if( [event type] == NSSystemDefined && [event subtype] == 8 ) {
		int keyCode = (([event data1] & 0xFFFF0000) >> 16);
		int keyFlags = ([event data1] & 0x0000FFFF);
		int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
		int keyRepeat = (keyFlags & 0x1);
        
		[self mediaKeyEvent: keyCode state: keyState repeat: keyRepeat];
	}
    
	[super sendEvent: event];
}

- (void)mediaKeyEvent:(int)key state:(BOOL)state repeat:(BOOL)repeat
{   
    if (![[PRUserDefaults userDefaults] mediaKeys]) {
        return;
    }
	switch(key) {
		case NX_KEYTYPE_PLAY:
			if (state == 0) {
                [[(PRCore *)[self delegate] now] playPause];
            }
            break;
		case NX_KEYTYPE_FAST:
			if (state == 0) {
				[[(PRCore *)[self delegate] now] playNext];
            }
            break;
		case NX_KEYTYPE_REWIND:
			if (state == 0) {
				[[(PRCore *)[self delegate] now] playPrevious];
            }
            break;
	}
}


@end
