#import "PRWindow.h"
#import <objc/runtime.h>
#import "PRFrameView.h"
#import "PRCore.h"
#import "PRNowPlayingController.h"


@interface PRWindow(hush)
- (float)roundedCornerRadius;
- (void)drawRectOriginal:(NSRect)rect;
- (NSWindow*)window;
@end


@implementation PRWindow

- (void)awakeFromNib {
    [PRFrameView swizzle];
    
    // Get window's frame view class 
    id class = [[[self contentView] superview] class];  
    
    // Add our drawRect: to the frame class 
    Method m0 = class_getInstanceMethod([self class], @selector(themeDrawRect:)); 
    class_addMethod(class, @selector(drawRectOriginal:), method_getImplementation(m0), method_getTypeEncoding(m0));  
    
    // Exchange methods 
    Method m1 = class_getInstanceMethod(class, @selector(drawRect:)); 
    Method m2 = class_getInstanceMethod(class, @selector(drawRectOriginal:)); 
    method_exchangeImplementations(m1, m2);
    [super awakeFromNib];
}

- (void)themeDrawRect:(NSRect)rect {
	[self drawRectOriginal:rect];

    // Clip corner
    NSRect windowRect = [[self window] frame];
    windowRect.origin = NSMakePoint(0, 0);
    float cornerRadius = [self roundedCornerRadius];
    [[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:cornerRadius yRadius:cornerRadius] addClip];
    
    // Fill
    if ([[self window] isMainWindow]) {
        NSRect controlRect = NSMakeRect(0, windowRect.size.height - 30, windowRect.size.width, 30);
        NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.92 alpha:1.0], 0.0, 
                                 [NSColor colorWithCalibratedWhite:0.65 alpha:1.0], 1.0,
                                 nil] autorelease];
        [gradient drawInRect:controlRect angle:-90.0];
    } else {
        NSRect controlRect = NSMakeRect(0, windowRect.size.height - 30, windowRect.size.width, 30);
        NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithCalibratedWhite:0.99 alpha:1.0], 0.0, 
                                 [NSColor colorWithCalibratedWhite:0.96 alpha:1.0], 0.3, 
                                 [NSColor colorWithCalibratedWhite:0.83 alpha:1.0], 1.0,
                                 nil] autorelease];
        [gradient drawInRect:controlRect angle:-90.0];
    }
}

- (void)updateTrackingArea {
    if (_trackingArea) {
        [[[[self window] contentView] superview] removeTrackingArea:_trackingArea];
        [_trackingArea release];
    }
    NSRect trackingRect = [[self standardWindowButton:NSWindowCloseButton] frame];
    trackingRect.size.width = NSMaxX([[self standardWindowButton:NSWindowZoomButton] frame]) - NSMinX(trackingRect);
    _trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
                                                 options:(NSTrackingMouseEnteredAndExited |
                                                          NSTrackingActiveAlways)
                                                   owner:self
                                                userInfo:nil];
    [[[[self window] contentView] superview] addTrackingArea:_trackingArea];
}

// Update our buttons so that they highlight correctly.
- (void)mouseEntered:(NSEvent*)event {
    _entered = YES;
//    [closeButton_ setNeedsDisplay];
//    [zoomButton_ setNeedsDisplay];
//    [miniaturizeButton_ setNeedsDisplay];
}

// Update our buttons so that they highlight correctly.
- (void)mouseExited:(NSEvent*)event {
    _entered = NO;
//    [closeButton_ setNeedsDisplay];
//    [zoomButton_ setNeedsDisplay];
//    [miniaturizeButton_ setNeedsDisplay];
}

- (BOOL)mouseInGroup:(NSButton*)widget {
    return _entered;
}

- (BOOL)_isTitleHidden {
    return TRUE;
}

- (void)keyDown:(NSEvent *)event{
    BOOL didHandle = FALSE;
    if ([self delegate] && 
        [[self delegate] respondsToSelector:@selector(window:keyDown:)]) {
        didHandle = [(id<PRWindowDelegate>)[self delegate] window:self keyDown:event];
    }
    if (!didHandle) {
        [super keyDown:event];
    }
}

@end
