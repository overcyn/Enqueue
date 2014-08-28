#import <Foundation/Foundation.h>


@interface NSIndexPath (Extensions)
- (id)initWithAlbum:(NSUInteger)album song:(NSUInteger)song;
+ (instancetype)indexPathForAlbum:(NSUInteger)album song:(NSUInteger)song;
+ (instancetype)indexPathForAlbum:(NSUInteger)album;
- (NSUInteger)album;
- (NSUInteger)song;
@end
