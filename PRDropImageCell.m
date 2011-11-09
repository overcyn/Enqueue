#import "PRDropImageCell.h"
#import "PRDropImageView.h"


@implementation PRDropImageCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
    [super drawWithFrame:cellFrame inView:controlView];
    if ([(PRDropImageView *)[self controlView] focusRing] || 
        [self controlView] == [[[self controlView] window] firstResponder]) {
        NSRect focusRingFrame = cellFrame;
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRect:NSInsetRect(focusRingFrame,5,5)] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end