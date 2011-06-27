#import <Cocoa/Cocoa.h>


@interface NSImage (Extensions)

typedef enum {
    MGImageResizeCrop,
    MGImageResizeCropStart,
    MGImageResizeCropEnd,
    MGImageResizeScale
} MGImageResizingMethod;

- (void)drawInRect:(NSRect)dstRect operation:(NSCompositingOperation)op fraction:(float)delta method:(MGImageResizingMethod)resizeMethod;
- (NSImage *)imageToFitSize:(NSSize)size method:(MGImageResizingMethod)resizeMethod;
- (NSImage *)imageCroppedToFitSize:(NSSize)size;
- (NSImage *)imageScaledToFitSize:(NSSize)size;
- (NSImage *)imageScaledToLength:(float)length;

- (NSData *)jpegRepresentationWithCompressionFactor:(float)compression;

- (void)drawCenteredinRect:(NSRect)inRect operation:(NSCompositingOperation)op fraction:(float)delta;

@end
