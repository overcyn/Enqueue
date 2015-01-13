#import <Cocoa/Cocoa.h>

@interface PRRatingCell : NSSegmentedCell
@property (readwrite) BOOL showDots;
- (NSRect)frameForSegment:(BOOL)segment;
@end