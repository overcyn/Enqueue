#import "NSIndexPath+Extensions.h"


@implementation NSIndexPath (Extensions)

- (id)initWithAlbum:(NSUInteger)album song:(NSUInteger)song {
    NSUInteger indexes[] = {album, song};
    return [self initWithIndexes:indexes length:2];
}

+ (instancetype)indexPathForAlbum:(NSUInteger)album song:(NSUInteger)song {
    NSUInteger indexes[] = {album, song};
    return [self indexPathWithIndexes:indexes length:2];
}

+ (instancetype)indexPathForAlbum:(NSUInteger)album {
    return [self indexPathWithIndex:album];
}

- (NSUInteger)album {
    return [self indexAtPosition:0];
}

- (NSUInteger)song {
    return [self indexAtPosition:1];
}

@end
