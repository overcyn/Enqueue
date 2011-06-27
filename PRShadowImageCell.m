#import "PRShadowImageCell.h"
#import "NSImage+Extensions.h"


@implementation PRShadowImageCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{    
	NSImage *image = [self objectValue];
    NSRect inRect2 = NSInsetRect(cellFrame, 9, 9);
//    NSRect inRect2 = NSMakeRect(cellFrame.origin.x + 4, 
//                               cellFrame.origin.y + 4, 
//                               cellFrame.size.width - 8, 
//                               cellFrame.size.height - 8);
	NSRect inRect = NSMakeRect(inRect2.origin.x + 2, 
                               inRect2.origin.y + 2, 
                               inRect2.size.width - 4, 
                               inRect2.size.height - 4);
	
	// draw image
	if ([image isKindOfClass:[NSImage class]]) {
        [image setFlipped:FALSE];
        // create a destination rect scaled to fit inside the frame
        NSRect drawnRect;
        drawnRect.origin = inRect.origin;
        if ([image size].width > [image size].height) {
            drawnRect.size.height = [image size].height * inRect.size.width/[image size].width;
            drawnRect.size.width = inRect.size.width;
        } else {
            drawnRect.size.width = [image size].width * inRect.size.height/[image size].height;
            drawnRect.size.height = inRect.size.height;
        }
        
        // center it in the frame
        drawnRect.origin.x += (inRect.size.width - drawnRect.size.width)/2;
        drawnRect.origin.y += (inRect.size.height - drawnRect.size.height)/2;
        drawnRect.origin.x = floor(drawnRect.origin.x);
        drawnRect.origin.y = floor(drawnRect.origin.y);
        drawnRect.size.width = floor(drawnRect.size.width);
        drawnRect.size.height = floor(drawnRect.size.height);
        
        NSRect borderRect = 
          NSMakeRect(drawnRect.origin.x - 3, drawnRect.origin.y - 3, drawnRect.size.width + 6, drawnRect.size.height + 6);
        drawnRect = borderRect;
        
        // drawBorder
        [NSGraphicsContext saveGraphicsState];
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0.0, -2.0)];
        [shadow setShadowBlurRadius:4.5];
        [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.7]];	
        [shadow set];
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:borderRect];
        [NSGraphicsContext restoreGraphicsState];
        
        // draw image
        [image drawInRect:drawnRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
}


@end
