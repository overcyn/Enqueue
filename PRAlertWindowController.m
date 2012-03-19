#import "PRAlertWindowController.h"


@implementation PRAlertWindowController

- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void(^)(void))block {
    _handler = [block copy];
    [NSApp beginSheet:[self window] 
       modalForWindow:window
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}

- (void)endSheet{
    [[self window] orderOut:nil];
    [NSApp endSheet:[self window]];
    _handler();
}

@end
