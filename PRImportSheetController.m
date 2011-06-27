#import "PRCore.h"
#import "PRImportSheetController.h"


@implementation PRImportSheetController

- (void)beginSheet
{
	[NSApp beginSheet:[self window] 
	   modalForWindow:[[[NSApp delegate] win] window]
        modalDelegate:self 
	   didEndSelector:NULL 
		  contextInfo:nil];
	
	[progress setUsesThreadedAnimation:TRUE];
	[progress startAnimation:self];
	
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)endSheet
{
	[[self window] orderOut:nil];
    [NSApp endSheet:[self window]];
}

- (void)setTitle:(NSString *)title
{
	[title_ setStringValue:title];
}

@end
