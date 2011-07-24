#import "PRNowPlayingCell.h"


@implementation PRNowPlayingCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)theControlView
{
    cellFrame.origin.x -= 1;
    cellFrame.size.width += 3;
    if ([[[self objectValue] objectForKey:@"showSubtitle"] boolValue]) {
        cellFrame.origin.y -= 1;
        [self drawHeaderWithFrame:cellFrame inView:theControlView];
        return;
    }
	NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
    NSNumber *badge = [dict objectForKey:@"badge"];
	NSImage *icon = [dict objectForKey:@"icon"];
    NSImage *invertedIcon = [dict objectForKey:@"invertedIcon"];
	
    // Icon
	float insetPadding = 6;
    float horizontalPadding = 6;
    NSSize iconSize = NSMakeSize(13, 13);
    NSRect iconRect = NSMakeRect(cellFrame.origin.x + insetPadding, 
                                 cellFrame.origin.y + cellFrame.size.height/2 - iconSize.height/2 - 2, 
                                 iconSize.width, iconSize.height);
    if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isMainWindow]) {
        icon = invertedIcon;
        [icon setFlipped:TRUE];
    }
    [icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    // Badge
    if ([badge intValue] != 0) {
        NSRect badgeRect = NSMakeRect(cellFrame.origin.x + 4, cellFrame.origin.y + 1, 18, 14);
        NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:7 yRadius:7];
        [[NSColor colorWithCalibratedRed:.53 green:.60 blue:.74 alpha:1.0] set];
        [badgePath fill];
        
        NSMutableParagraphStyle *badgeStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [badgeStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [badgeStyle setAlignment:NSCenterTextAlignment];
        NSFont *badgeFont = [NSFont fontWithName:@"Helvetica-Bold" size:11];
        NSDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
        [dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        [dict setValue:badgeFont forKey:NSFontAttributeName];
        [dict setValue:badgeStyle forKey:NSParagraphStyleAttributeName];
        NSAttributedString *badgeAttributedString = [[[NSAttributedString alloc] initWithString:[badge stringValue] attributes:dict] autorelease];
        [badgeAttributedString drawInRect:NSInsetRect(badgeRect, 2, 0)];
    }
	
	// Text
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
	[shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSMutableDictionary *attributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                        [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                                        style, NSParagraphStyleAttributeName,
                                        [NSColor colorWithCalibratedWhite:0.10 alpha:1], NSForegroundColorAttributeName, 
                                        nil] autorelease];
    if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isMainWindow]) {
        [attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    }
    float height = [title sizeWithAttributes:attributes].height;
	NSRect textRect = NSMakeRect(iconRect.origin.x + iconRect.size.width + horizontalPadding,
                                 cellFrame.origin.y + cellFrame.size.height/2 - height/2,
                                 cellFrame.size.width - iconRect.size.width - horizontalPadding - insetPadding*2,
                                 height);
	[title drawInRect:textRect withAttributes:attributes];
}

- (void)drawHeaderWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
	NSString *subtitle = [dict objectForKey:@"subtitle"];
	
	// Text Attributes	
	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
	[shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSColor *color = [NSColor colorWithDeviceRed:90.0/255.0 green:102.0/255.0 blue:118.0/255.0 alpha:1.0];
    NSMutableDictionary *titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             [NSFont boldSystemFontOfSize:11.5], NSFontAttributeName,
                                             style, NSParagraphStyleAttributeName,
                                             color, NSForegroundColorAttributeName,
                                             shadow, NSShadowAttributeName,
                                             nil] autorelease];
    NSMutableDictionary *subtitleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                                                color, NSForegroundColorAttributeName,
                                                shadow, NSShadowAttributeName,
                                                style, NSParagraphStyleAttributeName, 
                                                nil] autorelease];
	
	// Text
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];
	NSSize subtitleSize = [subtitle sizeWithAttributes:subtitleAttributes];
    float height = titleSize.height + subtitleSize.height + 3;
	NSRect textBox = NSMakeRect(cellFrame.origin.x + 7,
                                cellFrame.origin.y + cellFrame.size.height * .5 - height * 0.5,
                                cellFrame.size.width - 7,
                                height);
    NSRect titleBox = NSMakeRect(textBox.origin.x, 
                                 textBox.origin.y + textBox.size.height*.5 - titleSize.height,
                                 textBox.size.width,
                                 titleSize.height);
    NSRect subtitleBox = NSMakeRect(textBox.origin.x,
                                    textBox.origin.y + textBox.size.height*.5,
                                    textBox.size.width,
                                    subtitleSize.height);
	[title drawInRect:titleBox withAttributes:titleAttributes];
    [subtitle drawInRect:subtitleBox withAttributes:subtitleAttributes];
	
	// Background
    [NSBezierPath setDefaultLineWidth:0];
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithCalibratedWhite:0.0 alpha:0.0], 0.0,
                             [NSColor colorWithCalibratedWhite:0.0 alpha:0.2], 0.5,
                             [NSColor colorWithCalibratedWhite:0.0 alpha:0.0], 1.0, nil] autorelease];
    NSRect rect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, 1);
    [gradient drawInRect:rect angle:0];
    gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0.0], 0.0,
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0.4], 0.5,
                 [NSColor colorWithCalibratedWhite:1.0 alpha:0.0], 1.0, nil] autorelease];
    rect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + 1, cellFrame.size.width, 1);
    [gradient drawInRect:rect angle:0];
}

@end