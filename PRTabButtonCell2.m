#import "PRTabButtonCell2.h"
#import "NSColor+Extensions.h"
#import "NSBezierPath+Extensions.h"
#import "NSParagraphStyle+Extensions.h"

@implementation PRTabButtonCell2

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view {    
    NSRect frame2 = frame;
    frame2.origin.y += 0.5;
    frame2.size.height -= 1;
    frame2.origin.x += 0.5;
    frame2.size.width -= 1;
    
    NSBezierPath *path;
    if (FALSE) {
        path = [NSBezierPath bezierPathWithRoundedRect:frame2 xRadius:0 yRadius:0];
    } else {
        path = [NSBezierPath bezierPathWithRoundedRect:frame2 xRadius:2 yRadius:2];
    }
    
    [NSGraphicsContext saveGraphicsState];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor redColor]];
    [shadow setShadowBlurRadius:0.0];
    [shadow setShadowOffset:NSMakeSize(0.0, 3.0)];
    [shadow set];
    
    // Draw background
    NSGradient *gradient;
    if ([self isHighlighted]) {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.94 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.89 alpha:1.0],0.4,
                     [NSColor colorWithCalibratedWhite:0.85 alpha:1.0],1.0, 
                     nil] autorelease];
    } else {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.99 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.99 alpha:1.0],0.2,
                     [NSColor colorWithCalibratedWhite:0.92 alpha:1.0], 0.8, 
                     nil] autorelease];
    }
    [gradient drawInBezierPath:path angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    
    // Draw border
    [[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] set];
    [path stroke];
    
    // Draw Interior
    [self drawInteriorWithFrame:frame inView:view];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view {
    frame.origin.y -= 2;
    NSAttributedString *attrTitle;
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.9]];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSFont fontWithName:@"HelveticaNeue-Bold" size:12], NSFontAttributeName,
                          [NSColor colorWithCalibratedWhite:0.15 alpha:1.0], NSForegroundColorAttributeName,
                          [NSParagraphStyle centerAlignStyle], NSParagraphStyleAttributeName,
                          shadow, NSShadowAttributeName, nil];
    attrTitle = [[[NSAttributedString alloc] initWithString:[self title] attributes:attr] autorelease];
    [self setAttributedTitle:attrTitle];
    [super drawInteriorWithFrame:frame inView:view];
}

@end
