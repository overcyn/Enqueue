#import "PRHeaderBox.h"

@implementation PRHeaderBox

@synthesize trackingDelegate = _trackingDelegate;

- (void)updateTrackingAreas {
    if (!_trackingDelegate || ![_trackingDelegate respondsToSelector:@selector(updateTrackingAreas)]) {
        return;
    }
    [_trackingDelegate updateTrackingAreas];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect frame = NSInsetRect([self bounds], 2, 2);
    [NSGraphicsContext saveGraphicsState];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:4 yRadius:4];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow setShadowBlurRadius:1];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.3]];    
    [shadow set];
    
    // outer shadow
    [[NSColor yellowColor] set];
    [path fill];
    
    // fill
    NSColor *color = [NSColor colorWithDeviceRed:218./255. green:223./255. blue:230./255. alpha:1.0];
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
                             [color blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]], 0.0,
                             [color blendedColorWithFraction:0.2 ofColor:[NSColor blackColor]], 1.0, nil];
    [gradient drawInBezierPath:path angle:-90.0];
    
    // border
    shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow setShadowBlurRadius:1];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.3]];    
    [shadow set];
    
    [path addClip];
    
    [[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
    [path stroke];
    [NSGraphicsContext restoreGraphicsState];
//    [super drawRect:dirtyRect];
}

@end
