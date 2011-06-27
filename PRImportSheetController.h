#import <Cocoa/Cocoa.h>


@interface PRImportSheetController : NSWindowController 
{
	IBOutlet NSTextField *title_;
	IBOutlet NSProgressIndicator *progress;
}

- (void)beginSheet;
- (void)endSheet;
- (void)setTitle:(NSString *)title;

@end
