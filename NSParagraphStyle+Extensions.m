#import "NSParagraphStyle+Extensions.h"


@implementation NSParagraphStyle (Extensions)

+ (NSParagraphStyle *)rightAlignStyle {
    NSMutableParagraphStyle *align = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [align setAlignment:NSRightTextAlignment];
    [align setLineBreakMode:NSLineBreakByTruncatingTail];
    return align;
}

+ (NSParagraphStyle *)leftAlignStyle {
    NSMutableParagraphStyle *align = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [align setAlignment:NSLeftTextAlignment];
    [align setLineBreakMode:NSLineBreakByTruncatingTail];
    return align;
}

+ (NSParagraphStyle *)centerAlignStyle {
    NSMutableParagraphStyle *align = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [align setAlignment:NSCenterTextAlignment];
    [align setLineBreakMode:NSLineBreakByTruncatingTail];
    return align;
}

@end
