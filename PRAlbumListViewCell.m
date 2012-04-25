#import "PRAlbumListViewCell.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "NSImage+Extensions.h"
#import "PRUserDefaults.h"


@implementation PRAlbumListViewCell

- (void)drawInteriorWithFrame:(NSRect)theCellFrame inView:(NSView *)theControlView {
	NSDictionary *dict = [self objectValue];
	PRDb *db = [dict objectForKey:@"db"];
    PRItem *item = [dict objectForKey:@"file"];
    NSImage *icon = [dict objectForKey:@"icon"];
    if (!icon || ![icon isValid]) {
        icon = [NSImage imageNamed:@"PRLightAlbumArt"];
    }
    
    NSString *artist = [[db library] artistValueForItem:item];
	NSString *album = [[db library] valueForItem:item attr:PRItemAttrAlbum];
	NSNumber *year = [[db library] valueForItem:item attr:PRItemAttrYear];
    if ([[[db library] valueForItem:item attr:PRItemAttrCompilation] boolValue] && [[PRUserDefaults userDefaults] useCompilation]) {
        artist = @"Compilation";
    }
    
	// Inset the cell frame to give everything a little horizontal padding
	NSRect insetRect = NSInsetRect(theCellFrame, 10, 9);
	NSSize iconSize = NSMakeSize(150, 150);
    [icon setFlipped:TRUE];
	
	// Make attributes for our strings	
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
	
	NSDictionary *titleAttributes = @{NSFontAttributeName:[NSFont boldSystemFontOfSize:11],
NSParagraphStyleAttributeName:paragraphStyle,
NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]};
	NSDictionary *subtitleAttributes = @{NSFontAttributeName:[NSFont systemFontOfSize:11],
NSParagraphStyleAttributeName:paragraphStyle,
NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]};
	
	// Make a Title string
	NSString *title = artist;
    NSString *subtitle = album;
	NSString *subSubtitle = [year stringValue];
    if ([title isEqualToString:@""]) {
        title = @"Unknown Artist";
    }
    if ([subtitle isEqualToString:@""]) {
        subtitle = @"Unknown Album";
    }
    if ([subSubtitle isEqualToString:@"0"]) {
        subSubtitle = @"";
    }
	
	// get the size of the string for layout
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];
	NSSize subtitleSize = [subtitle sizeWithAttributes:subtitleAttributes];
	NSSize subSubtitleSize = [subSubtitle sizeWithAttributes:subtitleAttributes];
	
	// Vertical padding between the lines of text
    // Horizontal padding between icon and text
	float verticalPadding = 0.0;
	float subVerticalPadding = 1.0;
	
	// Icon box: center the icon vertically inside of the inset rect
	NSRect iconBox = NSMakeRect(insetRect.origin.x, insetRect.origin.y, iconSize.width, iconSize.height);
	
	// Make a box for our text
	// Place it next to the icon with horizontal padding
	// Size it horizontally to fill out the rest of the inset rect
	// Center it vertically inside of the inset rect
	float combinedHeight = titleSize.height + subtitleSize.height + subSubtitleSize.height + 2 * subVerticalPadding;
    
    NSRect textBox = NSMakeRect(insetRect.origin.x, insetRect.origin.y + iconBox.size.height + verticalPadding,
                                iconSize.width, combinedHeight);
    
	// Now split the text box in half and put the title box in the top half and subtitle box in bottom half
	NSRect titleBox = NSMakeRect(textBox.origin.x, textBox.origin.y, textBox.size.width, titleSize.height);
	NSRect subtitleBox = NSMakeRect(textBox.origin.x, textBox.origin.y + titleSize.height + subVerticalPadding,
                                    textBox.size.width, subtitleSize.height);
    
    NSImage *image = icon;
    NSRect inRect = NSInsetRect(iconBox, 7, 7);
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
    
    // drawBorder
    [NSGraphicsContext saveGraphicsState];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowOffset:NSMakeSize(0.0, -2.0)];
    [shadow setShadowBlurRadius:5];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.4]];	
    [shadow set];
    [image drawInRect:drawnRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0]; 
    [NSGraphicsContext restoreGraphicsState];
    
	// draw the text
	[title drawInRect:titleBox withAttributes:titleAttributes];
	[subtitle drawInRect:subtitleBox withAttributes:subtitleAttributes];
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view {
    return NSZeroRect;
}

@end
