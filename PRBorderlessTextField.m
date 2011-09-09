#import "PRBorderlessTextField.h"


@implementation PRBorderlessTextField

- (BOOL)becomeFirstResponder
{
	if ([self isEditable]) {
		[self setBordered:TRUE];
		[self setDrawsBackground:TRUE];
	}
	return TRUE;
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
	[self setDrawsBackground:FALSE];
	[self setBordered:FALSE];
	[self validateEditing];
	[self abortEditing];
}

- (void)cancelOperation:(id)sender
{
    [self setDrawsBackground:FALSE];
	[self setBordered:FALSE];
    [self abortEditing];
}

@end