#import "PRTabButtonCell.h"
#import "NSColor+Extensions.h"
#import "NSBezierPath+Extensions.h"

@implementation PRTabButtonCell

@synthesize rounded = _rounded;

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{    
    NSRect frame2 = frame;
    frame2.origin.y += 0.5;
    frame2.size.height -= 1;
    frame2.origin.x += 0.5;
    frame2.size.width -= 1;
    
    NSBezierPath *path;
    if (!_rounded) {
        path = [NSBezierPath bezierPathWithRoundedRect:frame2 xRadius:0 yRadius:0];
    } else {
        path = [NSBezierPath bezierPathWithRoundedRect:frame2 xRadius:2 yRadius:2];
    }
    
    // Draw background
    NSGradient *gradient;
    if ([self state] == NSOnState) {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.85 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.87 alpha:1.0],0.4,
                     [NSColor colorWithCalibratedWhite:0.89 alpha:1.0],1.0, 
                     nil] autorelease];
    } else if ([self isHighlighted]) {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.94 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.89 alpha:1.0],0.4,
                     [NSColor colorWithCalibratedWhite:0.85 alpha:1.0],1.0, 
                     nil] autorelease];
    } else {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.99 alpha:1.0],0.0,
                     [NSColor colorWithCalibratedWhite:0.94 alpha:1.0],0.4,
                     [NSColor colorWithCalibratedWhite:0.92 alpha:1.0],1.0, 
                     nil] autorelease];
    }
    [gradient drawInBezierPath:path angle:90.0];
    
    // Draw border
    [[NSColor colorWithCalibratedWhite:0.65 alpha:1.0] set];
    [path stroke];
    
    // Draw Interior
    [self drawInteriorWithFrame:frame inView:view];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view
{
    frame.origin.y -= 2;
    NSAttributedString *attrTitle;
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.4]];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSFont fontWithName:@"HelveticaNeue-Bold" size:12], NSFontAttributeName,
                          [NSColor colorWithCalibratedWhite:0.15 alpha:1.0], NSForegroundColorAttributeName,
                          paragraphStyle, NSParagraphStyleAttributeName, 
                          shadow, NSShadowAttributeName, nil];
    attrTitle = [[[NSAttributedString alloc] initWithString:[self title] attributes:attr] autorelease];
    [self setAttributedTitle:attrTitle];
    [super drawInteriorWithFrame:frame inView:view];
}
//- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
//{    
//    if ([self state] == NSOnState) {
//        // Draw border
//        [[NSColor PRTabBorderColor] set];
//        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:frame]];
//        [NSBezierPath fillRect:[NSBezierPath leftBorderOfRect:frame]];
//        [NSBezierPath fillRect:[NSBezierPath rightBorderOfRect:frame]];
//        
//        // Draw background
//        [[NSColor PRForegroundColor] set];
//        [NSBezierPath fillRect:NSInsetRect(frame, 1, 1)];
//        [NSBezierPath fillRect:[NSBezierPath topBorderOfRect:frame]];
//        
//        [[NSColor PRTabBorderHighlightColor] set];
//        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:NSInsetRect(frame, 1, 1)]];
//    } else {
//        NSRect frame2 = frame;
//        frame2.size.height -= 3;
//        frame2.origin.y += 2;
//        
//        // Draw background
//        if ([self isHighlighted]) {
//            [[NSColor PRAltTabDepressedColor] set];
//        } else {
//            [[NSColor PRAltTabColor] set];
//        }
//        [NSBezierPath fillRect:NSInsetRect(frame2, 1, 1)];
//
//        
//        // Draw border
//        [[NSColor PRTabBorderColor] set];
//        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:frame2]];
//        [NSBezierPath fillRect:[NSBezierPath leftBorderOfRect:frame2]];
//        [NSBezierPath fillRect:[NSBezierPath rightBorderOfRect:frame2]];
//        
//        [[NSColor PRAltTabBorderHighlightColor] set];
//        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:NSInsetRect(frame2, 1, 1)]];
//        
//    }
//    
//    // Draw Interior
//    [self drawInteriorWithFrame:frame inView:view];
//}
//
//- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view
//{
//    frame.origin.y -= 2;
//    NSAttributedString *attrTitle;
//    if ([self state] == NSOnState) {
//        NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
//        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
//        [paragraphStyle setAlignment:NSCenterTextAlignment];
//        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
//        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
//        [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
//        NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
//                              [NSFont fontWithName:@"HelveticaNeue-Bold" size:13], NSFontAttributeName,
//                              [NSColor colorWithCalibratedWhite:0.2 alpha:1.0], NSForegroundColorAttributeName,
//                              paragraphStyle, NSParagraphStyleAttributeName, 
//                              shadow, NSShadowAttributeName, nil];
//        attrTitle = [[[NSAttributedString alloc] initWithString:[self title] attributes:attr] autorelease];
//    } else {
//        NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
//        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
//        [paragraphStyle setAlignment:NSCenterTextAlignment];
//        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
//        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.9]];
//        [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
//        NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
//                              [NSFont fontWithName:@"HelveticaNeue-Bold" size:12], NSFontAttributeName,
//                              [NSColor colorWithCalibratedWhite:0.55 alpha:1.0], NSForegroundColorAttributeName,
//                              paragraphStyle, NSParagraphStyleAttributeName, 
//                              shadow, NSShadowAttributeName, nil];
//        attrTitle = [[[NSAttributedString alloc] initWithString:[self title] attributes:attr] autorelease];
//    }
//    [self setAttributedTitle:attrTitle];
//    [super drawInteriorWithFrame:frame inView:view];
//}

@end
