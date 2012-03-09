#import "NSWindow+Extensions.h"

@implementation NSWindow (Extensions)

- (BOOL)isFullScreen
{
    return (([self styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask);
}


@end
