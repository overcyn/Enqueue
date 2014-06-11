#import <Cocoa/Cocoa.h>


// View that draws background for the now playing display.
@interface PRHeaderBox : NSBox
@property (readwrite, strong) id trackingDelegate;
@end
