#import <AppKit/AppKit.h>


@interface PRAlertWindowController : NSWindowController {
    void (^_handler)(void);
}
- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void(^)(void))block;
- (void)endSheet;
@end
