#import "PRLibraryViewController.h"
#import "PRAlbumListViewController.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRInfoViewController.h"
#import "PRLibrary.h"
#import "PRLibraryViewSource.h"
#import "PRListViewController.h"
#import "PRNowPlayingController.h"
#import "PRPlaylists.h"
#import "PRSizeFormatter.h"
#import "PRStringFormatter.h"
#import "PRTimeFormatter2.h"


#define SEARCH_DELAY 0.25


@interface PRLibraryViewController () <NSMenuDelegate, NSTextFieldDelegate>
@end

@implementation PRLibraryViewController {
    __weak PRCore *_core;
    
    NSView *_centerSuperview;
    NSView *_paneSuperview;
    NSView *_headerView;
    NSButton *_infoButton;
    NSPopUpButton *_libraryPopUpButton;
    NSSearchField *_searchField;
    
    NSMenu *_libraryPopUpButtonMenu;
    
    PRInfoViewController *infoViewController;
    PRListViewController *listViewController;
    PRAlbumListViewController *albumListViewController;
    
    NSDate *_searchFieldLastEdit;
    
    BOOL _infoViewVisible;
    PRList *_currentList;
    __weak PRTableViewController *_currentViewController;
}

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _currentList = [[[_core db] playlists] libraryList];
    return self;
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setView:view];
    
    // Center view
    _centerSuperview = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
    [_centerSuperview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[self view] addSubview:_centerSuperview];
    
    listViewController = [[PRListViewController alloc] initWithCore:_core];
    [[listViewController view] setFrame:[_centerSuperview bounds]];
    [_centerSuperview addSubview:[listViewController view]];
    _currentViewController = listViewController;
    
    albumListViewController = [[PRAlbumListViewController alloc] initWithCore:_core];
    
    // Pane view
    _paneSuperview = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 500, 140)];
    [_paneSuperview setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    _infoViewVisible = NO;
    
    infoViewController = [[PRInfoViewController alloc] initWithCore:_core];
    [[infoViewController view] setFrame:[_paneSuperview bounds]];
    [_paneSuperview addSubview:[infoViewController view]];
    
    // Header view
    _libraryPopUpButtonMenu = [[NSMenu alloc] init];
    [_libraryPopUpButtonMenu setDelegate:self];
    [_libraryPopUpButtonMenu setAutoenablesItems:NO];
    
    _headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 250, 30)];
    _infoButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 3, 25, 27)];
    [_infoButton setBordered:NO];
    [_infoButton setTarget:self];
    [_infoButton setAction:@selector(toggleInfoViewVisible)];
    [_infoButton setButtonType:NSMomentaryChangeButton];
    [_infoButton setToolTip:@"Toggle tag editor."];
    [_headerView addSubview:_infoButton];
    
    _libraryPopUpButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(24, 4, 35, 26)];
    [_libraryPopUpButton setMenu:_libraryPopUpButtonMenu];
    [_libraryPopUpButton setBordered:NO];
    [_libraryPopUpButton setPullsDown:YES];
    [_libraryPopUpButton setToolTip:@"Change the layout of the library."];
    [[_libraryPopUpButton cell] setArrowPosition:NSPopUpNoArrow];
    [_headerView addSubview:_libraryPopUpButton];
    
    _searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(66, 6, 145, 19)];
    [_searchField setDelegate:self];
    [_searchField setToolTip:@"Search for songs."];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
        [_searchField setFocusRingType:NSFocusRingTypeNone];
    }
    [[_searchField cell] setControlSize:NSSmallControlSize];
    PRStringFormatter *stringFormatter = [[PRStringFormatter alloc] init];
    [stringFormatter setMaxLength:80];
    [_searchField setFormatter:stringFormatter];
    [_headerView addSubview:_searchField];
    
    // Initialization
    [self updateLayout];
    _currentList = nil;
    [self setCurrentList:[[[_core db] playlists] libraryList]];
    
    // Key View
    [_searchField setNextKeyView:[self lastKeyView]];
    
    // Update
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(updateSearch)];
}

#pragma mark - Accessors

@synthesize currentViewController = _currentViewController;
@synthesize headerView = _headerView;

- (PRList *)currentList {
    return _currentList;
}

- (void)setCurrentList:(PRList *)list {
    if ([list isEqual:_currentList]) {
        return;
    }
    _currentList = list;
    [self setLibraryViewMode:[[[_core db] playlists] viewModeForList:_currentList]];
    [self updateSearch];
    [self menuNeedsUpdate:_libraryPopUpButtonMenu];
    [NSNotificationCenter post:PRCurrentListDidChangeNotification];
}

- (PRLibraryViewMode)libraryViewMode {
    if (_currentViewController == listViewController) {
        return PRListMode;
    } else if (_currentViewController == albumListViewController) {
        return PRAlbumListMode;
    } else {
        @throw NSInternalInconsistencyException;
    }
}

- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode {
    [listViewController setCurrentList:nil];
    [albumListViewController setCurrentList:nil];
    
    [[[_core db] playlists] setViewMode:libraryViewMode forList:_currentList];
    
    id oldViewController = _currentViewController;
    if (libraryViewMode == PRListMode) {
        _currentViewController = listViewController;
    } else if (libraryViewMode == PRAlbumListMode) {
        _currentViewController = albumListViewController;
    } else {
        @throw NSInvalidArgumentException;
    }
    
    [[_currentViewController view] setFrame:[_centerSuperview bounds]];
    [_centerSuperview replaceSubview:[oldViewController view] with:[_currentViewController view]];    
    [_currentViewController setCurrentList:_currentList];
    [self menuNeedsUpdate:_libraryPopUpButtonMenu];
    [[self firstKeyView] setNextKeyView:[_currentViewController firstKeyView]];
    [[_currentViewController lastKeyView] setNextKeyView:_searchField];
}

- (BOOL)infoViewVisible {
    return _infoViewVisible;
}

- (void)setInfoViewVisible:(BOOL)visible {
    if (_infoViewVisible == visible) {
        return;
    }
    _infoViewVisible = visible;
    [self updateLayout];
}

- (void)toggleInfoViewVisible {
    [self setInfoViewVisible:![self infoViewVisible]];
}

#pragma mark - Action

- (void)find {
    [[_searchField window] makeFirstResponder:_searchField];
}

#pragma mark - Action Priv

- (void)setLibraryViewModeAction:(id)sender {
    [self setLibraryViewMode:[sender tag]];
}

#pragma mark - Update

- (void)updateLayout {
    if (_infoViewVisible) {
        // pane
        NSRect frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = 140;
        [_paneSuperview removeFromSuperview];
        [[self view] addSubview:_paneSuperview];
        [_paneSuperview setFrame:frame];
        
        // center
        frame.origin.x = 0;
        frame.origin.y = [_paneSuperview frame].size.height;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = [[self view] frame].size.height - [_paneSuperview frame].size.height;
        [_centerSuperview setFrame:frame];
        [_infoButton setImage:[NSImage imageNamed:@"InfoAlt"]];
    } else {
        // pane
        [_paneSuperview removeFromSuperview];
        
        // center
        NSRect frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size.width = [[self view] frame].size.width;
        frame.size.height = [[self view] frame].size.height;
        [_centerSuperview setFrame:frame];
        [_infoButton setImage:[NSImage imageNamed:@"Info"]];
    }
}

- (void)updateSearch {
    NSString *search = [[[_core db] playlists] valueForList:_currentList attr:PRListAttrSearch];
    [_searchField setStringValue:search];
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [menu removeAllItems];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSImage *image;
    if ([self libraryViewMode] == PRListMode) {
        image = [NSImage imageNamed:@"List.png"];
    } else {
        image = [NSImage imageNamed:@"AlbumList.png"];
    }
    [item setImage:image];
    [item setEnabled:YES];
    [menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"View As..." action:nil keyEquivalent:@""];
    [item setEnabled:NO];
    [menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"List" action:@selector(setLibraryViewModeAction:) keyEquivalent:@""];
    [item setTag:PRListMode];
    if ([self libraryViewMode] == PRListMode) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Album List" action:@selector(setLibraryViewModeAction:) keyEquivalent:@""];
    [item setTag:PRAlbumListMode];
    if ([self libraryViewMode] == PRAlbumListMode) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    [menu addItem:[NSMenuItem separatorItem]];
    item = [[NSMenuItem alloc] initWithTitle:@"Browser" action:nil keyEquivalent:@""];
    [item setSubmenu:[_currentViewController browserHeaderMenu]];
    [menu addItem:item];
    
    for (NSMenuItem *i in [menu itemArray]) {
        [i setTarget:self];
    }
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)note {
    _searchFieldLastEdit = [NSDate date];

    float delay = [[_searchField stringValue] length] != 0 ? SEARCH_DELAY : 0.0;
    [[NSOperationQueue currentQueue] addBlock:^{
        [self postSearchChangedAndRetry:YES];
    } afterDelay:delay];
}

#pragma mark - Priv

- (void)postSearchChangedAndRetry:(BOOL)retry {
    NSString *search = [_searchField stringValue];
    if (!search) {
        search = @"";
    }
    if ([[[[_core db] playlists] valueForList:_currentList attr:PRListAttrSearch] isEqual:search]) {
        return;
    }
    if (fabs([_searchFieldLastEdit timeIntervalSinceNow]) < SEARCH_DELAY) {
        if (retry) {
            [[NSOperationQueue currentQueue] addBlock:^{
                [self postSearchChangedAndRetry:NO];
            } afterDelay:SEARCH_DELAY];
        }
        return;
    }
    [[[_core db] playlists] setValue:search forList:_currentList attr:PRListAttrSearch];
    [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
}

@end
