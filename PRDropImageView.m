#import "PRDropImageView.h"

@implementation PRDropImageView

// ========================================
// Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    focusRing = FALSE;
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
}

// ========================================
// Accessors

@synthesize focusRing;

// ========================================
// Subclassing

- (void)mouseDown:(NSEvent *)theEvent {
    [[self window] makeFirstResponder:self];
}

- (BOOL)acceptsFirstResponder {
    return TRUE;
}

- (BOOL)becomeFirstResponder {
    [self setNeedsDisplay:TRUE];
    return TRUE;
}

- (void)keyDown:(NSEvent *)event {
    if ([[event characters] length] != 1) {
        [super keyDown:event];
        return;
    }
	if ([[event characters] characterAtIndex:0] == 0x7F ||
        [[event characters] characterAtIndex:0] == 0xf728) {
        [self setObjectValue:nil];
        [self setNeedsDisplay:TRUE];
    } else {
		[super keyDown:event];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    focusRing = TRUE;
    [self setNeedsDisplay:focusRing];
    [[NSCursor dragCopyCursor] set];
    
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric) {
        return NSDragOperationGeneric;
    } else {
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    focusRing = FALSE;
    [self setNeedsDisplay:TRUE];
    [[NSCursor arrowCursor] set];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    focusRing = FALSE;
    [[NSCursor arrowCursor] set];
    
    NSPasteboard *paste = [sender draggingPasteboard];
    NSString *desiredType = [paste availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
    NSData *carriedData = [paste dataForType:desiredType];
    if (!carriedData) {
        return FALSE;
    }

    NSImage *newImage = nil;
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
    [self setObjectValue:newImage];
    [self setNeedsDisplay:TRUE];
    return TRUE;
}

@end
