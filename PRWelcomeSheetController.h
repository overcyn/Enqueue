#import <Cocoa/Cocoa.h>
@class PRCore;
@class PRGradientView;


@interface PRWelcomeSheetController : NSWindowController 
{   
    IBOutlet PRGradientView *background;
    IBOutlet NSButton *closeButton;
    IBOutlet NSButton *importItunesButton;
    IBOutlet NSButton *openFilesButton;
    IBOutlet NSButton *monitorFoldersButton;
    
    PRCore *core;
}

// ========================================

- (id)initWithCore:(PRCore *)core_;

// ========================================
// Action

- (void)beginSheetForWindow:(NSWindow *)window;

- (void)importItunes;
- (void)openFiles;
- (void)monitorFolders;
- (void)endSheet;

@end
