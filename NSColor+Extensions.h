#import <AppKit/AppKit.h>

@interface NSColor (Extensions)

+ (NSColor *)PRGridColor;
+ (NSColor *)PRGridHighlightColor;

+ (NSColor *)PRTabBorderColor;
+ (NSColor *)PRTabBorderHighlightColor;
+ (NSColor *)PRAltTabColor;
+ (NSColor *)PRAltTabDepressedColor;
+ (NSColor *)PRAltTabBorderHighlightColor;
+ (NSColor *)PRTabBackgroundColor;

+ (NSColor *)PRBackgroundColor;
+ (NSColor *)PRForegroundColor;
+ (NSColor *)PRForegroundBorderColor;

+ (NSColor *)PRSidebarBackgroundColor;
+ (NSColor *)PRBrowserBackgroundColor;

+ (NSColor *)transparent;

@end
