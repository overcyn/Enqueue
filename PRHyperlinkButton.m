#import "PRHyperlinkButton.h"


@implementation PRHyperlinkButton

@dynamic attrString;
@dynamic altAttrString;

- (void)setAttrString:(NSAttributedString *)attrString {
    if (attrString == _attrString) {
        return;
    }
    _attrString = attrString;
    
    [[self window] invalidateCursorRectsForView:self];
    [self updateTrackingAreas];
}

- (NSAttributedString *)attrString {
    return _attrString;
}

- (void)setAltAttrString:(NSAttributedString *)altAttrString {
    if (altAttrString == _altAttrString) {
        return;
    }
    _altAttrString = altAttrString;
    
    [[self window] invalidateCursorRectsForView:self];
    [self updateTrackingAreas];
}

- (NSAttributedString *)altAttrString {
    return _altAttrString;
}

- (void)awakeFromNib {
    [self updateTrackingAreas];
}

- (void)updateTrackingAreas {
    if (_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
    
    NSRect rect = [self titleRect];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:rect
                                                 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow  
                                                   owner:self 
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
    
    CGRect r = CGRectZero;
    r.origin = [NSEvent mouseLocation];
    r = [[self window] convertRectFromScreen:r];
    
    if (NSPointInRect([self convertPointFromBacking:r.origin], rect)) {
        [self mouseEntered:nil];
    } else {
        [self mouseExited:nil];
    }
}

- (void)resetCursorRects {
    [self addCursorRect:NSIntersectionRect([self titleRect],[self bounds]) cursor:[NSCursor pointingHandCursor]];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [self setAttributedTitle:_altAttrString];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [self setAttributedTitle:_attrString];
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSRect rect = [self titleRect];
    
    CGRect r = CGRectZero;
    r.origin = [NSEvent mouseLocation];
    r = [[self window] convertRectFromScreen:r];

    if (NSPointInRect([self convertPointFromBacking:r.origin], rect)) {
        [super mouseDown:theEvent];
    }
}

- (NSRect)titleRect {
    NSRect rect = [[self attributedTitle] boundingRectWithSize:[self bounds].size options:0];
    rect.size.height = [self bounds].size.height;
    rect.origin.y = 0;
    
    if ([[self attributedTitle] length] <= 0) {
        return rect;
    }
    NSDictionary *attributes = [[self attributedTitle] attributesAtIndex:0 effectiveRange:nil];
    NSParagraphStyle *style = [attributes objectForKey:NSParagraphStyleAttributeName];
    if (style && [style alignment] == NSCenterTextAlignment) {
        rect.origin.x = [self bounds].size.width/2 - rect.size.width/2;
    }
    return rect;
}

@end
