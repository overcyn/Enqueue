#import <Cocoa/Cocoa.h>

@interface PRTrialSheetController : NSWindowController
{
    IBOutlet NSTextField *label;
    IBOutlet NSButton *purchase;
    IBOutlet NSButton *ignore;
    
    NSDate *_date;
    
    PRCore *_core;
}

- (id)initWithCore:(PRCore *)core_;

- (void)ignore;
- (void)purchase;

- (void)beginSheetForWindow:(NSWindow *)window;
- (void)endSheet;

@end
