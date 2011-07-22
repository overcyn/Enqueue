#import "PRGradientView.h"


@implementation PRGradientView

@synthesize color;
@synthesize alternateColor;

@synthesize verticalGradient;
@synthesize alternateVerticalGradient;
@synthesize topGradient;
@synthesize botGradient;
@synthesize topBorder;
@synthesize botBorder;
@synthesize alternateTopGradient;
@synthesize alternateBotGradient;

@synthesize horizontalGradient;
@synthesize alternateHorizontalGradient;
@synthesize leftGradient;
@synthesize rightGradient;
@synthesize alternateLeftGradient;
@synthesize alternateRightGradient;
@synthesize leftBorder;
@synthesize rightBorder;


- (id)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}

- (void)awakeFromNib
{
}

- (void)drawRect:(NSRect)rect
{   
    NSRect bounds = [self bounds];
//    bounds.origin.x -= 0.5;
//    bounds.origin.y -= 0.5;
//    bounds.size.width += 1;
//    bounds.size.height += 1;
    
    
    NSColor *tempColor = color;
    NSGradient *tempVerticalGradient = verticalGradient;
    NSGradient *tempHorizontalGradient = horizontalGradient;
    NSColor *tempTopGradient = topGradient;
    NSColor *tempBotGradient = botGradient;
    NSColor *tempLeftGradient = leftGradient;
    NSColor *tempRightGradient = rightGradient;
    
    [NSBezierPath setDefaultLineWidth:1.0];
    
    if (![[self window] isMainWindow]) {
        if (alternateColor) {
            tempColor = alternateColor;
        }
        if (alternateVerticalGradient) {
            tempVerticalGradient = alternateVerticalGradient;
        }
        if (alternateHorizontalGradient) {
            tempHorizontalGradient = alternateHorizontalGradient;
        }
        if (alternateTopGradient) {
            tempTopGradient = alternateTopGradient;
        }
        if (alternateBotGradient) {
            tempBotGradient = alternateBotGradient;
        }
        if (alternateLeftGradient) {
            tempLeftGradient = alternateLeftGradient;
        }
        if (alternateRightGradient) {
            tempRightGradient = alternateRightGradient;
        }
    }

    if (tempColor) {
        [tempColor set];
        [NSBezierPath fillRect:rect];
    } 
    if (tempVerticalGradient) {
        [tempVerticalGradient drawInRect:bounds angle:-90.0];
    }
    if (tempHorizontalGradient) {
        [tempHorizontalGradient drawInRect:bounds angle:0.0];
    }
    if (tempTopGradient && tempBotGradient) {
        NSGradient *gradient_ = [[[NSGradient alloc] initWithStartingColor:tempTopGradient 
                                                               endingColor:tempBotGradient] autorelease];
        [gradient_ drawInRect:bounds angle:-90.0];
    }
    if (tempLeftGradient && tempRightGradient) {
        NSGradient *gradient_ = [[[NSGradient alloc] initWithStartingColor:tempLeftGradient 
                                                               endingColor:tempRightGradient] autorelease];
        [gradient_ drawInRect:bounds angle:0.0];
    }
    if (botBorder) {
        [botBorder set];
        NSPoint p1;
        p1.x = bounds.origin.x;
        p1.y = bounds.origin.y + 0.5;
        NSPoint p2;
        p2.x = bounds.origin.x + bounds.size.width;
        p2.y = bounds.origin.y + 0.5;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    if (topBorder) {
        [topBorder set];
        NSPoint p1;
        p1.x = bounds.origin.x;
        p1.y = bounds.origin.y + bounds.size.height - 0.5;
        NSPoint p2;
        p2.x = bounds.origin.x + bounds.size.width;
        p2.y = bounds.origin.y + bounds.size.height - 0.5;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    if (leftBorder) {
        [leftBorder set];
        NSPoint p1;
        p1.x = bounds.origin.x;
        p1.y = bounds.origin.y;
        NSPoint p2;
        p2.x = bounds.origin.x;
        p2.y = bounds.origin.y + bounds.size.height;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    if (rightBorder) {
        [rightBorder set];
        NSPoint p1;
        p1.x = bounds.origin.x + bounds.size.width;
        p1.y = bounds.origin.y;
        NSPoint p2;
        p2.x = bounds.origin.x + bounds.size.width;
        p2.y = bounds.origin.y + bounds.size.height;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
}


@end
