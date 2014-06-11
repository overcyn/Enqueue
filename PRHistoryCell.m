#import "PRHistoryCell.h"
#import "NSColor+Extensions.h"
#import "NSParagraphStyle+Extensions.h"
#import "NSBezierPath+Extensions.h"


@implementation PRHistoryCell

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView {
    NSDictionary *dict = [self objectValue];
    NSString *title = [dict objectForKey:@"title"];
    NSString *subtitle = [dict objectForKey:@"subtitle"];
    NSString *subSubTitle = [dict objectForKey:@"subSubTitle"];
    float value = [[dict objectForKey:@"value"] floatValue];
    float max = [[dict objectForKey:@"max"] floatValue];
    
    // Border
    [[NSColor PRGridColor] set];
    [NSBezierPath fillRect:NSMakeRect(frame.origin.x, frame.origin.y + frame.size.height - 1, frame.size.width, 1)];
    [[NSColor PRGridHighlightColor] set];
    [NSBezierPath fillRect:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, 1)];

    // Graph
    if (value != 0 && max != 0) {
        NSRect graphFrame = frame;
        graphFrame.size.width -= 100;
        graphFrame.origin.y += 0.5;
        graphFrame.size.height -= 0.5;
        if (max < 10) {
            max = 10;
        }
        float drawWidth = (value / max * (graphFrame.size.width)) + 20;
        NSRect fillFrame, eraseFrame;
        NSDivideRect(graphFrame, &fillFrame, &eraseFrame, drawWidth, NSMinXEdge);
        
        [[[NSColor selectedTextBackgroundColor] blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]] set];
        [[NSBezierPath bezierPathWithRect:fillFrame] fill];
        [[[NSColor PRGridColor] blendedColorWithFraction:0.07 ofColor:[NSColor blackColor]] set];    
        [NSBezierPath fillRect:[NSBezierPath topBorderOfRect:fillFrame]];
    }
    
    frame.size.width -= 40;
    frame.origin.x += 20;
    frame.size.height -= 3;
    frame.size.width -= 100;
    
    // Title & Subtitle
    NSDictionary *titleAttr = @{
        NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue" size:12],
        NSParagraphStyleAttributeName:[NSParagraphStyle leftAlignStyle],
        NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]};
    NSDictionary *subtitleAttr = @{
        NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue-Italic" size:12],
        NSParagraphStyleAttributeName:[NSParagraphStyle leftAlignStyle],
        NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.3 alpha:1.0]};
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:title attributes:titleAttr];
    if (subtitle) {
        subtitle = [NSString stringWithFormat:@"  —  %@",subtitle];
        [str appendAttributedString:[[NSMutableAttributedString alloc] initWithString:subtitle attributes:subtitleAttr]];
    }
    
    NSSize titleSize = [title sizeWithAttributes:titleAttr];
    NSRect textFrame = NSMakeRect(frame.origin.x + 10, frame.origin.y + frame.size.height * .5 - titleSize.height * .5,
                                  frame.size.width, titleSize.height);
    [str drawInRect:textFrame];
    
    // SubSubTitle
    NSDictionary *subSubtitleAttr = @{
        NSFontAttributeName:[NSFont fontWithName:@"HelveticaNeue" size:12],
        NSParagraphStyleAttributeName:[NSParagraphStyle rightAlignStyle],
        NSForegroundColorAttributeName:[NSColor blackColor]};
    
    NSSize subSubtitleSize = [subSubTitle sizeWithAttributes:subSubtitleAttr];
    NSRect subSubtitleFrame = NSMakeRect(textFrame.origin.x + textFrame.size.width, frame.origin.y + (frame.size.height - subSubtitleSize.height) / 2.0,
                                         90, frame.size.height);
    [subSubTitle drawInRect:subSubtitleFrame withAttributes:subSubtitleAttr];
}

@end
