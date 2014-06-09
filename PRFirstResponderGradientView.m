#import "PRFirstResponderGradientView.h"


@implementation PRFirstResponderGradientView

- (void)mouseDown:(NSEvent *)theEvent {
    [[self window] makeFirstResponder:nil];
}

@end
