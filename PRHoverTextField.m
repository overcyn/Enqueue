#import "PRHoverTextField.h"


@implementation PRHoverTextField

- (id)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

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
	NSMutableAttributedString *attributedString = 
      [[[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]] autorelease];
    [attributedString addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] 
                                                                forKey:NSUnderlineStyleAttributeName] 
                              range:NSMakeRange(0, [attributedString length])];
    [self setAttributedStringValue:attributedString];
    
}

- (void)mouseExited:(NSEvent *)theEvent
{
	NSMutableAttributedString *attributedString = 
    [[[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]] autorelease];
    [attributedString addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnderlineStyleNone] 
                                                                forKey:NSUnderlineStyleAttributeName] 
                              range:NSMakeRange(0, [attributedString length])];
    [self setAttributedStringValue:attributedString];
}

@end
