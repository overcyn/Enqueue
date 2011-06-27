#import <Cocoa/Cocoa.h>


@interface PRGradientView : NSView
{
    NSColor *color;
    NSColor *alternateColor;
    
    NSGradient *verticalGradient;
    NSGradient *alternateVerticalGradient;
    NSColor *topGradient;
    NSColor *botGradient;
    NSColor *alternateTopGradient;
    NSColor *alternateBotGradient;
    NSColor *topBorder;
    NSColor *botBorder;
    
    NSGradient *horizontalGradient;
    NSGradient *alternateHorizontalGradient;
    NSColor *leftGradient;
    NSColor *rightGradient;
    NSColor *alternateLeftGradient;
    NSColor *alternateRightGradient;
    NSColor *leftBorder;
    NSColor *rightBorder;
}

@property (readwrite, retain) NSColor *color;
@property (readwrite, retain) NSColor *alternateColor;

@property (readwrite, retain) NSGradient *verticalGradient;
@property (readwrite, retain) NSGradient *alternateVerticalGradient;
@property (readwrite, retain) NSColor *topGradient;
@property (readwrite, retain) NSColor *botGradient;
@property (readwrite, retain) NSColor *alternateTopGradient;
@property (readwrite, retain) NSColor *alternateBotGradient;
@property (readwrite, retain) NSColor *topBorder;
@property (readwrite, retain) NSColor *botBorder;

@property (readwrite, retain) NSGradient *horizontalGradient;
@property (readwrite, retain) NSGradient *alternateHorizontalGradient;
@property (readwrite, retain) NSColor *leftGradient;
@property (readwrite, retain) NSColor *rightGradient;
@property (readwrite, retain) NSColor *alternateLeftGradient;
@property (readwrite, retain) NSColor *alternateRightGradient;
@property (readwrite, retain) NSColor *leftBorder;
@property (readwrite, retain) NSColor *rightBorder;

@end
