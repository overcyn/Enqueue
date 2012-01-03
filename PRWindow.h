#import <Foundation/Foundation.h>


@interface PRWindow : NSWindow
{
    BOOL _entered;
    NSTrackingArea *_trackingArea;
}

- (BOOL)mouseInGroup:(NSButton*)widget;
- (void)updateTrackingArea;

@end
