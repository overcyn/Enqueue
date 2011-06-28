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

- (void)drawRect:(NSRect)rect
{   
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
        [tempVerticalGradient drawInRect:[self bounds] angle:-90.0];
    }
    if (tempHorizontalGradient) {
        [tempHorizontalGradient drawInRect:[self bounds] angle:0.0];
    }
    if (tempTopGradient && tempBotGradient) {
        NSGradient *gradient_ = [[[NSGradient alloc] initWithStartingColor:tempTopGradient 
                                                               endingColor:tempBotGradient] autorelease];
        [gradient_ drawInRect:[self bounds] angle:-90.0];
    }
    if (tempLeftGradient && tempRightGradient) {
        NSGradient *gradient_ = [[[NSGradient alloc] initWithStartingColor:tempLeftGradient 
                                                               endingColor:tempRightGradient] autorelease];
        [gradient_ drawInRect:[self bounds] angle:0.0];
    }
    if (botBorder) {
        [botBorder set];
        NSPoint p1;
        p1.x = [self bounds].origin.x;
        p1.y = [self bounds].origin.y;
        NSPoint p2;
        p2.x = [self bounds].origin.x + [self bounds].size.width;
        p2.y = [self bounds].origin.y;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    if (topBorder) {
        [topBorder set];
        NSPoint p1;
        p1.x = [self bounds].origin.x;
        p1.y = [self bounds].origin.y + [self bounds].size.height;
        NSPoint p2;
        p2.x = [self bounds].origin.x + [self bounds].size.width;
        p2.y = [self bounds].origin.y + [self bounds].size.height;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    if (leftBorder) {
        [leftBorder set];
        NSPoint p1;
        p1.x = [self bounds].origin.x;
        p1.y = [self bounds].origin.y;
        NSPoint p2;
        p2.x = [self bounds].origin.x;
        p2.y = [self bounds].origin.y + [self bounds].size.height;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    if (rightBorder) {
        [rightBorder set];
        NSPoint p1;
        p1.x = [self bounds].origin.x + [self bounds].size.width;
        p1.y = [self bounds].origin.y;
        NSPoint p2;
        p2.x = [self bounds].origin.x + [self bounds].size.width;
        p2.y = [self bounds].origin.y + [self bounds].size.height;
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
}


@end
