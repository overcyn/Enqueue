#import <Cocoa/Cocoa.h>


@interface PRSynchronizedScrollView : NSScrollView
- (void)setSynchronizedScrollView:(NSScrollView *)scrollview;
- (void)stopSynchronizing;
- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification;
@end
