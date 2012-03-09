#import <Cocoa/Cocoa.h>


@interface PRRatingCell : NSSegmentedCell {
	BOOL _showDots;
	NSRect _cellFrame;
	BOOL _editing;
}
// Accessors
@property (readwrite) BOOL showDots;

// Drawing Misc
- (NSRect)frameForSegment:(BOOL)segment;
@end