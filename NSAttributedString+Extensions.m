#import "NSAttributedString+Extensions.h"
#import "NSParagraphStyle+Extensions.h"


@implementation NSAttributedString (Extensions)

+ (NSMutableDictionary *)defaultUIAttributes {
    return [NSMutableDictionary dictionaryWithDictionary:@{
        NSFontAttributeName:[NSFont fontWithName:@"LucidaGrande" size:11],
        NSForegroundColorAttributeName:[NSColor colorWithDeviceWhite:0.3 alpha:1.0],
        NSParagraphStyleAttributeName:[NSParagraphStyle leftAlignStyle],
    }];
}

+ (NSMutableDictionary *)defaultBoldUIAttributes {
    NSMutableDictionary *attrs = [self defaultUIAttributes];
    [attrs setObject:[NSFont fontWithName:@"LucidaGrande-Bold" size:11] forKey:NSFontAttributeName];
    [attrs setObject:[NSColor colorWithDeviceWhite:0.1 alpha:1.0] forKey:NSForegroundColorAttributeName];
    return attrs;
}

@end
