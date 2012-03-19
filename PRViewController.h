#import <AppKit/AppKit.h>


@interface PRViewController : NSViewController {
    NSView *_firstKeyView;
    NSView *_lastKeyView;
}
@property (readonly) NSView *firstKeyView;
@property (readonly) NSView *lastKeyView;
@end
