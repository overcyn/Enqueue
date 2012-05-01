#import "PRHistoryCell.h"
#import "NSColor+Extensions.h"
#import "NSParagraphStyle+Extensions.h"


@implementation PRHistoryCell

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)theControlView {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
	NSString *subtitle = [dict objectForKey:@"subtitle"];
    NSString *subSubTitle = [dict objectForKey:@"subSubTitle"];
    
    // BACKGROUND
    [[NSColor PRGridColor] set];
    [NSBezierPath fillRect:NSMakeRect(frame.origin.x, frame.origin.y + frame.size.height - 1, frame.size.width, 1)];
    [[NSColor PRGridHighlightColor] set];
    [NSBezierPath fillRect:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, 1)];

    frame.size.height -= 1;
    if ([self isHighlighted]) {
        [[NSColor colorWithCalibratedWhite:0.84 alpha:1.0] set];
        [NSBezierPath fillRect:frame];
    }
    
    frame.size.width -= 40;
    frame.origin.x += 20;
    frame.size.height -= 2;
    frame.size.width -= 100;
    
    // ICON
    NSImage *icon = [dict objectForKey:@"icon"];
    if (!icon) {
        icon = [NSImage imageNamed:@"PRLightAlbumArt"];
    }
	NSSize iconSize = NSMakeSize(25, 25);
	[icon setFlipped:YES];
	NSRect iconBox = NSMakeRect(frame.origin.x, frame.origin.y + frame.size.height*.5 - iconSize.height*.5, 0, 0);
    [icon drawInRect:iconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    // TITLE SUBTITLE
    NSDictionary *titleAttr = @{NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue" size:12],
        NSParagraphStyleAttributeName:[NSParagraphStyle leftAlignStyle],
        NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]};
    
    NSDictionary *subtitleAttr = @{NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue-Italic" size:12],
        NSParagraphStyleAttributeName:[NSParagraphStyle leftAlignStyle],
        NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.3 alpha:1.0]};
    
    // get the size of the string for layout
	NSSize titleSize = [title sizeWithAttributes:titleAttr];
	float titleHeight = titleSize.height;
	
    NSRect textFrame = frame;
    textFrame = NSMakeRect(textFrame.origin.x + 10, textFrame.origin.y + textFrame.size.height * .5 - titleHeight * .5,
                           textFrame.size.width, titleHeight);
    
    NSMutableAttributedString *str = [[[NSMutableAttributedString alloc] initWithString:title attributes:titleAttr] autorelease];
    if (subtitle) {
        subtitle = [NSString stringWithFormat:@"  —  %@",subtitle];
        [str appendAttributedString:[[[NSMutableAttributedString alloc] initWithString:subtitle attributes:subtitleAttr] autorelease]];
    }
    
    [str drawInRect:textFrame];
    
    // SUBSUBTITLE
    NSDictionary *subSubtitleAttr = @{
        NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue" size:12],
        NSParagraphStyleAttributeName:[NSParagraphStyle rightAlignStyle],
        NSForegroundColorAttributeName:[NSColor blackColor]};
    
    NSSize subSubtitleSize = [subSubTitle sizeWithAttributes:subSubtitleAttr];
    
    NSRect subSubtitleFrame = frame;
    subSubtitleFrame.origin.x += subSubtitleFrame.size.width;
    subSubtitleFrame.size.width = 90;
    subSubtitleFrame.origin.y = subSubtitleFrame.origin.y + (subSubtitleFrame.size.height - subSubtitleSize.height) / 2.0;
    
    [subSubTitle drawInRect:subSubtitleFrame withAttributes:subSubtitleAttr];
    
    [pool drain];
}

@end
