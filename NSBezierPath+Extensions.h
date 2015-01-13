#import <AppKit/AppKit.h>

@interface NSBezierPath (Extensions)
+ (NSRect)leftBorderOfRect:(NSRect)rect;
+ (NSRect)rightBorderOfRect:(NSRect)rect;
+ (NSRect)topBorderOfRect:(NSRect)rect;
+ (NSRect)botBorderOfRect:(NSRect)rect;
@end
