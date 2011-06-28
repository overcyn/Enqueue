#import <Cocoa/Cocoa.h>


@interface PRTableView : NSTableView
{
	NSColor *highlightColor;
	NSColor *secondaryHighlightColor;
    bool slideback;
    
    int bordered;
}

@property (readwrite, retain) NSColor *highlightColor;
@property (readwrite, retain) NSColor *secondaryHighlightColor;
@property (readwrite, assign) bool slideback;
@property (readwrite) int bordered;

- (void)performDrawDropHighlightBetweenUpperRow:(int)theUpperRowIndex 
									andLowerRow:(int)theLowerRowIndex 
									   atOffset:(float)theOffset;

@end

@implementation NSColor (ColorChangingFun)

//+ (NSColor *)_blueAlternatingRowColor
//{
//    return [NSColor colorWithDeviceRed:243/255. green:246/255. blue:250/255. alpha:1.0];
//}

+ (NSArray *)controlAlternatingRowBackgroundColors
{
    return [NSArray arrayWithObjects:
            //[NSColor colorWithDeviceWhite:0.95 alpha:1.0],
            [NSColor colorWithDeviceRed:243/255. green:246/255. blue:250/255. alpha:1.0], 
            [NSColor colorWithDeviceWhite:255/255. alpha:1.0],
            nil];
}

@end