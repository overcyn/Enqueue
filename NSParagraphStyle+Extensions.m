#import "NSParagraphStyle+Extensions.h"


@implementation NSParagraphStyle (Extensions)

+ (NSParagraphStyle *)rightAlignStyle {
    NSMutableParagraphStyle *align = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [align setAlignment:NSRightTextAlignment];
    [align setAlignment:NSLineBreakByTruncatingTail];
    return align;
}

+ (NSParagraphStyle *)leftAlignStyle {
    NSMutableParagraphStyle *align = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [align setAlignment:NSLeftTextAlignment];
    [align setAlignment:NSLineBreakByTruncatingTail];
    return align;
}

+ (NSParagraphStyle *)centerAlignStyle {
    NSMutableParagraphStyle *align = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [align setAlignment:NSCenterTextAlignment];
    [align setAlignment:NSLineBreakByTruncatingTail];
    return align;
}

@end
