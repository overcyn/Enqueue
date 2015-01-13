#import <Cocoa/Cocoa.h>
#import "PRAlertWindowController.h"
@class PRCore;

@interface PRTrialSheetController : PRAlertWindowController {
    __weak PRCore *_core;
    
    NSTextField *_label;
    NSButton *_purchase;
    NSButton *_ignore;
    
    BOOL _didLoadWindow;
}
- (id)initWithCore:(PRCore *)core;
@end
