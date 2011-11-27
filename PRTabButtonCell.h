#import <AppKit/AppKit.h>

@interface PRTabButtonCell : NSButtonCell
{
    BOOL _rounded;
}

@property (readwrite) BOOL rounded;

@end
