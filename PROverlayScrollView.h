#import <Cocoa/Cocoa.h>


@interface PROverlayScrollView : NSScrollView 
{

}

@end


@interface NSScrollView (MyScroller)

+ (NSSize)contentSizeForFrameSize:(NSSize)frameSize 
			hasHorizontalScroller:(BOOL)hFlag 
			  hasVerticalScroller:(BOOL)vFlag 
					   borderType:(NSBorderType)borderType;

@end


@implementation NSScrollView (MyScroller)

+ (NSSize)contentSizeForFrameSize:(NSSize)frameSize 
			hasHorizontalScroller:(BOOL)hFlag 
			  hasVerticalScroller:(BOOL)vFlag 
					   borderType:(NSBorderType)borderType
{
	return frameSize;
}

@end