#import <Cocoa/Cocoa.h>


@interface PRRatingCell : NSSegmentedCell
{
	BOOL showDots;
	NSRect cellFrame_;
	BOOL editing;
	int editSelectedSegment;
}

- (NSRect)frameForSegment:(BOOL)segment;
- (void)setShowDots:(BOOL)newShowDots;

@end