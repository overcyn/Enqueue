#import "PRScrollView.h"


@implementation PRScrollView

@synthesize minimumSize;

- (void)awakeFromNib
{
    [self setPostsFrameChangedNotifications:TRUE];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(viewFrameDidChange:) 
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
    [self setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"body-bg.png"]]];
//    [self setBackgroundColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];

}


- (void)viewFrameDidChange:(NSNotification *)notification
{
    if ([self documentView] && minimumSize.width != 0 && minimumSize.height != 0) {
        NSRect newBounds = [[self documentView] frame];
        
        if ([self contentSize].width > minimumSize.width) {
            newBounds.size.width = [self contentSize].width;
        } else {
            newBounds.size.width = minimumSize.width;
        }
        
        if ([self contentSize].height > minimumSize.height) {
            newBounds.size.height = [self contentSize].height;
        } else {
            newBounds.size.height = minimumSize.height;
        }
        
        [[self documentView] setFrame:newBounds];
    }
}


// this doesnt work
//- (void)drawRect:(NSRect)dirtyRect
//{
//    float yOffset = NSMaxY([self convertRect:[self frame] toView:nil]);
//    [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0,yOffset)];
//    [super drawRect:dirtyRect];
//}

@end
