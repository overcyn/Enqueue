#import "PRBorderlessTextField.h"


@implementation PRBorderlessTextField

- (void)awakeFromNib
{
	[super awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(textDidEndEditing:)
												 name:NSTextDidEndEditingNotification
											   object:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSTextDidEndEditingNotification 
                                                  object:self];
    [super dealloc];
}

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