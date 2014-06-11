#import "PRScrollView.h"
#import "PRClipView.h"


@implementation PRScrollView {
    NSSize _minimumSize;
}

- (void)awakeFromNib {
    [self setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self];
    [self setContentView:[[PRClipView alloc] init]];
}

- (NSSize)minimumSize {
    return _minimumSize;
}

- (void)setMinimumSize:(NSSize)minimumSize {
    _minimumSize = minimumSize;
    NSRect rect = [self documentVisibleRect];
    NSRect blue = [[self documentView] frame];
    
    [self viewFrameDidChange:nil];
    rect.origin.y += [[self documentView] frame].size.height - blue.size.height;
    [[self documentView] scrollRectToVisible:rect];
}

- (void)viewFrameDidChange:(NSNotification *)notification {
    if ([self documentView] && _minimumSize.width != 0 && _minimumSize.height != 0) {
        NSRect newBounds = [[self documentView] frame];
        
        if ([self contentSize].width > _minimumSize.width) {
            newBounds.size.width = [self contentSize].width;
        } else {
            newBounds.size.width = _minimumSize.width;
        }
        
        if ([self contentSize].height > _minimumSize.height) {
            newBounds.size.height = [self contentSize].height;
        } else {
            newBounds.size.height = _minimumSize.height;
        }
        
        [[self documentView] setFrame:newBounds];
    }
}

@end
