#import "NSBezierPath+Extensions.h"

@implementation NSBezierPath (Extensions)

+ (NSRect)leftBorderOfRect:(NSRect)rect
{
    return NSMakeRect(rect.origin.x, rect.origin.y, 1, rect.size.height);
}

+ (NSRect)rightBorderOfRect:(NSRect)rect
{
    return NSMakeRect(rect.origin.x + rect.size.width - 1, rect.origin.y, 1, rect.size.height);
}

+ (NSRect)topBorderOfRect:(NSRect)rect
{
    return NSMakeRect(rect.origin.x, rect.origin.y + rect.size.height - 1, rect.size.width, 1);
}

+ (NSRect)botBorderOfRect:(NSRect)rect
{
    return NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, 1);
}

@end
