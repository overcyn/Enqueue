#import <AppKit/AppKit.h>


@interface PRTabButtonCell : NSButtonCell {
    BOOL _rounded;
}
// Accessors
@property (readwrite) BOOL rounded;
@end
