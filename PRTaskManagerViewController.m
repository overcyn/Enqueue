#import "PRTaskManagerViewController.h"
#import "PRTaskManager.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRTask.h"
#import "PRControlsViewController.h"


@implementation PRTaskManagerViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core
{
    if (!(self = [super initWithWindowNibName:@"PRTaskManagerView"])) {return nil;}
    _core = core;
    [[_core taskManager] addObserver:self forKeyPath:@"tasks" options:0 context:nil];
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
	if ([[[_core taskManager] tasks] count] > 0) {
        PRTask *task = [[[_core taskManager] tasks] objectAtIndex:0];
        if ([task background]) {
            [[[_core win] controlsViewController] setProgressHidden:FALSE];
            [[[_core win] controlsViewController] setProgressTitle:[task title]];
            [[[_core win] controlsViewController] setProgressPercent:[task percent]];
            if ([[self window] isVisible]) {
                [self endSheet];
            }
        } else {
            [[[_core win] controlsViewController] setProgressHidden:TRUE];
            if (![[self window] isVisible]) {
                [self beginSheet];
            }
            [titleTextField setStringValue:[task title]];
        }
    } else {
        [self endSheet];
        [[[_core win] controlsViewController] setProgressHidden:TRUE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    
    if (object == [_core taskManager] && [keyPath isEqualToString:@"tasks"]) {
        [self update];
    }
}

// ========================================
// Action
// ========================================

- (void)beginSheet
{
	[NSApp beginSheet:[self window] 
	   modalForWindow:[[_core win] window]
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
    PRTask *task = [[[_core taskManager] tasks] objectAtIndex:0];
    [task setShouldCancel:TRUE];
}

@end
