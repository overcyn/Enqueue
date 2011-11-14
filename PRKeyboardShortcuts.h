#import <Foundation/Foundation.h>

@class PRCore, SPMediaKeyTap;

@interface PRKeyboardShortcuts : NSObject 
{
    SPMediaKeyTap *_tap;
    
    // weak
    PRCore *_core;
}

- (id)initWithCore:(PRCore *)core;

@end
