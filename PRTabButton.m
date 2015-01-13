#import "PRTabButton.h"

@implementation PRTabButton

- (void)mouseDown:(NSEvent *)theEvent {
    if ([self state] != NSOnState) {
        [super mouseDown:theEvent];
    }
}

@end
