#import "PRCenteredTextFieldCell.h"


@implementation PRCenteredTextFieldCell

- (id)init {
    if (!(self = [super init])) {return nil;}
    [self _setup];
    return self;
}

- (id)initTextCell:(NSString *)string {
    if (!(self = [super initTextCell:string])) {return nil;}
    [self _setup];
    return self;
}

- (id)initImageCell:(NSImage *)image {
    if (!(self = [super initImageCell:image])) {return nil;}
    [self _setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (!(self = [super initWithCoder:decoder])) {return nil;}
    [self _setup];
    return self;
}

- (void)_setup {
    [self setFont:[NSFont systemFontOfSize:11]];
    [self setTruncatesLastVisibleLine:YES];
    [self setWraps:NO];
    [self setLineBreakMode:NSLineBreakByTruncatingTail];
    [self setEditable:YES];
}

#pragma mark - 

- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y + (theRect.size.height - titleSize.height) / 2.0;
    return NSInsetRect(titleFrame, 3, 1);
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];
    NSColor *color = [NSColor colorWithCalibratedWhite:0.10 alpha:1];
    if ([self isHighlighted] && [self controlView] == [[[self controlView] window] firstResponder] && [[[self controlView] window] isMainWindow]) {
        color = [NSColor whiteColor];
    }
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, nil];
    [string addAttributes:attributes range:NSMakeRange(0, [string length])];
    [string drawInRect:titleRect];
}

@end
