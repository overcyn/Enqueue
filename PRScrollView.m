#import "PRScrollView.h"
#import "NSColor+Extensions.h"


@implementation PRScrollView

- (void)awakeFromNib
{
    [self setPostsFrameChangedNotifications:TRUE];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(viewFrameDidChange:) 
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
    [self setBackgroundColor:[NSColor PRBackgroundColor]];
}

@dynamic minimumSize;

- (NSSize)minimumSize
{
    return minimumSize;
}

- (void)setMinimumSize:(NSSize)minimumSize_
{
    minimumSize = minimumSize_;
    NSRect rect = [self documentVisibleRect];
    NSRect blue = [[self documentView] frame];
    
    [self viewFrameDidChange:nil];
    rect.origin.y += [[self documentView] frame].size.height - blue.size.height;
    [[self documentView] scrollRectToVisible:rect];
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

@end
