#import "PRWelcomeSheetController.h"
#import "PRGradientView.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRPreferencesViewController.h"


@implementation PRWelcomeSheetController

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core_ {
    self = [super initWithWindowNibName:@"PRWelcomeSheet"];
    if (self) {
        core = core_;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [background setTopGradient:[NSColor colorWithDeviceWhite:1.0 alpha:1.0]];
    [background setBotGradient:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
    
    [importItunesButton setTarget:self];
    [importItunesButton setAction:@selector(importItunes)];
    [importItunesButton setShowsBorderOnlyWhileMouseInside:TRUE];
    [openFilesButton setTarget:self];
    [openFilesButton setAction:@selector(openFiles)];
    [openFilesButton setShowsBorderOnlyWhileMouseInside:TRUE];
    [monitorFoldersButton setTarget:self];
    [monitorFoldersButton setAction:@selector(monitorFolders)];
    [monitorFoldersButton setShowsBorderOnlyWhileMouseInside:TRUE];
    [closeButton setTarget:self];
    [closeButton setAction:@selector(endSheet)];
}

// ========================================
// Action

- (void)beginSheetForWindow:(NSWindow *)window {
    [NSApp beginSheet:[self window] modalForWindow:window modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (void)importItunes {
    [self endSheet];
    [core itunesImport:nil];
}

- (void)openFiles {
    [self endSheet];
    [core showOpenPanel:nil];
}

- (void)monitorFolders {
    [self endSheet];
    [[core win] setCurrentMode:PRPreferencesMode];
    [[[core win] preferencesViewController] addFolder];
}

- (void)endSheet {
    [[self window] orderOut:nil];
    [NSApp endSheet:[self window]];
}

@end
