#import "PRHistoryCell2.h"
#import "NSBezierPath+Extensions.h"
#import "NSColor+Extensions.h"

@implementation PRHistoryCell2

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)theControlView
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
	NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
	NSString *subtitle = [dict objectForKey:@"subtitle"];
    NSString *subSubTitle = [dict objectForKey:@"subSubTitle"];
    float value = [[dict objectForKey:@"value"] floatValue];
	float max = [[dict objectForKey:@"max"] floatValue];
    
    // GRAPH
    NSRect graphFrame = NSInsetRect(frame, 0, 0);
    
    NSRect topBorder = [NSBezierPath topBorderOfRect:graphFrame];
    NSRect botBorder = [NSBezierPath botBorderOfRect:graphFrame];
    
    frame.size.width -= 40;
    frame.origin.x += 20;
    
    graphFrame.size.width -= 70;
    if (max < 10) {
        max = 10;
    }
	float drawWidth = (value / max * (graphFrame.size.width)) + 20;
	NSRect fillFrame, eraseFrame;
	NSDivideRect(graphFrame, &fillFrame, &eraseFrame, drawWidth, NSMinXEdge);
	
    float radius = 0;
    eraseFrame.size.width += 70;
    
    [[[NSColor selectedTextBackgroundColor] blendedColorWithFraction:0.5 ofColor:[NSColor whiteColor]] set];
    [[NSBezierPath bezierPathWithRoundedRect:fillFrame xRadius:radius yRadius:radius] fill];
    
    [[NSColor PRGridColor] set];
    [NSBezierPath fillRect:topBorder];
    [[[NSColor PRGridHighlightColor] colorWithAlphaComponent:0.5] set];
    [NSBezierPath fillRect:botBorder];
    
    [[[NSColor PRGridColor] blendedColorWithFraction:0.07 ofColor:[NSColor blackColor]] set];    
    [NSBezierPath fillRect:[NSBezierPath topBorderOfRect:fillFrame]];
    
    frame.size.width -= 100;
    
    // ICON
    NSImage *icon = [dict objectForKey:@"icon"];
    if (!icon) {
        icon = [NSImage imageNamed:@"PRLightAlbumArt"];
    }
	NSSize iconSize = NSMakeSize(25, 25);
	[icon setFlipped:YES];
	NSRect iconBox = NSMakeRect(frame.origin.x,
								frame.origin.y + frame.size.height*.5 - iconSize.height*.5,
								0,
								0);
    [icon drawInRect:iconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    // TITLE SUBTITLE
	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
    
    NSDictionary *titleAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSFont fontWithName:@"HelveticaNeue" size:12], NSFontAttributeName,
                               style, NSParagraphStyleAttributeName,
                               [NSColor colorWithCalibratedWhite:0.0 alpha:1.0], NSForegroundColorAttributeName, nil];
    NSDictionary *subtitleAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSFont fontWithName:@"HelveticaNeue-Italic" size:12], NSFontAttributeName,
                                  style, NSParagraphStyleAttributeName,
                                  [NSColor colorWithCalibratedWhite:0.3 alpha:1.0], NSForegroundColorAttributeName, nil];
    
    // get the size of the string for layout
	NSSize titleSize = [title sizeWithAttributes:titleAttr];
	float titleHeight = titleSize.height;
	
    NSRect textFrame = frame;
    textFrame = NSMakeRect(textFrame.origin.x + 10, 
                           textFrame.origin.y + textFrame.size.height * .5 - titleHeight * .5, 
                           textFrame.size.width, 
                           titleHeight);
    
    NSMutableAttributedString *str = [[[NSMutableAttributedString alloc] initWithString:title attributes:titleAttr] autorelease];
    if (subtitle) {
        subtitle = [NSString stringWithFormat:@"  —  %@",subtitle];
        [str appendAttributedString:[[[NSMutableAttributedString alloc] initWithString:subtitle attributes:subtitleAttr] autorelease]];
    }
    
    [str drawInRect:textFrame];
    
    // SUBSUBTITLE
    NSMutableParagraphStyle *style2 = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style2 setLineBreakMode:NSLineBreakByTruncatingTail];
    [style2 setAlignment:NSRightTextAlignment];
    NSMutableDictionary *subSubtitleAttr = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSFont fontWithName:@"HelveticaNeue" size:12], NSFontAttributeName,
                                            style2, NSParagraphStyleAttributeName,
                                            [NSColor colorWithCalibratedWhite:0.0 alpha:1.0], NSForegroundColorAttributeName, nil];
    
    NSSize subSubtitleSize = [subSubTitle sizeWithAttributes:subSubtitleAttr];
    
    NSRect subSubtitleFrame = frame;
    subSubtitleFrame.origin.x += subSubtitleFrame.size.width;
    subSubtitleFrame.size.width = 90;
    subSubtitleFrame.origin.y = subSubtitleFrame.origin.y + (subSubtitleFrame.size.height - subSubtitleSize.height) / 2.0;
    
    [subSubTitle drawInRect:subSubtitleFrame withAttributes:subSubtitleAttr];
    
    [pool drain];
}

@end
