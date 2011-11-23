#import "PRTexturedView.h"


@implementation PRTexturedView

- (BOOL)acceptsFirstResponder
{
    return TRUE;
}

- (BOOL)becomeFirstResponder
{
    return TRUE;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self window] makeFirstResponder:self];
}

- (void)drawRect:(NSRect)dirtyRect
{
//    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"PRBackgroundPattern"]] set];
//    [NSBezierPath fillRect:dirtyRect];
    
    [[NSColor colorWithDeviceWhite:0.6 alpha:1.0] set];
    NSBezierPath *path = [[[NSBezierPath alloc] init] autorelease];
    [path moveToPoint:NSMakePoint([self frame].origin.x, [self frame].origin.y + [self frame].size.height)];
    [path lineToPoint:NSMakePoint([self frame].origin.x + [self frame].size.width, [self frame].origin.y + [self frame].size.height)];
    [path stroke];
}

@end
