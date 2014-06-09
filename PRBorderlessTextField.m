#import "PRBorderlessTextField.h"
#import "NSOperationQueue+Extensions.h"


@implementation PRBorderlessTextField

- (BOOL)becomeFirstResponder {
	if ([self isEditable]) {
		[self setBordered:TRUE];
		[self setDrawsBackground:TRUE];
	}
	return [super becomeFirstResponder];
}

- (void)textDidEndEditing:(NSNotification *)note {
    [super textDidEndEditing:note];
	[self setDrawsBackground:FALSE];
	[self setBordered:FALSE];
	[self validateEditing];
	[self abortEditing];
}

- (void)cancelOperation:(id)sender {
    [self setDrawsBackground:FALSE];
	[self setBordered:FALSE];
    [self abortEditing];
}

@end