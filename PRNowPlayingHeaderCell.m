#import "PRNowPlayingHeaderCell.h"
#import "PRNowPlayingViewController.h"

@implementation PRNowPlayingHeaderCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSOutlineView *outlineView = (NSOutlineView *)controlView;
	NSString *title = [[self objectValue] objectForKey:@"title"];
	NSString *subtitle = [[self objectValue] objectForKey:@"subtitle"];
    BOOL drawBorder = [[[self objectValue] objectForKey:@"drawBorder"] boolValue];
    id item = [[self objectValue] objectForKey:@"item"];
    
    // Background
    NSGradient *gradient;
    if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isKeyWindow]) {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations: 
                     [[NSColor colorWithCalibratedRed:59./255 green:128./255 blue:223./255 alpha:1.0] blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]], 1.0, nil] autorelease];
    } else if ([self isHighlighted]) {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations: 
                     [NSColor colorWithDeviceWhite:0.8 alpha:1.0], 1.0, nil] autorelease];
    } else {
        gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.90 alpha:1.0], 0.0, 
                     [NSColor colorWithCalibratedWhite:0.87 alpha:1.0], 1.0, nil] autorelease];
    }
    [gradient drawInRect:cellFrame angle:90];
    
    // Top Border
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.25] set];
    NSRect rect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, 1);
    [NSBezierPath fillRect:rect];
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.4] set];
    rect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + 1, cellFrame.size.width, 1);
    [NSBezierPath fillRect:rect];
    
    // Bottom Border
    if (drawBorder) {
        [[NSColor colorWithDeviceWhite:0.0 alpha:0.25] set];
        NSRect rect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height - 1 , cellFrame.size.width, 1);
        [NSBezierPath fillRect:rect];
    }
    
    // Disclosure Triangle
    NSImage *disclosure = [NSImage imageNamed:@"Disclosure"];
    if ([outlineView isItemExpanded:item]) {
        disclosure = [NSImage imageNamed:@"DisclosureAlt"];
    }
    [disclosure setFlipped:TRUE];
//    [disclosure drawInRect:[self disclosureImageRectForCellFrame:cellFrame] 
//                  fromRect:NSZeroRect 
//                 operation:NSCompositeSourceOver 
//                  fraction:1.0];

	// Text Attributes	
	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    NSColor *color;
    NSColor *altColor;
    if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isKeyWindow]) {
        color = [NSColor whiteColor];
        altColor = [NSColor whiteColor];
    } else {
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.4]];
        [shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
        color = [NSColor colorWithDeviceWhite:0.25 alpha:1.0];
        altColor = [NSColor colorWithDeviceWhite:0.4 alpha:1.0];
    }
    NSMutableDictionary *titleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                             [NSFont boldSystemFontOfSize:11], NSFontAttributeName,
                                             style, NSParagraphStyleAttributeName,
                                             color, NSForegroundColorAttributeName,
                                             shadow, NSShadowAttributeName,
                                             nil] autorelease];
    NSMutableDictionary *subtitleAttributes = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                [NSFont systemFontOfSize:11], NSFontAttributeName,
                                                altColor, NSForegroundColorAttributeName,
                                                shadow, NSShadowAttributeName,
                                                style, NSParagraphStyleAttributeName, 
                                                nil] autorelease];
	
	// Text
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];
	NSSize subtitleSize = [subtitle sizeWithAttributes:subtitleAttributes];
    float height = titleSize.height + subtitleSize.height + 3;
	NSRect textBox = NSMakeRect(cellFrame.origin.x + 21,
                                cellFrame.origin.y + cellFrame.size.height * .5 - height * 0.5,
                                cellFrame.size.width - 24,
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
}

- (NSRect)disclosureImageRectForCellFrame:(NSRect)cellFrame
{
    NSRect disclosureRect = NSMakeRect(0, 0, 15, 15);
    disclosureRect.origin.y = cellFrame.origin.y + cellFrame.size.height/2 - 7;
    disclosureRect.origin.x = cellFrame.origin.x + 3;
    return disclosureRect;
}

- (NSRect)disclosureRectForCellFrame:(NSRect)cellFrame
{
    NSRect disclosureRect = cellFrame;
    disclosureRect.size.width = 21;
    return disclosureRect;
}

@end
