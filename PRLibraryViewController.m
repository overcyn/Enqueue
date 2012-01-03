#import "PRLibraryViewController.h"
#import "PRInfoViewController.h"
#import "PRListViewController.h"
#import "PRAlbumListViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRNowPlayingController.h"
#import "PRLibraryViewSource.h"
#import "PRTimeFormatter2.h"
#import "PRSizeFormatter.h"
#import "PRCore.h"


@implementation PRLibraryViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    if (!(self = [super initWithNibName:@"PRLibraryView" bundle:nil])) {return nil;}
    core = [core_ retain];
    db = [[core db] retain];
    now = [[core now] retain];
    infoViewController = [[PRInfoViewController alloc] initWithCore:core];
    
    playlist = -1;
    return self;
}

- (void)dealloc
{
    [infoViewController release];
    [listViewController release];
    [albumListViewController release];
    [db release];
    [now release];
    [super dealloc];
}

- (void)awakeFromNib
{	
    [paneSuperview retain];
    [centerSuperview retain];
    
	// Panes. Toggle on init to set initial frame
	currentPaneViewController = infoViewController;
    _edit = TRUE;
    [self updateLayout];
    [self infoViewToggle];
    
	// ListView
	listViewController = [[PRListViewController alloc] initWithDb:db 
                                             nowPlayingController:now
                                            libraryViewController:self];
	// AlbumListView
	albumListViewController = [[PRAlbumListViewController alloc] initWithDb:db
                                                       nowPlayingController:now
                                                      libraryViewController:self];
	
	[[listViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview addSubview:[listViewController view]];
	currentViewController = listViewController;
    
    [[infoViewController view] setFrame:[paneSuperview bounds]];
    [paneSuperview addSubview:[infoViewController view]];
}

// ========================================
// Accessors
// ========================================

@synthesize currentViewController;

- (void)setPlaylist:(PRPlaylist)newPlaylist;
{
	if (playlist == newPlaylist) {
		return;
	}
	playlist = newPlaylist;
	[self setLibraryViewMode:[self libraryViewMode]];
}

- (PRLibraryViewMode)libraryViewMode
{
    if (playlist == -1) {
        return -1;
    }
	return [[db playlists] libraryViewModeForPlaylist:playlist];
}

- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode
{   
	[listViewController setCurrentPlaylist:-1];
	[albumListViewController setCurrentPlaylist:-1];
    
    [[db playlists] setValue:[NSNumber numberWithInt:libraryViewMode] 
                 forPlaylist:playlist 
                   attribute:PRLibraryViewModePlaylistAttribute];
    
	id oldViewController = currentViewController;
	if (libraryViewMode == PRListMode) {
		currentViewController = listViewController;
	} else if (libraryViewMode == PRAlbumListMode) {
		currentViewController = albumListViewController;
	}
	
	[[currentViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview replaceSubview:[oldViewController view] with:[currentViewController view]];    
	[currentViewController setCurrentPlaylist:playlist];    
    
    [[NSNotificationCenter defaultCenter] postPlaylistChanged:playlist];
    [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
}

- (void)setLibraryViewModeAction:(id)sender
{
    [self setLibraryViewMode:[sender tag]];
}

- (void)setListMode
{
    [self setLibraryViewMode:PRListMode];
}

- (void)setAlbumListMode
{
    [self setLibraryViewMode:PRAlbumListMode];
}

// ========================================
// UI
// ========================================

- (void)updateLayout
{
    if (_edit) {
        // PANE
        NSRect frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = 140;
        [paneSuperview removeFromSuperview];
        [[self view] addSubview:paneSuperview];
        [paneSuperview setFrame:frame];
        
        // CENTER
        frame.origin.x = 0;
        frame.origin.y = [paneSuperview frame].size.height;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = [[self view] frame].size.height - [paneSuperview frame].size.height;
        [centerSuperview setFrame:frame];
    } else {
        // PANE
        [paneSuperview removeFromSuperview];
        
        // CENTER
        NSRect frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = [[self view] frame].size.height;
        [centerSuperview setFrame:frame];
    }
}

- (void)infoViewToggle
{
    _edit = !_edit;
    [self updateLayout];
    [[NSNotificationCenter defaultCenter] postInfoViewVisibleChanged];
}

- (BOOL)infoViewVisible
{
    return _edit;
}

- (void)highlightFile:(PRFile)file
{
	[currentViewController highlightFile:file];
}

- (NSMenu *)libraryViewMenu
{
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    NSImage *image;
    if ([self libraryViewMode] == PRListMode) {
        image = [NSImage imageNamed:@"List.png"];
    } else { // Album List
        image = [NSImage imageNamed:@"AlbumList.png"];
    }
    [item setImage:image];
    [menu addItem:item];
    item = [[[NSMenuItem alloc] initWithTitle:@"View As..." action:nil keyEquivalent:@""] autorelease];
    [item setEnabled:FALSE];
    [menu addItem:item];
    item = [[[NSMenuItem alloc] initWithTitle:@"List" action:@selector(setLibraryViewModeAction:) keyEquivalent:@""] autorelease];
    [item setTag:PRListMode];
    if ([self libraryViewMode] == PRListMode) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    item = [[[NSMenuItem alloc] initWithTitle:@"Album List" action:@selector(setLibraryViewModeAction:) keyEquivalent:@""] autorelease];
    [item setTag:PRAlbumListMode];
    if ([self libraryViewMode] == PRAlbumListMode) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    [menu addItem:[NSMenuItem separatorItem]];
    item = [[[NSMenuItem alloc] initWithTitle:@"Browser" action:nil keyEquivalent:@""] autorelease];
    [item setSubmenu:[[self currentViewController] browserHeaderMenu]];
    [menu addItem:item];
    
    for (NSMenuItem *i in [menu itemArray]) {
        [i setTarget:self];
    }
    return menu;
}

@end
