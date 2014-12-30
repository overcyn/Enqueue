#import "PRLibraryViewController.h"
#import "PRAlbumListViewController.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRInfoViewController.h"
#import "PRLibrary.h"
#import "PRNowPlayingController.h"
#import "PRPlaylists.h"
#import "PRSizeFormatter.h"
#import "PRStringFormatter.h"
#import "PRBrowserViewController.h"
#import "PRTimeFormatter2.h"
#import "PRListDescription.h"
#import "PRBridge.h"
#import "PRConnection.h"

#define SEARCH_DELAY 0.25

@interface PRLibraryViewController () <NSMenuDelegate, NSTextFieldDelegate>
@end

@implementation PRLibraryViewController {
    PRBridge *_bridge;
    
    NSView *_centerSuperview;
    NSView *_paneSuperview;
    NSView *_headerView;
    NSButton *_infoButton;
    NSPopUpButton *_libraryPopUpButton;
    NSSearchField *_searchField;
    
    NSMenu *_libraryPopUpButtonMenu;
    
    PRInfoViewController *_infoVC;
    PRBrowserViewController *_browserVC;
    PRAlbumListViewController *_albumListVC;
    
    NSDate *_searchFieldLastEdit;
    
    BOOL _infoViewVisible;
    PRList *_currentList;
    PRListDescription *_listDescription;
    PRBrowserViewController *_currentVC;
}

#pragma mark - Initialization

- (id)initWithBridge:(PRBridge *)bridge {
    if (!(self = [super init])) {return nil;}
    _bridge = bridge;
    return self;
}

#pragma mark - API

@synthesize currentViewController = _currentVC;
@synthesize headerView = _headerView;

- (PRList *)currentList {
    return _currentList;
}

- (void)setCurrentList:(PRList *)list {
    if (![list isEqual:_currentList]) {
        _currentList = list;
        [self _reloadData];
        [NSNotificationCenter post:PRCurrentListDidChangeNotification];
    }
}

- (PRLibraryViewMode)libraryViewMode {
    if (_currentVC == _browserVC) {
        return PRListMode;
    }
    return PRAlbumListMode;
}

- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode {
    [_listDescription viewMode];
}

- (BOOL)infoViewVisible {
    return _infoViewVisible;
}

- (void)setInfoViewVisible:(BOOL)visible {
    if (_infoViewVisible != visible) {
        _infoViewVisible = visible;
        [self _updateLayout];
    }
}

- (void)toggleInfoViewVisible {
    [self setInfoViewVisible:![self infoViewVisible]];
}

- (void)find {
    [[_searchField window] makeFirstResponder:_searchField];
}

#pragma mark - NSViewController

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setView:view];
    
    // Center view
    _centerSuperview = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
    [_centerSuperview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[self view] addSubview:_centerSuperview];
    
    _browserVC = [[PRBrowserViewController alloc] initWithBridge:_bridge];
    [[_browserVC view] setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [[_browserVC view] setFrame:[_centerSuperview bounds]];
    [_centerSuperview addSubview:[_browserVC view]];
    _currentVC = _browserVC;
    
//    _albumListVC = [[PRAlbumListViewController alloc] initWithCore:_core];
//    [[_albumListVC view] setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    
    // Pane view
    _paneSuperview = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 500, 140)];
    [_paneSuperview setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    _infoViewVisible = NO;
    
    // _infoVC = [[PRInfoViewController alloc] initWithCore:_core];
    // [[_infoVC view] setFrame:[_paneSuperview bounds]];
    // [_paneSuperview addSubview:[_infoVC view]];
    
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
    [self _updateLayout];
    
    // Key View
    [_searchField setNextKeyView:[self lastKeyView]];
    
    // Update
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(_updateSearch)];
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
    item = [[NSMenuItem alloc] initWithTitle:@"List" action:@selector(_setLibraryViewModeAction:) keyEquivalent:@""];
    [item setTag:PRListMode];
    if ([self libraryViewMode] == PRListMode) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Album List" action:@selector(_setLibraryViewModeAction:) keyEquivalent:@""];
    [item setTag:PRAlbumListMode];
    if ([self libraryViewMode] == PRAlbumListMode) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    [menu addItem:[NSMenuItem separatorItem]];
    item = [[NSMenuItem alloc] initWithTitle:@"Browser" action:nil keyEquivalent:@""];
    [item setSubmenu:[_currentVC browserHeaderMenu]];
    [menu addItem:item];
    
    for (NSMenuItem *i in [menu itemArray]) {
        [i setTarget:self];
    }
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)note {
    _searchFieldLastEdit = [NSDate date];

    CGFloat delay = [[_searchField stringValue] length] != 0 ? SEARCH_DELAY : 0.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self _postSearchChangedAndRetry:YES];
    });
}

#pragma mark - Action

- (void)_setLibraryViewModeAction:(id)sender {
    [self setLibraryViewMode:[sender tag]];
}

#pragma mark - Internal

- (void)_reloadData {
    if (_currentList) {
        __block PRListDescription *listDescription = nil;
        [_bridge performTaskSync:^(PRCore *core){
            [[[core conn] playlists] zListDescriptionForList:_currentList out:&listDescription];
        }];
        _listDescription = listDescription;
        
        [_browserVC setCurrentList:nil];
        [_albumListVC setCurrentList:nil];
        PRBrowserViewController *prevVC = _currentVC;
        if ([_listDescription viewMode] == PRListMode) {
            _currentVC = _browserVC;
        } else {
            _currentVC = _albumListVC;
        }
        [_currentVC setCurrentList:_currentList];
        if (_currentVC != prevVC) {
            [[_currentVC view] setFrame:[_centerSuperview bounds]];
            [_centerSuperview replaceSubview:[prevVC view] with:[_currentVC view]];    
            [[self firstKeyView] setNextKeyView:[_currentVC firstKeyView]];
            [[_currentVC lastKeyView] setNextKeyView:_searchField];
        }
        
        [self _updateLayout];
        [self _updateSearch];
    }
}

- (void)_updateLayout {
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

- (void)_updateSearch {
    [_searchField setStringValue:[_listDescription search]];
}

- (void)_postSearchChangedAndRetry:(BOOL)retry {
    NSString *search = [_searchField stringValue] ?: @"";
    if (![[_listDescription search] isEqual:search]) {
        if (fabs([_searchFieldLastEdit timeIntervalSinceNow]) < SEARCH_DELAY) {
            if (retry) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, SEARCH_DELAY * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self _postSearchChangedAndRetry:NO];
                });
            }
        } else {
            [_listDescription setSearch:search];
            [_bridge performTask:PRSetListDescriptionTask(_listDescription, _currentList)];
        }
    }
}

@end
