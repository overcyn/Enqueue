#import "PRRatingCell.h"

@implementation PRRatingCell {
    BOOL _showDots;
    NSRect _cellFrame;
    BOOL _editing;
}

- (id)init {
    if (!(self = [super init])) {return nil;}
    _showDots = NO;
    _editing = NO;
    return self;
}

@synthesize showDots = _showDots;

- (void)setObjectValue:(id<NSCopying>)obj {
    if (!obj) {
        [super setObjectValue:[NSNumber numberWithInt:0]];
        return;
    }
    [super setObjectValue:obj];
}

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView {
    if ([self objectValue] == nil) {
        return;
    }
    NSImage *icon;
    if (segment == 0) {
        icon = [NSImage imageNamed:@"PREmptyIcon"];
    } else if (segment <= [self selectedSegment]) {
        if (([self isHighlighted] || _editing) && !_showDots) {
            icon = [NSImage imageNamed:@"PRLightRatingIcon"];
        } else {
            icon = [NSImage imageNamed:@"PRRatingIcon"];
        }
    } else {
        if (([self isHighlighted] || _editing) && !_showDots) {
            icon = [NSImage imageNamed:@"PRLightEmptyRatingIcon"];
        } else {
            if (_showDots) {
                icon = [NSImage imageNamed:@"PREmptyRatingIcon"];
            } else {
                icon = [NSImage imageNamed:@"PREmptyIcon"];
            }
        }
    }
    [icon drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self objectValue] == nil) {
        return;
    }
    NSRect frame = NSMakeRect(cellFrame.origin.x + 2, cellFrame.origin.y + 1, 0, 15);
    for (int i = 0; i < [self segmentCount]; i++) {
        frame.size.width = [self widthForSegment:i] + 2;
        [self drawSegment:i inFrame:frame withView:controlView];
        frame.origin.x = frame.origin.x + frame.size.width - 1;
    }
}

- (BOOL)trackMouse:(NSEvent *)event_ inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
    _cellFrame = cellFrame;
    return [super trackMouse:event_ inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {    
    _editing = YES;
    for (int i = 0; i < [self segmentCount]; i++) {
        if (NSPointInRect(startPoint, [self frameForSegment:i])) {
            [self setSelectedSegment:i];
        }
    }
    return [super startTrackingAt:startPoint inView:controlView];
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
    currentPoint.y = [self frameForSegment:0].origin.y + 5;
    if (currentPoint.x <= [self frameForSegment:0].origin.x) {
        currentPoint.x = [self frameForSegment:0].origin.x + 1;
    }
    if (currentPoint.x >= [self frameForSegment:6].origin.x) {
        currentPoint.x = [self frameForSegment:6].origin.x - 1;
    }
    
    for (int i = 0; i < [self segmentCount]; i++) {
        if (NSPointInRect(currentPoint, [self frameForSegment:i])) {
            [self setSelectedSegment:i];
        }
    }
    
    return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
    currentPoint.y = [self frameForSegment:0].origin.y + 5;
    if (currentPoint.x <= [self frameForSegment:0].origin.x) {
        currentPoint.x = [self frameForSegment:0].origin.x + 1;
    }
    if (currentPoint.x >= [self frameForSegment:6].origin.x) {
        currentPoint.x = [self frameForSegment:6].origin.x - 1;
    }
    
    for (int i = 0; i < [self segmentCount]; i++) {
        if (NSPointInRect(currentPoint, [self frameForSegment:i])) {
            [self setObjectValue:[NSNumber numberWithInt:i]];
        }
    }
    
    _editing = NO;
    [super stopTracking:lastPoint at:currentPoint inView:controlView mouseIsUp:flag];
}

- (NSRect)frameForSegment:(BOOL)segment {
    NSRect frame = NSMakeRect(_cellFrame.origin.x + 2, _cellFrame.origin.y + 1, 0, 15);
    for (int i = 0; i < [self segmentCount]; i++) {
        frame.size.width = [self widthForSegment:i] + 2;
        if (i == segment) {
            break;
        }    
        frame.origin.x = frame.origin.x + frame.size.width - 1;
    }
    return frame;
}

@end