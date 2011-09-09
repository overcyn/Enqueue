#import "PRDropImageCell.h"
#import "PRDropImageView.h"

@implementation PRDropImageCell

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
    [super drawWithFrame:cellFrame inView:controlView];
    if ([(PRDropImageView *)[self controlView] focusRing]) {
        NSRect focusRingFrame = cellFrame;
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRect:NSInsetRect(focusRingFrame,5,5)] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end