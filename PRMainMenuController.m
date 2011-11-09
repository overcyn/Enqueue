#import "PRMainMenuController.h"
#import "PRCore.h"
#import "PRNowPlayingController.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRTableViewController.h"
#import "PRPlaylistsViewController.h"
#import "PRControlsViewController.h"
#import "PRNowPlayingController.h"
#import "PRMoviePlayer.h"
#import "PRFolderMonitor.h"

@implementation PRMainMenuController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    if (!(self = [super init])) {return nil;}
    core = core_;
    
    mainMenu = [core mainMenu];
    enqueueMenu = [[mainMenu itemWithTag:1] submenu];
    fileMenu = [[mainMenu itemWithTitle:@"File"] submenu];
    editMenu = [[mainMenu itemWithTitle:@"Edit"] submenu];
    viewMenu = [[mainMenu itemWithTitle:@"View"] submenu];
    controlsMenu = [[mainMenu itemWithTitle:@"Controls"] submenu];
    windowMenu = [[mainMenu itemWithTitle:@"Window"] submenu];
    helpMenu = [[mainMenu itemWithTitle:@"Help"] submenu];
    
    [fileMenu setDelegate:self];
    [enqueueMenu setDelegate:self];
    [viewMenu setDelegate:self];
    [controlsMenu setDelegate:self];
    
    // Enqueue Menu
    NSMenuItem *menuItem = [enqueueMenu itemWithTitle:@"Preferences..."];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(showPreferences)];
    
    // Library Menu
    menuItem = [fileMenu itemWithTag:1];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(newPlaylist)];
    
    menuItem = [fileMenu itemWithTag:2];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(newSmartPlaylist)];
    
    menuItem = [fileMenu itemWithTag:3];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(open)];
    
    menuItem = [fileMenu itemWithTag:4];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(itunesImport)];
    
    menuItem = [fileMenu itemWithTag:5];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(rescanLibrary)];
    
    menuItem = [fileMenu itemWithTag:6];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(duplicateFiles)];
    
    menuItem = [fileMenu itemWithTag:7];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(missingFiles)];
    
    // Edit Menu
    menuItem = [editMenu itemWithTag:8];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(find)];
    
    // View Menu
    menuItem = [viewMenu itemWithTag:1];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(viewAsList)];
    
    menuItem = [viewMenu itemWithTag:2];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(viewAsAlbumList)];
    
    menuItem = [viewMenu itemWithTag:3];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(toggleArtwork)];
    
    menuItem = [viewMenu itemWithTag:4];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(showInfo)];
    
    menuItem = [viewMenu itemWithTag:5];
    [menuItem setTarget:self];
    [menuItem setAction:@selector(showCurrentSong)];
    
    menuItem = [viewMenu itemWithTag:6];
    [menuItem setTarget:nil];
    [menuItem setAction:@selector(toggleFullScreen:)];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
        [menuItem setHidden:TRUE];
    }
    
    // Controls Menu
    menuItem = [controlsMenu itemWithTag:1];
    [menuItem setTarget:[core now]];
    [menuItem setAction:@selector(playPause)];
    
    menuItem = [controlsMenu itemWithTag:2];
    [menuItem setTarget:[core now]];
    [menuItem setAction:@selector(playNext)];
    
    menuItem = [controlsMenu itemWithTag:3];
    [menuItem setTarget:[core now]];
    [menuItem setAction:@selector(playPrevious)];
    
    menuItem = [controlsMenu itemWithTag:4];
    [menuItem setTarget:[[core now] mov]];
    [menuItem setAction:@selector(increaseVolume)];
    
    menuItem = [controlsMenu itemWithTag:5];
    [menuItem setTarget:[[core now] mov]];
    [menuItem setAction:@selector(decreaseVolume)];
    
    menuItem = [controlsMenu itemWithTag:6];
    [menuItem bind:@"value" toObject:[core now] withKeyPath:@"shuffle" options:nil];
    
    menuItem = [controlsMenu itemWithTag:7];
    [menuItem bind:@"value" toObject:[core now] withKeyPath:@"repeat" options:nil];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

// ========================================
// Update
// ========================================

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    NSString *title;
    if (![[[core now] mov] isPlaying]) {
        title = @"Play";
    } else {
        title = @"Pause";
    }
    [[controlsMenu itemWithTag:1] setTitle:title];
    if ([[core win] showsArtwork]) {
        title = @"Hide Artwork";
    } else {
        title = @"Show Artwork";
    }
    [[viewMenu itemWithTag:3] setTitle:title];
    if ([[[core win] libraryViewController] infoViewVisible]) {
        title = @"Hide Info Pane";
    } else {
        title = @"Show Info Pane";
    }
    [[viewMenu itemWithTag:4] setTitle:title];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem == [fileMenu itemWithTitle:@"Import iTunes Library"] ||
        menuItem == [fileMenu itemWithTitle:@"Add to Library…"]) {
        return [[[core opQueue] operations] count] == 0;
    }
    return TRUE;
}

// ========================================
// Action
// ========================================

- (void)showPreferences
{
    [[core win] setCurrentMode:PRPreferencesMode];
}
         
- (void)newPlaylist
{
    [[core win] setCurrentMode:PRPlaylistsMode];
    [[[core win] playlistsViewController] newStaticPlaylist];
}

- (void)newSmartPlaylist
{
    [[core win] setCurrentMode:PRPlaylistsMode];
    [[[core win] playlistsViewController] newSmartPlaylist];
}

- (void)open
{
    [core showOpenPanel:nil];
}

- (void)itunesImport
{
    [core itunesImport:nil];
}

- (void)rescanLibrary
{
    [[core folderMonitor] rescan];
}

- (void)duplicateFiles
{
    
}

- (void)missingFiles
{
    
}

- (void)find
{
    [[core win] find];
}

- (void)viewAsList
{
    [[[core win] libraryViewController] setListMode];
}

- (void)viewAsAlbumList
{
    [[[core win] libraryViewController] setAlbumListMode];
}

- (void)toggleArtwork
{
    [[core win] setShowsArtwork:![[core win] showsArtwork]];
}

- (void)showInfo
{
    [[[core win] libraryViewController] infoViewToggle];
}

- (void)showCurrentSong
{
    [[[core win] controlsViewController] showInLibrary];
}

@end
