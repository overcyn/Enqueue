#import <Cocoa/Cocoa.h>


// View that draws gradients and borders
@interface PRGradientView : NSView
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
