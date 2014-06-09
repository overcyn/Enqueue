#import "PRWelcomeSheetController.h"
#import "PRGradientView.h"
#import "PRCore.h"
#import "PRMainWindowController.h"
#import "PRPreferencesViewController.h"


@implementation PRWelcomeSheetController

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super initWithWindowNibName:@"PRWelcomeSheet"])) {return nil;}
    _core = core;
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

#pragma mark - Action

- (void)importItunes {
    [self endSheet];
    [_core itunesImport:nil];
}

- (void)openFiles {
    [self endSheet];
    [_core showOpenPanel:nil];
}

- (void)monitorFolders {
    [self endSheet];
    [[_core win] setCurrentMode:PRPreferencesMode];
    [[[_core win] preferencesViewController] addFolder];
}

@end
