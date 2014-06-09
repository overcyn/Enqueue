#import "NSMenuItem+Extensions.h"

@implementation NSMenuItem (Extensions)

- (void)setActionBlock:(void (^)(void))blk {
    [self setTarget:self];
    [self setAction:@selector(executeActionBlock)];
    [self setRepresentedObject:[[blk copy] autorelease]];
}

- (void)executeActionBlock {
    ((void (^)(void))[self representedObject])();
}

@end
