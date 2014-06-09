#import "PRTabButtonCell.h"
#import "NSColor+Extensions.h"
#import "NSBezierPath+Extensions.h"
#import "NSParagraphStyle+Extensions.h"


@implementation PRTabButtonCell

@synthesize rounded = _rounded;

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
    NSRect frame2 = frame;
    frame2.origin.y += 0.5;
    frame2.size.height -= 1;
    frame2.origin.x += 0.5;
    frame2.size.width -= 1;
    
    float radius = _rounded ? 2.0 : 0.0;
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame2 xRadius:_rounded yRadius:_rounded];
    
    // Draw background
    NSGradient *gradient;
    if ([self state] == NSOnState) {
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.85 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.87 alpha:1.0],0.4,
                     [NSColor colorWithCalibratedWhite:0.89 alpha:1.0],1.0, 
                     nil];
    } else if ([self isHighlighted]) {
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.94 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.89 alpha:1.0],0.4,
                     [NSColor colorWithCalibratedWhite:0.85 alpha:1.0],1.0, 
                     nil];
    } else {
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.99 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.94 alpha:1.0],0.4,
                     [NSColor colorWithCalibratedWhite:0.92 alpha:1.0],1.0, 
                     nil];
    }
    [gradient drawInBezierPath:path angle:90.0];
    
    // Draw border
    [[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] set];
    [path stroke];
    
    // Draw Interior
    [self drawInteriorWithFrame:frame inView:view];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
    frame.origin.y -= 2;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    NSDictionary *attr = @{NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue-Bold" size:12],
        NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.10 alpha:1.0],
        NSParagraphStyleAttributeName:[NSParagraphStyle centerAlignStyle],
        NSShadowAttributeName:shadow};
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:[self title] attributes:attr];
    [self setAttributedTitle:attrTitle];
    [super drawInteriorWithFrame:frame inView:view];
}

@end
