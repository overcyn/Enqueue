#import <Foundation/Foundation.h>

@interface NSFileManager (Extensions)

- (BOOL)itemAtURL:(NSURL *)u1 containsItemAtURL:(NSURL *)u2;
- (BOOL)itemAtURL:(NSURL *)u1 equalsItemAtURL:(NSURL *)u2;
- (NSArray *)subDirsAtURL:(NSURL *)URL error:(NSError **)err;

@end
