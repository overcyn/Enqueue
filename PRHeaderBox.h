#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>


@interface PRHeaderBox : NSBox {
    id _trackingDelegate;
}
@property (readwrite, retain) id trackingDelegate;
@end
