#import "PRGradientView.h"
#import "NSBezierPath+Extensions.h"


@implementation PRGradientView {
    NSColor *_color;
    NSGradient *_horizontalGradient;
    NSGradient *_verticalGradient;
    NSColor *_topGradient;
    NSColor *_botGradient;
    NSColor *_leftGradient;
    NSColor *_rightGradient;
    
    NSColor *_altColor;
    NSGradient *_altHorizontalGradient;
    NSGradient *_altVerticalGradient;
    NSColor *_altTopGradient;
    NSColor *_altBotGradient;
    NSColor *_altLeftGradient;
    NSColor *_altRightGradient;
    
    NSColor *_topBorder;
    NSColor *_botBorder;
    NSColor *_leftBorder;
    NSColor *_rightBorder;
    NSColor *_topBorder2;
    NSColor *_botBorder2;
}

- (void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
    [center addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];
}

#pragma mark - Properties

@synthesize color = _color;
@synthesize horizontalGradient = _horizontalGradient;
@synthesize verticalGradient = _verticalGradient;
@synthesize topGradient = _topGradient;
@synthesize botGradient = _botGradient;
@synthesize leftGradient = _leftGradient;
@synthesize rightGradient = _rightGradient;

@synthesize altColor = _altColor;
@synthesize altHorizontalGradient = _altHorizontalGradient;
@synthesize altVerticalGradient = _altVerticalGradient;
@synthesize altTopGradient = _altTopGradient;
@synthesize altBotGradient = _altBotGradient;
@synthesize altLeftGradient = _altLeftGradient;
@synthesize altRightGradient = _altRightGradient;

@synthesize topBorder = _topBorder;
@synthesize botBorder = _botBorder;
@synthesize leftBorder = _leftBorder;
@synthesize rightBorder = _rightBorder;
@synthesize topBorder2 = _topBorder2;
@synthesize botBorder2 = _botBorder2;

#pragma mark - NSView

- (void)viewWillMoveToWindow:(NSWindow *)window {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [center removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if (window) {
        [center addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:window];
        [center addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:window];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
        
    NSColor *tempColor = _color;
    NSGradient *tempVerticalGradient = _verticalGradient;
    NSGradient *tempHorizontalGradient = _horizontalGradient;
    NSColor *tempTopGradient = _topGradient;
    NSColor *tempBotGradient = _botGradient;
    NSColor *tempLeftGradient = _leftGradient;
    NSColor *tempRightGradient = _rightGradient;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    if (![[self window] isMainWindow]) {
        if (_altColor) {
            tempColor = _altColor;
        }
        if (_altVerticalGradient) {
            tempVerticalGradient = _altVerticalGradient;
        }
        if (_altHorizontalGradient) {
            tempHorizontalGradient = _altHorizontalGradient;
        }
        if (_altTopGradient) {
            tempTopGradient = _altTopGradient;
        }
        if (_altBotGradient) {
            tempBotGradient = _altBotGradient;
        }
        if (_altLeftGradient) {
            tempLeftGradient = _altLeftGradient;
        }
        if (_altRightGradient) {
            tempRightGradient = _altRightGradient;
        }
    }

    if (tempColor) {
        [tempColor set];
        [NSBezierPath fillRect:bounds];
    } 
    if (tempVerticalGradient) {
        [tempVerticalGradient drawInRect:bounds angle:-90.0];
    }
    if (tempHorizontalGradient) {
        [tempHorizontalGradient drawInRect:bounds angle:0.0];
    }
    if (tempTopGradient && tempBotGradient) {
        NSGradient *gradient_ = [[NSGradient alloc] initWithStartingColor:tempTopGradient endingColor:tempBotGradient];
        [gradient_ drawInRect:bounds angle:-90.0];
    }
    if (tempLeftGradient && tempRightGradient) {
        NSGradient *gradient_ = [[NSGradient alloc] initWithStartingColor:tempLeftGradient endingColor:tempRightGradient];
        [gradient_ drawInRect:bounds angle:0.0];
    }
    if (_botBorder2) {
        [_botBorder2 set];
        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:NSInsetRect(bounds, 0, 1)]];
    }
    if (_topBorder2) {
        [_topBorder2 set];
        [NSBezierPath fillRect:[NSBezierPath topBorderOfRect:NSInsetRect(bounds, 0, 1)]];
    }
    if (_leftBorder) {
        [_leftBorder set];
        [NSBezierPath fillRect:[NSBezierPath leftBorderOfRect:bounds]];
    }
    if (_rightBorder) {
        [_rightBorder set];
        [NSBezierPath fillRect:[NSBezierPath rightBorderOfRect:bounds]];
    }
    if (_botBorder) {
        [_botBorder set];
        [NSBezierPath fillRect:[NSBezierPath botBorderOfRect:bounds]];
    }
    if (_topBorder) {
        [_topBorder set];
        [NSBezierPath fillRect:[NSBezierPath topBorderOfRect:bounds]];
    }
}

#pragma mark - Notification

- (void)windowDidBecomeMain:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

@end
