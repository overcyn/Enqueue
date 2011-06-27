//
//  NSImage+Extensions.m
//  Lyre
//
//  Created by Kevin Dang on 1/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSImage+Extensions.h"



@implementation NSImage (Extensions)

- (void)drawInRect:(NSRect)dstRect operation:(NSCompositingOperation)op fraction:(float)delta method:(MGImageResizingMethod)resizeMethod
{
	float sourceWidth = [self size].width;
    float sourceHeight = [self size].height;
    float targetWidth = dstRect.size.width;
    float targetHeight = dstRect.size.height;
    BOOL cropping = !(resizeMethod == MGImageResizeScale);
    
    // Calculate aspect ratios
    float sourceRatio = sourceWidth / sourceHeight;
    float targetRatio = targetWidth / targetHeight;
    
    // Determine what side of the source image to use for proportional scaling
    BOOL scaleWidth = (sourceRatio <= targetRatio);
    // Deal with the case of just scaling proportionally to fit, without cropping
    scaleWidth = (cropping) ? scaleWidth : !scaleWidth;
    
    // Proportionally scale source image
    float scalingFactor, scaledWidth, scaledHeight;
    if (scaleWidth) {
        scalingFactor = 1.0 / sourceRatio;
        scaledWidth = targetWidth;
        scaledHeight = round(targetWidth * scalingFactor);
    } else {
        scalingFactor = sourceRatio;
        scaledWidth = round(targetHeight * scalingFactor);
        scaledHeight = targetHeight;
    }
    float scaleFactor = scaledHeight / sourceHeight;
    
    // Calculate compositing rectangles
    NSRect sourceRect;
    if (cropping) {
        float destX, destY;
        if (resizeMethod == MGImageResizeCrop) {
            // Crop center
            destX = round((scaledWidth - targetWidth) / 2.0);
            destY = round((scaledHeight - targetHeight) / 2.0);
        } else if (resizeMethod == MGImageResizeCropStart) {
            // Crop top or left (prefer top)
            if (scaleWidth) {
				// Crop top
				destX = round((scaledWidth - targetWidth) / 2.0);
				destY = round(scaledHeight - targetHeight);
            } else {
				// Crop left
                destX = 0.0;
				destY = round((scaledHeight - targetHeight) / 2.0);
            }
        } else if (resizeMethod == MGImageResizeCropEnd) {
            // Crop bottom or right
            if (scaleWidth) {
				// Crop bottom
				destX = 0.0;
				destY = 0.0;
            } else {
				// Crop right
				destX = round(scaledWidth - targetWidth);
				destY = round((scaledHeight - targetHeight) / 2.0);
            }
        }
        sourceRect = NSMakeRect(destX / scaleFactor, destY / scaleFactor, 
                                targetWidth / scaleFactor, targetHeight / scaleFactor);
    } else {
        sourceRect = NSMakeRect(0, 0, sourceWidth, sourceHeight);
		dstRect.origin.x += (targetWidth - scaledWidth) / 2.0;
		dstRect.origin.y += (targetHeight - scaledHeight) / 2.0;
		dstRect.size.width = scaledWidth;
		dstRect.size.height = scaledHeight;
    }
    
    [self drawInRect:dstRect fromRect:sourceRect operation:op fraction:delta];
}

- (NSImage *)imageToFitSize:(NSSize)size method:(MGImageResizingMethod)resizeMethod
{
    NSImage *result = [[NSImage alloc] initWithSize:size];
    
    // Composite image appropriately
    [result lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[self drawInRect:NSMakeRect(0,0,size.width,size.height) operation:NSCompositeSourceOver fraction:1.0 method:resizeMethod];
    [result unlockFocus];
    
    return [result autorelease];
}

- (NSImage *)imageCroppedToFitSize:(NSSize)size
{
    return [self imageToFitSize:size method:MGImageResizeCrop];
}

- (NSImage *)imageScaledToFitSize:(NSSize)size
{
    return [self imageToFitSize:size method:MGImageResizeScale];
}

- (NSImage *)imageScaledToLength:(float)length
{
    NSSize size;
    if ([self size].width > [self size].height) {
        size.width = length;
        size.height = length * [self size].height / [self size].width;
    } else {
        size.height = length;
        size.width = length * [self size].width / [self size].height;
    }

    return [self imageScaledToFitSize:size];
}

- (NSData *)jpegRepresentationWithCompressionFactor:(float)compression
{
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compression] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    
    return imageData;
}

- (void)drawCenteredinRect:(NSRect)inRect operation:(NSCompositingOperation)op fraction:(float)delta
{
    NSRect srcRect = NSZeroRect;
    srcRect.size = [self size];
    
    // create a destination rect scaled to fit inside the frame
    NSRect drawnRect = srcRect;
    if (drawnRect.size.width > drawnRect.size.height) {
        drawnRect.size.height *= inRect.size.width/drawnRect.size.width;
        drawnRect.size.width = inRect.size.width;
    } else {
        drawnRect.size.width *= inRect.size.height/drawnRect.size.height;
        drawnRect.size.height = inRect.size.height;
    }

    
    drawnRect.origin = inRect.origin;
    
    // center it in the frame
    drawnRect.origin.x += (inRect.size.width - drawnRect.size.width)/2;
    drawnRect.origin.y += (inRect.size.height - drawnRect.size.height)/2;
    

    
    // draw image
    [self drawInRect:drawnRect fromRect:srcRect operation:op fraction:delta];
    
//	// draw border
//	NSPoint startPoint;
//	NSPoint endPoint;
//	
//	[NSBezierPath setDefaultLineWidth:0];
//	// top
//	[[NSColor lightGrayColor] set];
//	startPoint = NSMakePoint(drawnRect.origin.x + 0.5, drawnRect.origin.y + 0.5);
//	endPoint = NSMakePoint(drawnRect.origin.x + drawnRect.size.width + 0.5, drawnRect.origin.y + 0.5);
//	[NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
//	// bottom
//	[[NSColor grayColor] set];
//	startPoint = NSMakePoint(drawnRect.origin.x + 0.5, drawnRect.origin.y + drawnRect.size.height + 0.5);
//	endPoint = NSMakePoint(drawnRect.origin.x + drawnRect.size.width + 0.5, drawnRect.origin.y + drawnRect.size.height + 0.5);
//	[NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
//	// left
//	[[NSColor grayColor] set];
//	startPoint = NSMakePoint(drawnRect.origin.x + 0.5, drawnRect.origin.y + 0.5);
//	endPoint = NSMakePoint(drawnRect.origin.x + 0.5, drawnRect.origin.y + drawnRect.size.height + 0.5);
//	[NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
//	// right
//	startPoint = NSMakePoint(drawnRect.origin.x + drawnRect.size.width + 0.5, drawnRect.origin.y + 0.5);
//	endPoint = NSMakePoint(drawnRect.origin.x + drawnRect.size.width + 0.5, drawnRect.origin.y + drawnRect.size.height + 0.5);
//	[NSBezierPath strokeLineFromPoint:startPoint toPoint:endPoint];
}


@end

