#import "PRNowPlayingCell.h"
#import "PRNowPlayingViewController.h"
#import "NSParagraphStyle+Extensions.h"


@implementation PRNowPlayingCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)theControlView {
	NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
    NSNumber *badge = [dict objectForKey:@"badge"];
	NSImage *icon = [dict objectForKey:@"icon"];
    NSImage *invertedIcon = [dict objectForKey:@"invertedIcon"];
	
    // Icon
	float insetPadding = 0;
    float horizontalPadding = 3;
    NSSize iconSize = NSMakeSize(15, 15);
    NSRect iconRect = NSMakeRect(cellFrame.origin.x + insetPadding + 4,
                                 cellFrame.origin.y + cellFrame.size.height/2 - iconSize.height/2, 
                                 iconSize.width, iconSize.height);
    if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isMainWindow]) {
        icon = invertedIcon;
    }
    [icon setFlipped:TRUE];
        
    // Badge
    if ([badge intValue] != 0) {        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]];
        [shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
        NSColor *badgeColor = [NSColor colorWithDeviceWhite:0.3 alpha:1.0];
        if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isMainWindow]) {
            [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.0]];
            badgeColor = [NSColor whiteColor];
        }
        NSDictionary *attributes = @{NSForegroundColorAttributeName:badgeColor,
            NSFontAttributeName:[NSFont fontWithName:@"Helvetica-Bold" size:12],
            NSParagraphStyleAttributeName:[NSParagraphStyle centerAlignStyle],
            NSShadowAttributeName:shadow};
        NSAttributedString *badgeString = [[[NSAttributedString alloc] initWithString:[badge stringValue] attributes:attributes] autorelease];
        
        NSRect badgeRect = NSMakeRect(cellFrame.origin.x + 2, cellFrame.origin.y + 2, 18, 14);
        [badgeString drawInRect:NSInsetRect(badgeRect, 2, 0)];
    } else {
        [icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
	
	// Text
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
	[shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSColor *color = [NSColor colorWithCalibratedWhite:0.10 alpha:1];
    if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isMainWindow]) {
        color = [NSColor whiteColor];
    }
    NSDictionary *attributes = @{NSFontAttributeName:[NSFont systemFontOfSize:11.0],
        NSParagraphStyleAttributeName:[NSParagraphStyle leftAlignStyle],
        NSForegroundColorAttributeName:color};
    float height = [title sizeWithAttributes:attributes].height;
	NSRect textRect = NSMakeRect(iconRect.origin.x + iconRect.size.width + horizontalPadding,
                                 cellFrame.origin.y + cellFrame.size.height/2 - height/2,
                                 cellFrame.size.width - iconRect.size.width - horizontalPadding - 5,
                                 height);
	[title drawInRect:textRect withAttributes:attributes];
}

@end