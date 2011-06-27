#import "PRPlaylistsCell.h"
#import "PRPlaylistsViewController.h"


@implementation PRPlaylistsCell

// ========================================
// Drawing
// ========================================

- (void)drawWithFrame:(NSRect)theCellFrame inView:(NSView *)theControlView
{
    if ([[self objectValue] isKindOfClass:[NSString class]]) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRect frame = theCellFrame;
        frame = NSInsetRect(frame, 10, 8);
        [[NSBezierPath bezierPathWithRect:frame] fill];
        [NSGraphicsContext restoreGraphicsState];
        return;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	NSDictionary *dict = [self objectValue];
	NSString *title = [dict objectForKey:@"title"];
	NSString *subtitle = [dict objectForKey:@"subtitle"];
	NSImage *icon = [dict objectForKey:@"icon"];
	NSSize iconSize = NSMakeSize(17, 17);
	[icon setFlipped:YES];
    
    if ([[dict objectForKey:@"mouseOver"] boolValue]) {
        NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                                 [NSColor colorWithDeviceRed:212.0/255.0 green:233.0/255.0 blue:246.0/255.0 alpha:0.4], 0.0, 
                                 [NSColor colorWithDeviceRed:212.0/255.0 green:233.0/255.0 blue:246.0/255.0 alpha:0.6], 1.0,
                                 nil] autorelease];
        [gradient drawInRect:theCellFrame angle:90.0];
    }
    
    // Draw dropdown button
    NSRect rect = theCellFrame;
    rect.origin.x += rect.size.width - 40;
    rect.origin.y += rect.size.height/2 - 10;
    rect.size.width = 21;
    rect.size.height = 21;
    
    if ([[dict objectForKey:@"mouseOver"] boolValue]) {        
        NSImage *image;
        if (NSPointInRect([[dict objectForKey:@"point"] pointValue], rect)) {
            image = [NSImage imageNamed:@"PRActionIcon3"];
        } else {
            image = [NSImage imageNamed:@"PRActionIcon2"];
        }
        [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    } else {
    }
    
    // Draw rest of button
    theCellFrame.size.height -= 6;
    theCellFrame.origin.y += 3;
    theCellFrame.size.width -= 50;
    
    // paragraph style
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
    [shadow setShadowOffset:NSMakeSize(1.0, -1.1)];
    
    NSMutableDictionary *titleAttributes = 
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
         [NSFont fontWithName:@"HelveticaNeue-Medium" size:12], NSFontAttributeName,
         paragraphStyle, NSParagraphStyleAttributeName,
         [NSColor colorWithDeviceWhite:0.2 alpha:1.0], NSForegroundColorAttributeName,
         shadow, NSShadowAttributeName,
         nil];
    NSMutableDictionary *subtitleAttributes = 
        [NSMutableDictionary dictionaryWithObjectsAndKeys:
         [NSFont fontWithName:@"HelveticaNeue" size:11], NSFontAttributeName,
         paragraphStyle, NSParagraphStyleAttributeName,
         [NSColor colorWithDeviceWhite:0.5 alpha:1.0], NSForegroundColorAttributeName,
         nil];
    
    // Inset the cell frame to give everything a little horizontal padding
	NSRect insetRect = NSInsetRect(theCellFrame, 5, 0);
    insetRect.origin.x += 5;
    insetRect.size.width -= 5;
    
	// get the size of the string for layout
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];
    NSSize subtitleSize = [subtitle sizeWithAttributes:subtitleAttributes];
	
	// Vertical padding between the lines of text 	
	// Horizontal padding between icon and text
	float verticalPadding = 0.0;
	float horizontalPadding = 10;
	
	// Icon box: center the icon vertically inside of the inset rect
	NSRect iconBox = NSMakeRect(insetRect.origin.x,
								insetRect.origin.y + insetRect.size.height*.5 - iconSize.height*.5,
								iconSize.width,
								iconSize.height);
	
	// Make a box for our text
	// Place it next to the icon with horizontal padding
	// Size it horizontally to fill out the rest of the inset rect
	// Center it vertically inside of the inset rect
	float aCombinedHeight = titleSize.height + subtitleSize.height + verticalPadding;
	
	NSRect aTextBox = NSMakeRect(iconBox.origin.x + iconBox.size.width + horizontalPadding,
								 insetRect.origin.y + insetRect.size.height * .5 - aCombinedHeight * .5 - 2,
								 insetRect.size.width - iconSize.width - horizontalPadding,
								 aCombinedHeight);
    NSRect aTitleBox = NSMakeRect(aTextBox.origin.x, 
                                  aTextBox.origin.y + aTextBox.size.height / 2 - titleSize.height + 4,
                                  aTextBox.size.width, titleSize.height);
    NSRect aSubtitleBox = NSMakeRect(aTextBox.origin.x,
                                     aTextBox.origin.y + aTextBox.size.height*.5 + 2,
                                     aTextBox.size.width, subtitleSize.height);
    
    if (!subtitle) {
        aTitleBox = NSMakeRect(aTextBox.origin.x, 
                               aTextBox.origin.y + (aTextBox.size.height - titleSize.height) / 2,
                               aTextBox.size.width, titleSize.height);
    }
    
    [title drawInRect:aTitleBox withAttributes:titleAttributes];
    [subtitle drawInRect:aSubtitleBox withAttributes:subtitleAttributes];
	[icon drawInRect:iconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [pool drain];
}

// ========================================
// Misc
// ========================================

- (NSMenu *)menuForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)view
{
    NSRect rect = cellFrame;
    rect.origin.x += rect.size.width - 40;
    rect.origin.y += rect.size.height/2 - 10;
    rect.size.width = 21;
    rect.size.height = 21;
    
    if (!NSPointInRect([[self controlView] convertPointFromBase:[event locationInWindow]], rect)) {
        return nil;
    }
    
    NSMenu *menu_ = [[[NSMenu alloc] initWithTitle:@"Menu"] autorelease];
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Duplicate" action:@selector(duplicatePlaylistMenuAction:) keyEquivalent:@""] autorelease];
    int playlist = [[[self objectValue] objectForKey:@"playlist"] intValue];
    [menu_ addItem:menuItem];
    if ([[[self objectValue] objectForKey:@"delete"] boolValue]) {
        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Rename" action:@selector(renamePlaylistMenuAction:) keyEquivalent:@""] autorelease];
        [menu_ addItem:menuItem];
        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(deletePlaylistMenuAction:) keyEquivalent:@""] autorelease];
        [menu_ addItem:menuItem];
    }
    for (NSMenuItem *i in [menu_ itemArray]) {
        [i setTarget:[self target]];
        [i setTag:playlist];
    }
    
    return menu_;
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)fieldEditor
{
    [super setUpFieldEditorAttributes:fieldEditor];
    [fieldEditor setDrawsBackground:FALSE];
    [self setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:15]];
    
//    if ([fieldEditor isKindOfClass:[NSTextView class]]) {
//        [(NSTextView *)fieldEditor setTextContainerInset:NSMakeSize(10, 9)];
//    }
    return fieldEditor;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
    return NSInsetRect(theRect, 10, 9);
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    [super selectWithFrame:NSInsetRect(aRect, 10, 9) 
                    inView:controlView 
                    editor:textObj 
                  delegate:anObject 
                     start:selStart 
                    length:selLength];
}

@end
