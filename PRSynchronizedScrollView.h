#import <Cocoa/Cocoa.h>


@interface PRSynchronizedScrollView : NSScrollView
{
	 NSScrollView *synchronizedScrollView;
}

- (void)setSynchronizedScrollView:(NSScrollView*)scrollview;
- (void)stopSynchronizing;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;

@end
