#import <Cocoa/Cocoa.h>

@class PRCore;

@interface PRTaskManagerViewController : NSWindowController 
{
    IBOutlet NSTextField *titleTextField;
	IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSButton *cancelButton;
    
    bool sheetIsVisible;
    
    PRCore *_core;
}

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core;

// ========================================
// Update

- (void)update;

// ========================================
// Action

- (void)beginSheet;
- (void)endSheet;
- (void)setTitle:(NSString *)title;
- (void)cancelTask;


@end
