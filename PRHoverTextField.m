#import "PRHoverTextField.h"


@implementation PRHoverTextField

- (void)awakeFromNib
{
    [super awakeFromNib];
    NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:[self bounds] 
                                                                 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow 
                                                                   owner:self 
                                                                userInfo:nil] autorelease];
    [self addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]] autorelease];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, nil];
    [attributedString addAttributes:attributes range:NSMakeRange(0, [attributedString length])];
    [self setAttributedStringValue:attributedString];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]] autorelease];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:NSUnderlineStyleNone], NSUnderlineStyleAttributeName, nil];
    [attributedString addAttributes:attributes range:NSMakeRange(0, [attributedString length])];
    [self setAttributedStringValue:attributedString];
}

@end