#import "PRBorderlessTextField.h"
#import "NSOperationQueue+Extensions.h"


@implementation PRBorderlessTextField

- (BOOL)becomeFirstResponder {
    if ([self isEditable]) {
        [self setBordered:YES];
        [self setDrawsBackground:YES];
    }
    return [super becomeFirstResponder];
}

- (void)textDidEndEditing:(NSNotification *)note {
    [super textDidEndEditing:note];
    [self setDrawsBackground:NO];
    [self setBordered:NO];
    [self validateEditing];
    [self abortEditing];
}

- (void)cancelOperation:(id)sender {
    [self setDrawsBackground:NO];
    [self setBordered:NO];
    [self abortEditing];
}

@end