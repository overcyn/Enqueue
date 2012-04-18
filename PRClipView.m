#import "PRClipView.h"
#import "NSColor+Extensions.h"


@implementation PRClipView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSBezierPath bezierPathWithRect:dirtyRect] addClip];
    
    // hacky hack. draws elastic portion of scroll view. duplicates drawing of prbackgroundview.
    NSRect rect = NSInsetRect([self bounds],floor([self bounds].size.width - 648 - 1)/2-0.5,0);
    rect.origin.x = floor(rect.origin.x);
    rect.size.width -= 1;
    rect.origin.x += 0.5;
    
    [[NSColor PRForegroundColor] set];
    [NSBezierPath fillRect:rect];
    [[NSColor PRForegroundBorderColor] set];
    [NSBezierPath strokeRect:rect];
}

@end
