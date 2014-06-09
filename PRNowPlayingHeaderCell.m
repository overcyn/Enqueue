#import "PRNowPlayingHeaderCell.h"
#import "PRNowPlayingViewController.h"
#import "NSAttributedString+Extensions.h"
#import "NSParagraphStyle+Extensions.h"


@implementation PRNowPlayingHeaderCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder]
        && [[[self controlView] window] isMainWindow];
    
	NSString *title = [[self objectValue] objectForKey:@"title"];
	NSString *subtitle = [[self objectValue] objectForKey:@"subtitle"];
    BOOL drawBorder = [[[self objectValue] objectForKey:@"drawBorder"] boolValue];
    
    // Background
    NSGradient *gradient;
    if (highlighted) {
        gradient = [[NSGradient alloc] initWithColorsAndLocations: 
                     [[NSColor colorWithCalibratedRed:59./255 green:128./255 blue:223./255 alpha:1.0] blendedColorWithFraction:0.1 ofColor:[NSColor whiteColor]], 1.0, nil];
    } else if ([self isHighlighted]) {
        gradient = [[NSGradient alloc] initWithColorsAndLocations: 
                     [NSColor colorWithDeviceWhite:0.8 alpha:1.0], 1.0, nil];
    } else {
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                     [NSColor colorWithCalibratedWhite:0.90 alpha:1.0], 0.0, 
                     [NSColor colorWithCalibratedWhite:0.87 alpha:1.0], 1.0, nil];
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

	// Text Attributes	
    NSMutableDictionary *titleAttrs = [NSAttributedString defaultBoldUIAttributes];
    NSMutableDictionary *subtitleAttrs = [NSAttributedString defaultUIAttributes];
    NSColor *titleColor = highlighted ? [NSColor whiteColor] : [NSColor colorWithDeviceWhite:0.25 alpha:1.0];
    NSColor *subTitleColor = highlighted ? [NSColor whiteColor] : [NSColor colorWithDeviceWhite:0.4 alpha:1.0];
    if (highlighted) {
        [titleAttrs removeObjectForKey:NSShadowAttributeName];
        [subtitleAttrs removeObjectForKey:NSShadowAttributeName];
    }
    [titleAttrs setObject:titleColor forKey:NSForegroundColorAttributeName];
    [subtitleAttrs setObject:subTitleColor forKey:NSForegroundColorAttributeName];
	
	// Text
	NSSize titleSize = [title sizeWithAttributes:titleAttrs];
	NSSize subtitleSize = [subtitle sizeWithAttributes:subtitleAttrs];
    float height = titleSize.height + subtitleSize.height + 3;
	NSRect textBox = NSMakeRect(cellFrame.origin.x + 21, cellFrame.origin.y + cellFrame.size.height * .5 - height * 0.5,
                                cellFrame.size.width - 24, height);
    NSRect titleBox = NSMakeRect(textBox.origin.x, textBox.origin.y + textBox.size.height*.5 - titleSize.height,
                                 textBox.size.width, titleSize.height);
    NSRect subtitleBox = NSMakeRect(textBox.origin.x, textBox.origin.y + textBox.size.height*.5,
                                    textBox.size.width, subtitleSize.height);
	[title drawInRect:titleBox withAttributes:titleAttrs];
    [subtitle drawInRect:subtitleBox withAttributes:subtitleAttrs];
}

@end
