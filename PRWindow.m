#import "PRWindow.h"
#import <objc/runtime.h>

@interface PRWindow(hush)
- (float)roundedCornerRadius;
- (void)drawRectOriginal:(NSRect)rect;
- (NSWindow*)window;
@end

@implementation PRWindow

- (void)awakeFromNib
{
    // Get window's frame view class 
    id class = [[[self contentView] superview] class];  
    
    // Add our drawRect: to the frame class 
    Method m0 = class_getInstanceMethod([self class], @selector(themeDrawRect:)); 
    class_addMethod(class, @selector(drawRectOriginal:), method_getImplementation(m0), method_getTypeEncoding(m0));  
    
    // Exchange methods 
    Method m1 = class_getInstanceMethod(class, @selector(drawRect:)); 
    Method m2 = class_getInstanceMethod(class, @selector(drawRectOriginal:)); 
    method_exchangeImplementations(m1, m2);
}

- (void)themeDrawRect:(NSRect)rect
{
	// Call original drawing method
	[self drawRectOriginal:rect];
    
    if (![[self window] isMainWindow]) {
        return;
    }
    
	//
	// Build clipping path : intersection of frame clip (bezier path with rounded corners) and rect argument
	//
    NSRect windowRect = [[self window] frame];
    float cornerRadius = [self roundedCornerRadius];
    windowRect.origin = NSMakePoint(0, 0);
    [[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:cornerRadius yRadius:cornerRadius] addClip];
    
//	[[NSBezierPath bezierPathWithRect:rect] addClip];
    
    
//    NSRect tempRect = NSMakeRect(0, windowRect.size.height - 60, windowRect.size.width, 60);
//    NSGradient *gradient2 = [[[NSGradient alloc] initWithColorsAndLocations:
//                             [NSColor colorWithCalibratedWhite:0.99 alpha:1.0], 0.0,
//                             [NSColor colorWithCalibratedWhite:0.97 alpha:1.0], 0.2,
//                             [NSColor colorWithCalibratedWhite:0.92 alpha:1.0], 0.5,
//                             [NSColor colorWithCalibratedWhite:0.82 alpha:1.0], 1.0,
//                             nil] autorelease];
//    [gradient2 drawInRect:tempRect angle:-90.0];
    
    
    NSRect controlRect = NSMakeRect(0, windowRect.size.height - 26, 185, 26);
//    [[NSBezierPath bezierPathWithRoundedRect:controlRect xRadius:cornerRadius yRadius:cornerRadius] addClip];
    
    NSGradient *gradient_ = [[[NSGradient alloc] initWithColorsAndLocations:
                              [NSColor colorWithCalibratedWhite:0.87 alpha:1.0], 0.0, 
                              [NSColor colorWithCalibratedWhite:0.8 alpha:1.0], 0.3, 
                              [NSColor colorWithCalibratedWhite:0.7 alpha:1.0], 1.0,
                              nil] autorelease];
    [gradient_ drawInRect:controlRect angle:-90.0];
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithCalibratedWhite:1.0 alpha:0.1], 0.0, 
                             [NSColor colorWithCalibratedWhite:1.0 alpha:0], 0.2,
                             [NSColor colorWithCalibratedWhite:1.0 alpha:0], 0.8,
                             [NSColor colorWithCalibratedWhite:1.0 alpha:0.1], 1.0,
                             nil] autorelease];
    [gradient drawInRect:controlRect angle:0.0];
    
//    NSBezierPath *rightCurve = [NSBezierPath bezierPath];
//    [rightCurve appendBezierPathWithArcWithCenter:NSMakePoint(185 - cornerRadius, windowRect.size.height - cornerRadius)
//                                           radius:cornerRadius-.3
//                                       startAngle:90.0
//                                         endAngle:0.0 
//                                        clockwise:TRUE];
//    [[NSColor lightGrayColor] set];
//    [rightCurve setLineWidth:1.0];
//    [rightCurve stroke];
    
    
    // left border
    [[NSColor colorWithDeviceWhite:0.98 alpha:1.0] set];
    NSPoint p1;
    p1.x = windowRect.origin.x;
    p1.y = windowRect.origin.y + windowRect.size.height;
    NSPoint p2;
    p2.x = windowRect.origin.x + windowRect.size.width;
    p2.y = windowRect.origin.y + windowRect.size.height;
    [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];

}


@end
