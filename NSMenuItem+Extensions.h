#import <AppKit/AppKit.h>

@interface NSMenuItem (Extensions)
- (void)setActionBlock:(void (^)(void))blk;
- (void)executeActionBlock;
@end
