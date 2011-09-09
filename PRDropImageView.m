#import "PRDropImageView.h"

@implementation PRDropImageView

- (id)init
{
    self = [super init];
    if (self) {
        focusRing = FALSE;
    }
    return self;
}

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
}

@synthesize focusRing;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    focusRing = TRUE;
    [self setNeedsDisplay:focusRing];
    [[NSCursor dragCopyCursor] set];
    
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric) {
        return NSDragOperationGeneric;
    } else {
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    focusRing = FALSE;
    [self setNeedsDisplay:TRUE];
    [[NSCursor arrowCursor] set];
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    focusRing = FALSE;
    [self setNeedsDisplay:focusRing];
    [[NSCursor arrowCursor] set];
    
    NSPasteboard *paste = [sender draggingPasteboard];
    NSString *desiredType = [paste availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
    NSData *carriedData = [paste dataForType:desiredType];
    if (!carriedData) {
        return FALSE;
    }

    NSImage *newImage;
    if ([desiredType isEqualToString:NSTIFFPboardType]) {
        newImage = [[[NSImage alloc] initWithData:carriedData] autorelease];
    } else if ([desiredType isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
        if ([fileArray count] < 1) {
            return FALSE;
        }
        NSString *path = [fileArray objectAtIndex:0];
        newImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
    } else {
        return FALSE;
    }
    
    if (!newImage) {
        return FALSE;
    }
    [self setImage:newImage];
    [self setNeedsDisplay:YES];
    return TRUE;
}

@end
