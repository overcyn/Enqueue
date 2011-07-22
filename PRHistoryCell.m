#import "PRHistoryCell.h"


@implementation PRHistoryCell


- (void)drawWithFrame:(NSRect)theCellFrame inView:(NSView *)theControlView
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
	NSString *subtitle = [dict objectForKey:@"subtitle"];
    NSString *subSubTitle = [dict objectForKey:@"subSubTitle"];
    float value = [[dict objectForKey:@"value"] floatValue];
	float max = [[dict objectForKey:@"max"] floatValue];
    int kind = [[dict objectForKey:@"kind"] intValue];
	NSImage *icon = [dict objectForKey:@"icon"];
    if (!icon) {
        icon = [NSImage imageNamed:@"PRLightAlbumArt"];
    }
	NSSize iconSize = NSMakeSize(28, 28);
	[icon setFlipped:YES];
    
    if ([[dict objectForKey:@"mouseOver"] boolValue] && value == 0) {
//        NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
//                                 [NSColor colorWithDeviceRed:212.0/255.0 green:233.0/255.0 blue:246.0/255.0 alpha:0.6], 0.0, 
//                                 [NSColor colorWithDeviceRed:212.0/255.0 green:233.0/255.0 blue:246.0/255.0 alpha:0.8], 1.0,
//                                 nil] autorelease];
//        [gradient drawInRect:theCellFrame angle:90.0];
    }
    
    theCellFrame.size.height -= 6;
    theCellFrame.origin.y += 3;
    theCellFrame.origin.x += 3;
    
    if ([[dict objectForKey:@"mouseOver"] boolValue] && value != 0) {
//        NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
//                                 [NSColor colorWithDeviceRed:212.0/255.0 green:233.0/255.0 blue:246.0/255.0 alpha:0.6], 1.0,
//                                 nil] autorelease];
//        [gradient drawInRect:theCellFrame angle:90.0];
    }
    
    theCellFrame.size.width -= 70;
    
    // Calculate width of filled part
    if (max < 10) {
        max = 10;
    }
	float drawWidth = (value / max * (theCellFrame.size.width - 70)) + 70;
	NSRect fillFrame, eraseFrame;
	NSDivideRect(theCellFrame, &fillFrame, &eraseFrame, drawWidth, NSMinXEdge);
	[[NSColor colorWithDeviceRed:212.0/255.0 green:233.0/255.0 blue:246.0/255.0 alpha:1.0] set];
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:fillFrame xRadius:4.0 yRadius:4.0];

    if (value != 0) {
        [NSGraphicsContext saveGraphicsState];
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.4]];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:2.0];
        [shadow set];
        [bezierPath fill];
        [NSGraphicsContext restoreGraphicsState];
    }

    theCellFrame.size.width -= 50;
    
    // paragraph style
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
    [shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
    NSMutableDictionary *titleAttributes = 
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
         [NSFont fontWithName:@"HelveticaNeue-Medium" size:12], NSFontAttributeName,
         paragraphStyle, NSParagraphStyleAttributeName,
         [NSColor colorWithDeviceWhite:0.2 alpha:1.0], NSForegroundColorAttributeName,
         shadow, NSShadowAttributeName,
         nil];
    NSMutableDictionary *subtitleAttributes = 
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
         [NSFont fontWithName:@"HelveticaNeue" size:11], NSFontAttributeName,
         paragraphStyle, NSParagraphStyleAttributeName,
         [NSColor colorWithDeviceWhite:0.5 alpha:1.0], NSForegroundColorAttributeName,
//         shadow, NSShadowAttributeName,
         nil];
    NSMutableParagraphStyle *paragraphStyle2 = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle2 setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle2 setAlignment:NSRightTextAlignment];
    NSMutableDictionary *subSubTitleAttributes;
    
    if (kind == 0) {
        subSubTitleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont fontWithName:@"HelveticaNeue-Medium" size:15], NSFontAttributeName,
                                 paragraphStyle2, NSParagraphStyleAttributeName,
                                 [NSColor colorWithDeviceWhite:0.2 alpha:1.0], NSForegroundColorAttributeName,
                                 nil];
    } else {
        subSubTitleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont fontWithName:@"HelveticaNeue" size:12], NSFontAttributeName,
                                 paragraphStyle2, NSParagraphStyleAttributeName,
                                 [NSColor colorWithDeviceWhite:0.2 alpha:1.0], NSForegroundColorAttributeName,
                                 nil];
    }
    
//    if ([[dict objectForKey:@"mouseOver"] boolValue]) {
//        [titleAttributes setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
//        [subtitleAttributes setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
//        [subSubTitleAttributes setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
//    }
	
    NSRect subSubTitleRect = theCellFrame;
    subSubTitleRect.origin.x += subSubTitleRect.size.width;
    subSubTitleRect.size.width = 110;
    NSAttributedString *temp = [[[NSAttributedString alloc] initWithString:subSubTitle attributes:subSubTitleAttributes] autorelease];
    subSubTitleRect.origin.y = subSubTitleRect.origin.y + (subSubTitleRect.size.height - [temp size].height) / 2.0;
    
    // Inset the cell frame to give everything a little horizontal padding
	NSRect insetRect = NSInsetRect(theCellFrame, 5, 0);
    insetRect.origin.x += 5;
    insetRect.size.width -= 5;
    
	// get the size of the string for layout
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];
    NSSize subtitleSize = [subtitle sizeWithAttributes:subtitleAttributes];
	
	// Vertical padding between the lines of text 	
	// Horizontal padding between icon and text
	float verticalPadding = 0.0;
	float horizontalPadding = 10;
	
	// Icon box: center the icon vertically inside of the inset rect
	NSRect iconBox = NSMakeRect(insetRect.origin.x,
								insetRect.origin.y + insetRect.size.height*.5 - iconSize.height*.5,
								iconSize.width,
								iconSize.height);
	
	// Make a box for our text
	// Place it next to the icon with horizontal padding
	// Size it horizontally to fill out the rest of the inset rect
	// Center it vertically inside of the inset rect
	float aCombinedHeight = titleSize.height + subtitleSize.height + verticalPadding;
	
	NSRect aTextBox = NSMakeRect(iconBox.origin.x + iconBox.size.width + horizontalPadding,
								 insetRect.origin.y + insetRect.size.height * .5 - aCombinedHeight * .5 - 2,
								 insetRect.size.width - iconSize.width - horizontalPadding,
								 aCombinedHeight);
    NSRect aTitleBox = NSMakeRect(aTextBox.origin.x, 
                                  aTextBox.origin.y + aTextBox.size.height / 2 - titleSize.height + 4,
                                  aTextBox.size.width, titleSize.height);
    NSRect aSubtitleBox = NSMakeRect(aTextBox.origin.x,
                                     aTextBox.origin.y + aTextBox.size.height*.5 + 2,
                                     aTextBox.size.width, subtitleSize.height);

    if (!subtitle) {
        aTitleBox = NSMakeRect(aTextBox.origin.x, 
                               aTextBox.origin.y + (aTextBox.size.height - titleSize.height) / 2,
                               aTextBox.size.width, titleSize.height);
    }
    
    [title drawInRect:aTitleBox withAttributes:titleAttributes];
    [subtitle drawInRect:aSubtitleBox withAttributes:subtitleAttributes];
    [subSubTitle drawInRect:subSubTitleRect withAttributes:subSubTitleAttributes];
	[icon drawInRect:iconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [pool drain];
}

@end
