#import "PRUpNextCell.h"
#import "PRUpNextViewController.h"
#import "NSParagraphStyle+Extensions.h"

@implementation PRUpNextCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)theControlView {
    BOOL highlighted = [self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder]
        && [[[self controlView] window] isMainWindow];
    
    PRUpNextCellModel *model = [self objectValue];
    NSString *title = [model title];
    NSNumber *badge = [model badge];
    NSImage *icon = nil;
    NSImage *invertedIcon = nil;
    if ([model iconType] ==  PRUpNextCellIconTypeNone) {
        icon = [[NSImage alloc] init];
        invertedIcon = [[NSImage alloc] init];
    } else if ([model iconType] == PRUpNextCellIconTypePlaying) {
        icon = [NSImage imageNamed:@"PRSpeakerIcon"];
        invertedIcon = [NSImage imageNamed:@"PRSpeakerIcon"];
    } else if ([model iconType] == PRUpNextCellIconTypeMissing) {
        icon = [NSImage imageNamed:@"Exclamation Point"];
        invertedIcon = [NSImage imageNamed:@"Exclamation Point"];
    }
    
    // Layout
    float horizontalPadding = 3;
    NSSize iconSize = NSMakeSize(15, 15);
    NSRect iconRect = NSMakeRect(cellFrame.origin.x + 4,
                                 cellFrame.origin.y + cellFrame.size.height/2 - iconSize.height/2, 
                                 iconSize.width, iconSize.height);
        
    if ([badge intValue] != 0) {
        // Badge
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
        [shadow setShadowColor:(highlighted ? [NSColor colorWithDeviceWhite:1.0 alpha:0.0] : [NSColor colorWithDeviceWhite:1.0 alpha:1.0])];
        NSColor *badgeColor = highlighted ? [NSColor whiteColor] : [NSColor colorWithDeviceWhite:0.3 alpha:1.0];
        NSDictionary *attributes = @{
            NSForegroundColorAttributeName:badgeColor,
            NSFontAttributeName:[NSFont fontWithName:@"Helvetica-Bold" size:12],
            NSParagraphStyleAttributeName:[NSParagraphStyle centerAlignStyle],
            NSShadowAttributeName:shadow};
        NSAttributedString *badgeString = [[NSAttributedString alloc] initWithString:[badge stringValue] attributes:attributes];
        
        NSRect badgeRect = NSMakeRect(cellFrame.origin.x + 2, cellFrame.origin.y + 2, 18, 14);
        [badgeString drawInRect:NSInsetRect(badgeRect, 2, 0)];
    } else {
        // Icon
        icon = highlighted ? invertedIcon : icon;
        [icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
    
    // Text
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
    [shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSColor *color = highlighted ? [NSColor whiteColor] : [NSColor colorWithCalibratedWhite:0.10 alpha:1];
    NSDictionary *attributes = @{
        NSFontAttributeName:[NSFont systemFontOfSize:11.0],
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

@implementation PRUpNextCellModel

- (id)copyWithZone:(NSZone *)zone {
    PRUpNextCellModel *copy = [[[self class] alloc] init];
    [copy setTitle:[self title]];
    [copy setBadge:[self badge]];
    [copy setIconType:[self iconType]];
    return copy;
}

@end
