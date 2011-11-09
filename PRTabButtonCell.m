#import "PRTabButtonCell.h"
#import "NSColor+Extensions.h"
#import "NSBezierPath+Extensions.h"

@implementation PRTabButtonCell

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{    
    if ([self state] == NSOnState) {
        // Draw border
        [[NSColor PRTabBorderColor] set];
        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:frame]];
        [NSBezierPath fillRect:[NSBezierPath leftBorderOfRect:frame]];
        [NSBezierPath fillRect:[NSBezierPath rightBorderOfRect:frame]];
        
        // Draw background
        [[NSColor PRForegroundColor] set];
        [NSBezierPath fillRect:NSInsetRect(frame, 1, 1)];
        [NSBezierPath fillRect:[NSBezierPath topBorderOfRect:frame]];
        
        [[NSColor PRTabBorderHighlightColor] set];
        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:NSInsetRect(frame, 1, 1)]];
    } else {
        NSRect frame2 = frame;
        frame2.size.height -= 3;
        frame2.origin.y += 2;
        
        // Draw background
        if ([self isHighlighted]) {
            [[NSColor PRAltTabDepressedColor] set];
        } else {
            [[NSColor PRAltTabColor] set];
        }
        [NSBezierPath fillRect:NSInsetRect(frame2, 1, 1)];

        
        // Draw border
        [[NSColor PRTabBorderColor] set];
        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:frame2]];
        [NSBezierPath fillRect:[NSBezierPath leftBorderOfRect:frame2]];
        [NSBezierPath fillRect:[NSBezierPath rightBorderOfRect:frame2]];
        
        [[NSColor PRAltTabBorderHighlightColor] set];
        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:NSInsetRect(frame2, 1, 1)]];
        
    }
    
    // Draw Interior
    [self drawInteriorWithFrame:frame inView:view];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view
{
    frame.origin.y -= 2;
    NSAttributedString *attrTitle;
    if ([self state] == NSOnState) {
        NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
        [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSFont fontWithName:@"HelveticaNeue-Bold" size:13], NSFontAttributeName,
                              [NSColor colorWithCalibratedWhite:0.2 alpha:1.0], NSForegroundColorAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, 
                              shadow, NSShadowAttributeName, nil];
        attrTitle = [[[NSAttributedString alloc] initWithString:[self title] attributes:attr] autorelease];
    } else {
        NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.9]];
        [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSFont fontWithName:@"HelveticaNeue-Bold" size:12], NSFontAttributeName,
                              [NSColor colorWithCalibratedWhite:0.55 alpha:1.0], NSForegroundColorAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName, 
                              shadow, NSShadowAttributeName, nil];
        attrTitle = [[[NSAttributedString alloc] initWithString:[self title] attributes:attr] autorelease];
    }
    [self setAttributedTitle:attrTitle];
    [super drawInteriorWithFrame:frame inView:view];
}

@end
