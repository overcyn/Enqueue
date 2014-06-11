#import "PRWindow.h"
#import <objc/runtime.h>
#import "PRCore.h"
#import "PRNowPlayingController.h"
#import "NSBezierPath+Extensions.h"


@interface PRWindow(hush)
- (float)roundedCornerRadius;
- (void)drawRectOriginal:(NSRect)rect;
- (NSWindow *)window;
@end


@implementation PRWindow

- (void)awakeFromNib {
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
    NSRect controlRect = NSMakeRect(0, windowRect.size.height - 30, windowRect.size.width, 30);
    NSGradient *gradient;
    if ([[self window] isMainWindow]) {
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.92 alpha:1.0], 0.0, 
                     [NSColor colorWithCalibratedWhite:0.65 alpha:1.0], 1.0,
                     nil];
    } else {
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.99 alpha:1.0], 0.0, 
                     [NSColor colorWithCalibratedWhite:0.96 alpha:1.0], 0.3, 
                     [NSColor colorWithCalibratedWhite:0.83 alpha:1.0], 1.0,
                     nil];
    }
    [gradient drawInRect:controlRect angle:-90.0];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.6] set];
    [NSBezierPath fillRect:[NSBezierPath topBorderOfRect:controlRect]];
    [[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
    [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:controlRect]];
}

- (BOOL)_isTitleHidden {
    return YES;
}

- (void)keyDown:(NSEvent *)event{
    BOOL didHandle = NO;
    if ([self delegate] && 
        [[self delegate] respondsToSelector:@selector(window:keyDown:)]) {
        didHandle = [(id<PRWindowDelegate>)[self delegate] window:self keyDown:event];
    }
    if (!didHandle) {
        [super keyDown:event];
    }
}

@end
