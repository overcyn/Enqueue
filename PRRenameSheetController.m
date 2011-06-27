#import "PRRenameSheetController.h"
#import "PRCore.h"


@implementation PRRenameSheetController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_;
{
    self = [super initWithWindowNibName:@"PRWelcomeSheet"];
    if (self) {
        core = core_;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

// ========================================
// Action
// ========================================

- (void)beginSheetForWindow:(NSWindow *)window
{
    [NSApp beginSheet:[self window] 
       modalForWindow:window 
        modalDelegate:self 
       didEndSelector:NULL
          contextInfo:nil];
}

@end
