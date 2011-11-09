#import <Cocoa/Cocoa.h>


@interface PRApplication : NSApplication
{

}

// ========================================
// Media Keys

- (void)mediaKeyEvent:(int)key state:(BOOL)state repeat:(BOOL)repeat;

@end
