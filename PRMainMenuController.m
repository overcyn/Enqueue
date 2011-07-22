#import "PRMainMenuController.h"
#import "PRCore.h"
#import "PRNowPlayingController.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRTableViewController.h"
#import "PRPlaylistsViewController.h"
#import "PRControlsViewController.h"

@implementation PRMainMenuController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    self = [super init];
    if (self) {
        core = core_;
        
        mainMenu = [core mainMenu];
        enqueueMenu = [[mainMenu itemWithTag:1] submenu];
        libraryMenu = [[mainMenu itemWithTitle:@"File"] submenu];
        editMenu = [[mainMenu itemWithTitle:@"Edit"] submenu];
        viewMenu = [[mainMenu itemWithTitle:@"View"] submenu];
        controlsMenu = [[mainMenu itemWithTitle:@"Controls"] submenu];
        windowMenu = [[mainMenu itemWithTitle:@"Window"] submenu];
        helpMenu = [[mainMenu itemWithTitle:@"Help"] submenu];
        
        [libraryMenu setDelegate:self];
        [enqueueMenu setDelegate:self];
        [viewMenu setDelegate:self];
        
        // Enqueue Menu
        NSMenuItem *menuItem = [enqueueMenu itemWithTitle:@"Preferences..."];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(showPreferences)];
        
        // Library Menu
        menuItem = [libraryMenu itemWithTitle:@"New Playlist"];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(newPlaylist)];
        
        menuItem = [libraryMenu itemWithTitle:@"Add to Library…"];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(openFiles)];
        
        menuItem = [libraryMenu itemWithTitle:@"Import iTunes Library"];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(itunesImport)];
        
        menuItem = [libraryMenu itemWithTitle:@"Get Album Art"];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(addToLibrary)];
        
        // Edit Menu
        menuItem = [editMenu itemWithTitle:@"Find"];
        [menuItem setTarget:[core win]];
        [menuItem setAction:@selector(find)];
        
        // View Menu
        menuItem = [viewMenu itemWithTitle:@"as List"];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(viewAsList)];
        
        menuItem = [viewMenu itemWithTitle:@"as Album List"];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(viewAsAlbumList)];
        
        menuItem = [viewMenu itemWithTag:1]; // Toggle artwork
        [menuItem setTarget:self];
        [menuItem setAction:@selector(toggleArtwork)];
        
        menuItem = [viewMenu itemWithTag:2]; // Toggle Info
        [menuItem setTarget:self];
        [menuItem setAction:@selector(showInfo)];
        
        menuItem = [viewMenu itemWithTitle:@"Show Current Song"];
        [menuItem setTarget:self];
        [menuItem setAction:@selector(showCurrentSong)];
        
        // Controls Menu
        menuItem = [controlsMenu itemWithTitle:@"Play/Pause"];
        [menuItem setTarget:[core now]];
        [menuItem setAction:@selector(playPause)];
        
        menuItem = [controlsMenu itemWithTitle:@"Next"];
        [menuItem setTarget:[core now]];
        [menuItem setAction:@selector(playNext)];
        
        menuItem = [controlsMenu itemWithTitle:@"Previous"];
        [menuItem setTarget:[core now]];
        [menuItem setAction:@selector(playPrevious)];
        
        menuItem = [controlsMenu itemWithTitle:@"Increase Volume"];
        [menuItem setTarget:[[core now] mov]];
        [menuItem setAction:@selector(increaseVolume)];
        
        menuItem = [controlsMenu itemWithTitle:@"Decrease Volume"];
        [menuItem setTarget:[[core now] mov]];
        [menuItem setAction:@selector(decreaseVolume)];
        
        menuItem = [controlsMenu itemWithTitle:@"Shuffle"];
        [menuItem bind:@"value" toObject:[core now] withKeyPath:@"shuffle" options:nil];
        
        menuItem = [controlsMenu itemWithTitle:@"Repeat"];
        [menuItem bind:@"value" toObject:[core now] withKeyPath:@"repeat" options:nil];
    }
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
    if ([[core win] showsArtwork]) {
        title = @"Hide Artwork";
    } else {
        title = @"Show Artwork";
    }
    [[viewMenu itemWithTag:1] setTitle:title];
    if ([[[core win] libraryViewController] infoViewVisible]) {
        title = @"Hide Info";
    } else {
        title = @"Show Info";
    }
    [[viewMenu itemWithTag:2] setTitle:title];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem == [libraryMenu itemWithTitle:@"Import iTunes Library"] ||
        menuItem == [libraryMenu itemWithTitle:@"Add to Library…"]) {
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

- (void)itunesImport
{
    [core itunesImport:nil];
}

- (void)openFiles
{
    [core showOpenPanel:nil];
}

- (void)viewAsList
{
    [[[core win] libraryViewController] setListMode];
}

- (void)viewAsAlbumList
{
    [[[core win] libraryViewController] setAlbumListMode];
}

- (void)browserOnTop
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:-1]];
    [(PRTableViewController *)[[[core win] libraryViewController] currentViewController] toggleBrowser:menuItem];
}

- (void)browserOnLeft
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:-2]];
    [(PRTableViewController *)[[[core win] libraryViewController] currentViewController] toggleBrowser:menuItem];
}

- (void)browserHidden
{
    [[[core win] libraryViewController] currentViewController];
}

- (void)browserToggleGenre
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:13]];
    [(PRTableViewController *)[[[core win] libraryViewController] currentViewController] toggleBrowser:menuItem];
}

- (void)browserToggleComposer
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:8]];
    [(PRTableViewController *)[[[core win] libraryViewController] currentViewController] toggleBrowser:menuItem];

}

- (void)browserToggleArtist
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:2]];
    [(PRTableViewController *)[[[core win] libraryViewController] currentViewController] toggleBrowser:menuItem];
}

- (void)browserToggleAlbum
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:3]];
    [(PRTableViewController *)[[[core win] libraryViewController] currentViewController] toggleBrowser:menuItem];
}

- (void)showCurrentSong
{
    [[[core win] controlsViewController] showInLibrary];
}

- (void)showInfo
{
    [[[core win] libraryViewController] infoViewToggle];
}

- (void)toggleArtwork
{
    [[core win] setShowsArtwork:![[core win] showsArtwork]];
}

@end
