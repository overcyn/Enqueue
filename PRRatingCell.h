#import <Cocoa/Cocoa.h>


@interface PRRatingCell : NSSegmentedCell
{
	BOOL _showDots;
	NSRect _cellFrame;
	BOOL _editing;
}

@property (readwrite) BOOL showDots;

- (NSRect)frameForSegment:(BOOL)segment;

@end