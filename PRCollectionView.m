#import "PRCollectionView.h"

@implementation PRCollectionView

- (void)drawRect:(NSRect)dirtyRect
{
//    BOOL color = TRUE;
//    float x = 0;
//    while (x < [self bounds].size.width) {
//        if (color) {
//            [[NSColor colorWithCalibratedWhite:0.87 alpha:1.0] set];
//        } else {
//            [[NSColor colorWithCalibratedWhite:0.93 alpha:1.0] set];
//        }
//        NSRect rect = [self bounds];
//        rect.origin.x = x;
//        rect.size.width = 270;
//        [NSBezierPath fillRect:rect];
//        
//        color = !color;
//        x += 270;
//    }
    [[NSColor colorWithCalibratedWhite:0.93 alpha:1.0] set];
    [NSBezierPath fillRect:dirtyRect];
    
    [super drawRect:dirtyRect];
}

@end
