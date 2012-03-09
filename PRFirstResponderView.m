#import "PRFirstResponderView.h"

@implementation PRFirstResponderView

- (BOOL)acceptsFirstResponder
{
    return TRUE;
}

- (BOOL)becomeFirstResponder
{
    return TRUE;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self window] makeFirstResponder:self];
}

@end
