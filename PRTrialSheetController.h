#import <Cocoa/Cocoa.h>


@interface PRTrialSheetController : NSWindowController {
    IBOutlet NSTextField *label;
    IBOutlet NSButton *purchase;
    IBOutlet NSButton *ignore;
    
    NSDate *_date;
    
    __weak PRCore *_core;
}
// Initialization
- (id)initWithCore:(PRCore *)core_;

// Sheet
- (void)beginSheetForWindow:(NSWindow *)window;
- (void)endSheet;
@end
