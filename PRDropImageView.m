#import "PRDropImageView.h"

@implementation PRDropImageView

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    focusRing = NO;
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
}

#pragma mark - Accessors

@synthesize focusRing;

#pragma mark - Subclassing

- (void)mouseDown:(NSEvent *)theEvent {
    [[self window] makeFirstResponder:self];
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    [self setNeedsDisplay:YES];
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    if ([[event characters] length] != 1) {
        [super keyDown:event];
        return;
    }
    if ([[event characters] characterAtIndex:0] == 0x7F ||
        [[event characters] characterAtIndex:0] == 0xf728) {
        [self setObjectValue:nil];
        [self setNeedsDisplay:YES];
    } else {
        [super keyDown:event];
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    focusRing = YES;
    [self setNeedsDisplay:focusRing];
    [[NSCursor dragCopyCursor] set];
    
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric) {
        return NSDragOperationGeneric;
    } else {
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    focusRing = NO;
    [self setNeedsDisplay:YES];
    [[NSCursor arrowCursor] set];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    focusRing = NO;
    [[NSCursor arrowCursor] set];
    
    NSPasteboard *paste = [sender draggingPasteboard];
    NSString *desiredType = [paste availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
    NSData *carriedData = [paste dataForType:desiredType];
    if (!carriedData) {
        return NO;
    }

    NSImage *newImage = nil;
    if ([desiredType isEqualToString:NSTIFFPboardType]) {
        newImage = [[NSImage alloc] initWithData:carriedData];
    } else if ([desiredType isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
        if ([fileArray count] < 1) {
            return NO;
        }
        NSString *path = [fileArray objectAtIndex:0];
        newImage = [[NSImage alloc] initWithContentsOfFile:path];
    } else {
        return NO;
    }
    
    if (!newImage) {
        return NO;
    }
    [self setObjectValue:newImage];
    [self setNeedsDisplay:YES];
    return YES;
}

@end
