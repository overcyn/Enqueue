#import "PRNowPlayingCell.h"


@implementation PRNowPlayingCell

- (void)drawWithFrame:(NSRect)theCellFrame inView:(NSView *)theControlView
{
	NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
	NSString *subtitle = [dict objectForKey:@"subtitle"];
	BOOL showSubtitle = [[dict objectForKey:@"showSubtitle"] boolValue];

    NSNumber *badge = [dict objectForKey:@"badge"];
	NSImage *icon = [dict objectForKey:@"icon"];
	NSImage *invertedIcon = [dict objectForKey:@"invertedIcon"];
	NSSize iconSize = [icon size];

	[icon setFlipped:YES];
	
	// Make attributes for our strings	
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
	[shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSMutableDictionary *titleAttributes;
	NSMutableDictionary *subtitleAttributes;
	if (!showSubtitle) {
		titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                            [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                            paragraphStyle, NSParagraphStyleAttributeName,
                            [NSColor colorWithCalibratedWhite:0.10 alpha:1], NSForegroundColorAttributeName,
                            nil] autorelease];
		subtitleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                               [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                               paragraphStyle, NSParagraphStyleAttributeName,
                               nil] autorelease];
		
		if ([self isHighlighted] &&
			[self controlView] == [[[self controlView] window] firstResponder] &&
			[[[self controlView] window] isMainWindow]) {
			[titleAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			icon = invertedIcon;
		}
		
	} else {
		titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                            [NSFont boldSystemFontOfSize:11.5], NSFontAttributeName,
                            paragraphStyle, NSParagraphStyleAttributeName,
                            [NSColor colorWithDeviceRed:90.0/255.0 green:102.0/255.0 blue:118.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                            shadow, NSShadowAttributeName,
                            nil] autorelease];
		subtitleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                               [NSFont systemFontOfSize:11.5], NSFontAttributeName,
                               paragraphStyle, NSParagraphStyleAttributeName,
                               [NSColor colorWithDeviceRed:90.0/255.0 green:102.0/255.0 blue:118.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                               shadow, NSShadowAttributeName,
                               nil] autorelease];
	}
	
	// Icon box: center the icon vertically inside of the inset rect
	// Inset the cell frame to give everything a little horizontal padding
	NSRect insetRect = NSInsetRect(theCellFrame, 5, 0);
	NSRect iconBox = NSMakeRect(insetRect.origin.x,
                                insetRect.origin.y + insetRect.size.height*.5 - iconSize.height*.5 + 1,
                                iconSize.width, iconSize.height);
    
    
    // Draw Badge
    NSRect badgeRect = NSMakeRect(insetRect.origin.x - 2, insetRect.origin.y + 1, 18, 14);
    NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:7 yRadius:7];
//    BOOL isWindowFront = [[NSApp mainWindow] isVisible];
//    BOOL isViewInFocus = [[[[self controlView] window] firstResponder] isEqual:[self controlView]];
//    BOOL isCellHighlighted = [self isHighlighted];
    if ([badge intValue] != 0) {
        [[NSColor colorWithCalibratedRed:.53 green:.60 blue:.74 alpha:1.0] set];
        [badgePath fill];
        
        NSMutableParagraphStyle *paragraphStyle2 = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [paragraphStyle2 setLineBreakMode:NSLineBreakByTruncatingTail];
        [paragraphStyle2 setAlignment:NSCenterTextAlignment];
        NSFont *badgeFont = [NSFont fontWithName:@"Helvetica-Bold" size:11];
        NSDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
        [dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        [dict setValue:badgeFont forKey:NSFontAttributeName];
        [dict setValue:paragraphStyle2 forKey:NSParagraphStyleAttributeName];
        NSAttributedString *badgeAttributedString = [[[NSAttributedString alloc] initWithString:[badge stringValue] attributes:dict] autorelease];
        [badgeAttributedString drawInRect:NSInsetRect(badgeRect, 2, 0)];
    }
    
    
	
	// Vertical padding between the lines of text 	
	// Horizontal padding between icon and text
	float verticalPadding = 4.0;
	float horizontalPadding = 3;
	
	// Text boxes
	float aCombinedHeight;
	NSRect aTextBox;
	NSRect aTitleBox;
	NSRect aSubtitleBox;
	
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];
	NSSize subtitleSize = [subtitle sizeWithAttributes:subtitleAttributes];

	if (showSubtitle) {
		aCombinedHeight = titleSize.height + subtitleSize.height + verticalPadding;
	} else {
		aCombinedHeight = titleSize.height;
	}
	
	aTextBox = NSMakeRect(iconBox.origin.x + iconBox.size.width + horizontalPadding,
						  insetRect.origin.y + insetRect.size.height * .5 - aCombinedHeight * .5,
						  insetRect.size.width - iconSize.width - horizontalPadding,
						  aCombinedHeight);
	
	if (showSubtitle) {
		aTitleBox = NSMakeRect(aTextBox.origin.x, 
							   aTextBox.origin.y + aTextBox.size.height*.5 - titleSize.height,
							   aTextBox.size.width,
							   titleSize.height);
		
		aSubtitleBox = NSMakeRect(aTextBox.origin.x,
								  aTextBox.origin.y + aTextBox.size.height*.5,
								  aTextBox.size.width,
								  subtitleSize.height);		
	} else {
		aTitleBox = aTextBox;
        aTitleBox.origin.x += 3;
        aTitleBox.size.width -= 3;
	}
	
	// draw background
	if (showSubtitle) {
		theCellFrame.size.width = theCellFrame.size.width + 3;
		theCellFrame.size.height = theCellFrame.size.height + 1;
		theCellFrame.origin.x = theCellFrame.origin.x - 1;
		theCellFrame.origin.y = theCellFrame.origin.y - 1.5;
		
		[[NSColor colorWithCalibratedWhite:0.4 alpha:0.5] set];
		[NSBezierPath setDefaultLineWidth:0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(theCellFrame.origin.x, theCellFrame.origin.y + 1) 
								  toPoint:NSMakePoint(theCellFrame.origin.x + theCellFrame.size.width, theCellFrame.origin.y + 1)];
		
		[[NSColor colorWithCalibratedWhite:1 alpha:0.4] set];
		[NSBezierPath setDefaultLineWidth:0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(theCellFrame.origin.x, theCellFrame.origin.y + 1.5) 
								  toPoint:NSMakePoint(theCellFrame.origin.x + theCellFrame.size.width, theCellFrame.origin.y + 1.5)];
	}
	
	// Draw the icon
	[icon drawInRect:iconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
	// Draw the text
	[title drawInRect:aTitleBox withAttributes:titleAttributes];
	
	if (showSubtitle) {
		[subtitle drawInRect:aSubtitleBox withAttributes:subtitleAttributes];	
	}
}

@end