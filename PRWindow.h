#import <Foundation/Foundation.h>


@interface PRWindow : NSWindow {
    BOOL _entered;
    NSTrackingArea *_trackingArea;
}
- (BOOL)mouseInGroup:(NSButton*)widget;
- (void)updateTrackingArea;
@end


@protocol PRWindowDelegate <NSObject>
@optional
- (BOOL)window:(NSWindow *)window keyDown:(NSEvent *)event;
@end
