#import <Foundation/Foundation.h>


@interface PRScrollView : NSScrollView {
    NSSize _minimumSize;
}
@property (readwrite) NSSize minimumSize;
@end