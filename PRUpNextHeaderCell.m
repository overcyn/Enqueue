#import "PRUpNextHeaderCell.h"
#import "PRUpNextViewController.h"
#import "NSAttributedString+Extensions.h"
#import "NSParagraphStyle+Extensions.h"

@implementation PRUpNextHeaderCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    BOOL highlighted = [self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder]
        && [[[self controlView] window] isMainWindow];
    
    NSString *title = [[self objectValue] objectForKey:@"title"];
    NSString *subtitle = [[self objectValue] objectForKey:@"subtitle"];
    
    // Background
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:
        [NSColor colorWithCalibratedWhite:0.99 alpha:0.5], 0.0,
        [NSColor colorWithCalibratedWhite:0.99 alpha:0.5], 1.0, nil];
    [gradient drawInRect:cellFrame angle:90];
    
    // Text Attributes
    NSMutableDictionary *titleAttrs = [NSAttributedString defaultBoldUIAttributes];
    NSMutableDictionary *subtitleAttrs = [NSAttributedString defaultUIAttributes];
    NSColor *titleColor = highlighted ? [NSColor whiteColor] : [NSColor colorWithDeviceWhite:0.0 alpha:1.0];
    NSColor *subTitleColor = highlighted ? [NSColor whiteColor] : [NSColor colorWithDeviceWhite:0.0 alpha:1.0];
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
