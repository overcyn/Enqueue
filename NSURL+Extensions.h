#import <Cocoa/Cocoa.h>


@interface NSURL (Extensions)

//- (NSURL *)URLByAppendingPathComponent:(NSString *)pathComponent;
//- (NSURL *)URLByAppendingPathExtension:(NSString *)pathExtension;
//- (NSURL *)URLByDeletingLastPathComponent;
//- (NSURL *)URLByDeletingPathExtension;
//- (NSString *)pathExtension;

- (BOOL)caseSensitive;
- (BOOL)contains:(NSURL *)URL;
- (BOOL)compare:(NSURL *)URL;

@end
