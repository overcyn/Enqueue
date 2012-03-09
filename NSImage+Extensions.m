#import "NSImage+Extensions.h"


@implementation NSImage (Extensions)

- (NSData *)jpegRepresentationWithCompressionFactor:(float)compression {
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compression] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    
    return imageData;
}

@end

