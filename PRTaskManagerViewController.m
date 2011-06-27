#import "PRTaskManagerViewController.h"
#import "PRTaskManager.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRTask.h"


@implementation PRTaskManagerViewController

// ========================================
// Initialization
// ========================================

- (id)initWithTaskManager:(PRTaskManager *)taskManager_ core:(PRCore *)core_
{
    self = [super initWithWindowNibName:@"PRTaskManagerView"];
    if (self) {
        taskManager = taskManager_;
        core = core_;
        
        [taskManager addObserver:self forKeyPath:@"tasks" options:0 context:nil];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelTask)];
}

- (void)dealloc
{
    [super dealloc];
}

// ========================================
// Update
// ========================================

- (void)update
{
	if ([[taskManager tasks] count] > 0) {
        PRTask *task = [[taskManager tasks] objectAtIndex:0];
        if ([task background]) {
            [[core win] setProgressHidden:FALSE];
            if ([[self window] isVisible]) {
                [self endSheet];
            }
            
            [[core win] setProgressTitle:[task title]];
            [[core win] setProgressValue:[[task value] intValue]];
        } else {
            [[core win] setProgressHidden:TRUE];
            if (![[self window] isVisible]) {
                [self beginSheet];
            }
            
            [titleTextField setStringValue:[task title]];
        }
    } else {
        [self endSheet];
        [[core win] setProgressHidden:TRUE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    
    if (object == [core taskManager] && [keyPath isEqualToString:@"tasks"]) {
        [self update];
    }
}

// ========================================
// Action
// ========================================

- (void)beginSheet
{
	[NSApp beginSheet:[self window] 
	   modalForWindow:[[core win] window]
        modalDelegate:self 
	   didEndSelector:NULL 
		  contextInfo:nil];
	
	[progressIndicator setUsesThreadedAnimation:TRUE];
	[progressIndicator startAnimation:self];
	
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)endSheet
{
    [NSApp endSheet:[self window]];
	[[self window] orderOut:nil];
}

- (void)setTitle:(NSString *)title
{
	[titleTextField setStringValue:title];
}

- (void)cancelTask
{
    PRTask *task = [[taskManager tasks] objectAtIndex:0];
    [task setShouldCancel:TRUE];
}

@end
