#import <Cocoa/Cocoa.h>

@class PRTaskManager, PRCore;

@interface PRTaskManagerViewController : NSWindowController 
{
    IBOutlet NSTextField *titleTextField;
	IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSButton *cancelButton;
    
    bool sheetIsVisible;
    
    PRCore *core;
    PRTaskManager *taskManager;
}

// ========================================
// Initialization

- (id)initWithTaskManager:(PRTaskManager *)taskManager core:(PRCore *)core_;

// ========================================
// Update

- (void)update;

// ========================================
// Action

- (void)beginSheet;
- (void)endSheet;
- (void)setTitle:(NSString *)title;


@end
