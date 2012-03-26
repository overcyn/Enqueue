#import <Cocoa/Cocoa.h>


@interface PRGradientView : NSView {
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
/* Accessors */
@property (readwrite, copy) NSColor *color;
@property (readwrite, copy) NSGradient *horizontalGradient;
@property (readwrite, copy) NSGradient *verticalGradient;
@property (readwrite, copy) NSColor *topGradient;
@property (readwrite, copy) NSColor *botGradient;
@property (readwrite, copy) NSColor *leftGradient;
@property (readwrite, copy) NSColor *rightGradient;

@property (readwrite, copy) NSColor *altColor;
@property (readwrite, copy) NSGradient *altHorizontalGradient;
@property (readwrite, copy) NSGradient *altVerticalGradient;
@property (readwrite, copy) NSColor *altTopGradient;
@property (readwrite, copy) NSColor *altBotGradient;
@property (readwrite, copy) NSColor *altLeftGradient;
@property (readwrite, copy) NSColor *altRightGradient;

@property (readwrite, copy) NSColor *topBorder;
@property (readwrite, copy) NSColor *botBorder;
@property (readwrite, copy) NSColor *leftBorder;
@property (readwrite, copy) NSColor *rightBorder;
@property (readwrite, copy) NSColor *topBorder2;
@property (readwrite, copy) NSColor *botBorder2;
@end
