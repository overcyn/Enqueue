#import <Foundation/Foundation.h>
@class PRCore, SPMediaKeyTap;


@interface PRMediaKeyController : NSObject {
    __weak PRCore *_core;
    SPMediaKeyTap *_tap;
}
- (id)initWithCore:(PRCore *)core;
@property (readwrite, getter=isEnabled) BOOL enabled;
@end
