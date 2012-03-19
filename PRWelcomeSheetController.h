#import <Cocoa/Cocoa.h>
#import "PRAlertWindowController.h"
@class PRCore, PRGradientView;


@interface PRWelcomeSheetController : PRAlertWindowController {
    __weak PRCore *_core;
    
    IBOutlet PRGradientView *background;
    IBOutlet NSButton *closeButton;
    IBOutlet NSButton *importItunesButton;
    IBOutlet NSButton *openFilesButton;
    IBOutlet NSButton *monitorFoldersButton;
}
// Initialization
- (id)initWithCore:(PRCore *)core_;

// Action
- (void)importItunes;
- (void)openFiles;
- (void)monitorFolders;
@end
