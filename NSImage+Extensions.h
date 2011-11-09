#import <Cocoa/Cocoa.h>


@interface NSImage (Extensions)

- (NSData *)jpegRepresentationWithCompressionFactor:(float)compression;

@end
