#import "PRLibraryViewController.h"
#import "PRInfoViewController.h"
#import "PRListViewController.h"
#import "PRAlbumListViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRNowPlayingController.h"
#import "PRLibraryViewSource.h"
#import "PRTimeFormatter2.h"
#import "PRSizeFormatter.h"
#import "PRCore.h"

@interface PRLibraryViewController ()
// Setup
- (void)updateLayout;
@end


@implementation PRLibraryViewController

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super initWithNibName:@"PRLibraryView" bundle:nil])) {return nil;}
    _core = core;
    _db = [_core db];
    _now = [_core now];
    infoViewController = [[PRInfoViewController alloc] initWithCore:core];
    _currentList = nil;
    return self;
}

- (void)dealloc {
    [infoViewController release];
    [listViewController release];
    [albumListViewController release];
    [super dealloc];
}

- (void)awakeFromNib {	
    [paneSuperview retain];
    [centerSuperview retain];
    
	currentPaneViewController = infoViewController;
    _edit = TRUE;
    [self updateLayout];
    [self infoViewToggle];
    
    listViewController = [[PRListViewController alloc] initWithCore:_core];
    albumListViewController = [[PRAlbumListViewController alloc] initWithCore:_core];
	
	[[listViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview addSubview:[listViewController view]];
	currentViewController = listViewController;
    
    [[infoViewController view] setFrame:[paneSuperview bounds]];
    [paneSuperview addSubview:[infoViewController view]];
}

// ========================================
// Accessors

@synthesize currentViewController;
@dynamic libraryViewMode, currentList;

- (PRList *)currentList {
    return _currentList;
}

- (void)setCurrentList:(NSNumber *)list {
    if ([list isEqual:_currentList]) {
        return;
    }
    [list retain];
    [_currentList release];
    _currentList = list;
    [self setLibraryViewMode:[self libraryViewMode]];
}

- (PRLibraryViewMode)libraryViewMode {
    if (!_currentList) {
        return -1;
    }
	return [[_db playlists] viewModeForList:_currentList];
}

- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode {   
	[listViewController setCurrentList:nil];
	[albumListViewController setCurrentList:nil];
    
    [[_db playlists] setViewMode:libraryViewMode forList:_currentList];
    
	id oldViewController = currentViewController;
	if (libraryViewMode == PRListMode) {
		currentViewController = listViewController;
	} else if (libraryViewMode == PRAlbumListMode) {
		currentViewController = albumListViewController;
	}
	
	[[currentViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview replaceSubview:[oldViewController view] with:[currentViewController view]];    
	[currentViewController setCurrentList:_currentList];    
    
    [[NSNotificationCenter defaultCenter] postPlaylistChanged:[_currentList intValue]];
    [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
}

- (void)setLibraryViewModeAction:(id)sender {
    [self setLibraryViewMode:[sender tag]];
}

- (void)setListMode {
    [self setLibraryViewMode:PRListMode];
}

- (void)setAlbumListMode {
    [self setLibraryViewMode:PRAlbumListMode];
}

- (void)infoViewToggle {
    _edit = !_edit;
    [self updateLayout];
    [[NSNotificationCenter defaultCenter] postInfoViewVisibleChanged];
}

- (BOOL)infoViewVisible {
    return _edit;
}

// ========================================
// Setup

- (void)updateLayout {
    if (_edit) {
        // pane
        NSRect frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = 140;
        [paneSuperview removeFromSuperview];
        [[self view] addSubview:paneSuperview];
        [paneSuperview setFrame:frame];
        
        // center
        frame.origin.x = 0;
        frame.origin.y = [paneSuperview frame].size.height;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = [[self view] frame].size.height - [paneSuperview frame].size.height;
        [centerSuperview setFrame:frame];
    } else {
        // pane
        [paneSuperview removeFromSuperview];
        
        // center
        NSRect frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = [[self view] frame].size.height;
        [centerSuperview setFrame:frame];
    }
}

// ========================================
// Action

- (void)highlightFile:(PRFile)file {
	[currentViewController highlightFile:file];
}

// ========================================
// Menu

- (NSMenu *)libraryViewMenu {
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    NSImage *image;
    if ([self libraryViewMode] == PRListMode) {
        image = [NSImage imageNamed:@"List.png"];
    } else {
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
