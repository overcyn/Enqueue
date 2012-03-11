#import "NSColor+Extensions.h"

@implementation NSColor (Extensions)

+ (NSColor *)PRGridColor {
    return [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
}

+ (NSColor *)PRGridHighlightColor {
    return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

+ (NSColor *)PRTabBorderColor {
    return [NSColor colorWithCalibratedWhite:0.70 alpha:1.0];
}

+ (NSColor *)PRTabBorderHighlightColor {
    return [NSColor colorWithCalibratedWhite:0.99 alpha:1.0];
}

+ (NSColor *)PRAltTabColor {
    return [NSColor colorWithCalibratedWhite:0.89 alpha:1.0];
}

+ (NSColor *)PRAltTabDepressedColor {
    return [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
}

+ (NSColor *)PRAltTabBorderHighlightColor; {
    return [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];
}

+ (NSColor *)PRTabBackgroundColor {
    return [NSColor colorWithCalibratedWhite:0.92 alpha:1.0];
}

+ (NSColor *)PRBackgroundColor {
    return [NSColor colorWithCalibratedWhite:0.89 alpha:1.0];
}

+ (NSColor *)PRForegroundColor {
    return [NSColor colorWithCalibratedWhite:0.97 alpha:1.0];
}

+ (NSColor *)PRForegroundBorderColor {
    return [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
}

@end
