#import <Cocoa/Cocoa.h>

@class PRRuleViewController, PRCore;

@interface PRRulePredicateViewController : NSViewController 
{
    IBOutlet NSView *_predicateView;
    IBOutlet NSButton *_addButton;
    IBOutlet NSPopUpButton *_fileAttributeButton;
    IBOutlet NSPopUpButton *_predicateButton;
    
    IBOutlet NSView *_stringView;
    IBOutlet NSTextField *_textField;
    
    IBOutlet NSView *_stringRangeView;
    IBOutlet NSTextField *_textField1;
    IBOutlet NSTextField *_textField2;
    
    IBOutlet NSView *_dateView;
    IBOutlet NSDatePicker *_dateField;
    
    IBOutlet NSView *_dateRangeView;
    IBOutlet NSDatePicker *_dateField1;
    IBOutlet NSDatePicker *_dateField2;
    
    IBOutlet NSView *_dateWithinView;
    
    IBOutlet NSView *_boolView;
    
    IBOutlet NSButton *_deleteButton;
    
    int _row;
    
    PRCore *_core;
    PRRuleViewController *_ruleView;
}

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core ruleView:(PRRuleViewController *)ruleView row:(int)row;

// ========================================
// Update

- (void)update;

// ========================================
// Action

- (void)add;
- (void)delete;
- (void)predicateMenuAction:(id)sender;
- (void)attributeMenuAction:(id)sender;

@end
