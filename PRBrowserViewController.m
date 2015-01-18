#import "PRBrowserViewController.h"
#import "NSNotificationCenter+Extensions.h"
#import "NSColor+Extensions.h"
#import "NSMenuItem+Extensions.h"
#import "NSString+Extensions.h"
#import "NSTableView+Extensions.h"
#import "PRTask.h"
#import "PRBridge_Front.h"
#import "PRBrowseView.h"
#import "PRBrowserListViewController.h"
#import "PRConnection.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRLibraryDescription.h"
#import "PRLibraryListViewController.h"
#import "PRLibraryViewController.h"
#import "PRList.h"
#import "PRMainWindowController.h"
#import "PRPlayer.h"
#import "PRPlaylists.h"
#import "PRTableView.h"
#import "PRTagger.h"
#import "sqlite_str.h"

@interface PRBrowserViewController () <PRBrowseViewDelegate, PRBrowserListViewControllerDelegate>
@end

@implementation PRBrowserViewController {
    PRBridge *_bridge;
    PRListID *_currentList;
    PRList *_listDescription;
    NSArray *_browserDescriptions;
    PRLibraryListViewController *_libraryListVC;
    PRBrowserListViewController *_browserListVC1;
    PRBrowserListViewController *_browserListVC2;
    PRBrowserListViewController *_browserListVC3;
}

#pragma mark - Initialization

- (id)initWithBridge:(PRBridge *)bridge {
    if (!(self = [super init])) {return nil;}
    _bridge = bridge;
    return self;
}

#pragma mark - API

- (NSMenu *)browserHeaderMenu {
    PRBrowserPosition position = [_listDescription vertical];
    
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [item setTitle:@"Hidden"];
    [item setTarget:self];
    [item setAction:@selector(_browserPositionAction:)];
    [item setRepresentedObject:@(PRBrowserPositionHidden)];
    if (position == PRBrowserPositionHidden) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"On Top"];
    [item setTarget:self];
    [item setAction:@selector(_browserPositionAction:)];
    [item setRepresentedObject:@(PRBrowserPositionHorizontal)];
    if (position == PRBrowserPositionHorizontal) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    item = [[NSMenuItem alloc] init];
    [item setTitle:@"On Left"];
    [item setTarget:self];
    [item setAction:@selector(_browserPositionAction:)];
    [item setRepresentedObject:@(PRBrowserPositionVertical)];
    if (position == PRBrowserPositionVertical) {
        [item setState:NSOnState];
    }
    [menu addItem:item];
    
    if (position != PRBrowserPositionHidden) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        for (PRItemAttr *i in @[PRItemAttrGenre, PRItemAttrComposer, PRItemAttrArtist, PRItemAttrAlbum]) {
            item = [[NSMenuItem alloc] init];
            [item setTitle:[PRLibrary titleForItemAttr:i]];
            [item setTarget:self];
            [item setAction:@selector(_browserAttributeAction:)];
            [item setRepresentedObject:i];
            if ([[_listDescription browserAttributes] containsObject:i]) {
                [item setState:NSOnState];
            }
            [menu addItem:item];
        }
    }
    return menu;
}

- (PRListID *)currentList {
    return _currentList;
}

- (void)setCurrentList:(PRListID *)list {
    _currentList = list;
    [self _reloadData];
}

- (NSDictionary *)info {
    // return [_libraryDescription info];
    return nil;
}

- (NSArray *)selection {
    return [_libraryListVC selectedItems];
}

- (void)highlightItem:(PRItemID *)item {
    // NSString *artist;
    // if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation] && [[[_db library] valueForItem:item attr:PRItemAttrCompilation] boolValue]) {
    //     artist = PRCompilationString;
    // } else {
    //     artist = [[_db library] artistValueForItem:item];
    // }
    // [self browseToArtist:artist];
    
    // NSInteger row = [_libraryDescription rowForItem:item];
    // if (row != -1) {
    //     [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    //     [_detailTableView scrollRowToVisiblePretty:row];
    // }
}

- (void)highlightFiles:(NSArray *)items {
    // NSMutableIndexSet *rows = [NSMutableIndexSet indexSet];
    // for (NSNumber *i in items) {
    //     NSInteger row = [_libraryDescription rowForItem:i];
    //     if (row == -1) {
    //         [rows removeAllIndexes];
    //         break;
    //     }
    //     [rows addIndex:row];
    // }
    // if ([rows count] == 0) {
    //     [[_db playlists] setSearch:@"" forList:_currentList];
    //     [[_db playlists] setSelection:@[] forBrowser:1 list:_currentList];
    //     [[_db playlists] setSelection:@[] forBrowser:2 list:_currentList];
    //     [[_db playlists] setSelection:@[] forBrowser:3 list:_currentList];
    //     [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
        
    //     for (NSNumber *i in items) {
    //         NSInteger row = [_libraryDescription rowForItem:i];
    //         if (row != -1) {
    //             [rows addIndex:row];
    //         }
    //     }
    // }
    // if ([rows count] > 0) {
    //     [_detailTableView selectRowIndexes:rows byExtendingSelection:NO];
    //     [_detailTableView scrollRowToVisiblePretty:[rows firstIndex]];
    // }
}

- (void)highlightArtist:(NSString *)artist {
    // [self browseToArtist:artist];
    // PRItemAttr *attr;
    // if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
    //     attr = PRItemAttrArtistAlbumArtist;
    // } else {
    //     attr = PRItemAttrArtist;
    // }
    // NSInteger row = [_libraryDescription firstRowWithValue:artist forAttr:attr];
    // if (row == -1) {
    //     return;
    // }
    // [_detailTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    // [_detailTableView scrollRowToVisiblePretty:row];
}

- (void)browseToArtist:(NSString *)artist {
    // [[_db playlists] setSearch:@"" forList:_currentList];
    // for (int i = 1; i <= 3; i++) {
    //     NSArray *selection = @[];
    //     if ([[[_db playlists] attrForBrowser:i list:_currentList] isEqual:PRItemAttrArtist]) {
    //         selection = @[artist];
    //     }
    //     [[_db playlists] setSelection:selection forBrowser:i list:_currentList];
    // }
    // [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
}

#pragma mark - NSViewController

- (void)loadView {
    // Browser
    PRBrowseView *view = [[PRBrowseView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
    [view setDelegate:self];
    [self setView:view];
    
    // Library list
    _libraryListVC = [[PRLibraryListViewController alloc] initWithBridge:_bridge];
    
    // Browser list
    _browserListVC1 = [[PRBrowserListViewController alloc] initWithBridge:_bridge];
    [_browserListVC1 setDelegate:self];
    _browserListVC2 = [[PRBrowserListViewController alloc] initWithBridge:_bridge];
    [_browserListVC2 setDelegate:self];
    _browserListVC3 = [[PRBrowserListViewController alloc] initWithBridge:_bridge];
    [_browserListVC3 setDelegate:self];
    
    // Key Views
    [[self firstKeyView] setNextKeyView:[_browserListVC1 view]];
    [[_browserListVC1 view] setNextKeyView:[_browserListVC2 view]];
    [[_browserListVC2 view] setNextKeyView:[_browserListVC3 view]];
    [[_browserListVC3 view] setNextKeyView:[_libraryListVC view]];
    [[_libraryListVC view] setNextKeyView:[self lastKeyView]];
    
    // Update
    [[NSNotificationCenter defaultCenter] observeBackendChanged:self sel:@selector(_backendDidChange:)];
    [[NSNotificationCenter defaultCenter] observeLibraryChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(tagsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeUseAlbumArtistChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistFilesChanged:)];
}

#pragma mark - PRBrowseViewDelegate

- (void)browseViewDidChangeDividerPosition:(PRBrowseView *)view {
    [self _saveBrowser];
}

#pragma mark - PRBrowserListViewControllerDelegate

- (void)browserListViewControllerDidChangeSelection:(PRBrowserListViewController *)browserVC {
    NSMutableArray *browserSelections = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        NSMutableArray *browserSelection = [NSMutableArray array];
        PRBrowserListViewController *browserVC = @[_browserListVC1, _browserListVC2, _browserListVC3][i];
        PRBrowserDescription *browserDescription = [browserVC browserDescription];
        NSIndexSet *selectedIndexes = [browserVC selectedIndexes];
        [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger j, BOOL *stop){
            if (j != 0) {
               [browserSelection addObject:[browserDescription valueForRow:j]];
            }
        }];
        [browserSelections addObject:browserSelection];
    }
    [_listDescription setBrowserSelections:browserSelections];
    [_bridge performTask:PRSetListDescriptionTask(_listDescription, _currentList)];
}

- (NSArray *)browserListViewControllerLibraryItems:(PRBrowserListViewController *)browserVC {
    return [_libraryListVC allItems];
}

- (NSMenu *)browserListViewControllerHeaderMenu:(PRBrowserListViewController *)browserVC {
    return [self browserHeaderMenu];
}

#pragma mark - Notifications

- (void)_backendDidChange:(NSNotification *)note {
    BOOL reloadData = NO;
    for (NSObject *i in [[note userInfo][@"changeset"] changes]) {
        if ([i isKindOfClass:[PRListChange class]]) {
            if ([[(PRListChange *)i list] isEqual:_currentList]) {
                reloadData = YES;
            }
        } else if ([i isKindOfClass:[PRNowPlayingChange class]]) {
            reloadData = YES;
        }
    }
    if (reloadData) {
        [self _reloadData];
    }
}

- (void)libraryDidChange:(NSNotification *)note {
    [self _reloadData];
}

- (void)tagsDidChange:(NSNotification *)note {
    [self _reloadData];
}

- (void)playlistFilesChanged:(NSNotification *)note {
    if ([[[note userInfo] valueForKey:@"playlist"] isEqual:_currentList]) {
        [self _reloadData];
    }
}

#pragma mark - Action

- (void)_browserPositionAction:(NSMenuItem *)item {
    PRBrowserPosition position = [[item representedObject] integerValue];
    if (position == PRBrowserPositionHorizontal) {
        [_listDescription setVertical:PRBrowserPositionHorizontal];
        [_listDescription setBrowserAttributes:@[PRItemAttrGenre, PRItemAttrArtist, PRItemAttrAlbum]];
    } else if (position == PRBrowserPositionVertical) {
        [_listDescription setVertical:PRBrowserPositionVertical];
        [_listDescription setBrowserAttributes:@[[NSNull null], [NSNull null], PRItemAttrArtist]];
    } else if (position == PRBrowserPositionHidden) {
        [_listDescription setVertical:PRBrowserPositionHidden];
        [_listDescription setBrowserAttributes:@[[NSNull null], [NSNull null], [NSNull null]]];
    }
    [_listDescription setBrowserSelections:@[@[], @[], @[]]];
    
    [_bridge performTask:PRSetListDescriptionTask(_listDescription, _currentList)];
}

- (void)_browserAttributeAction:(NSMenuItem *)item {
    PRItemAttr *attr = [item representedObject];
    if ([_listDescription vertical] == PRBrowserPositionVertical) {
        [_listDescription setBrowserAttributes:@[[NSNull null], [NSNull null], attr]];
    } else if ([_listDescription vertical] == PRBrowserPositionHorizontal) {
        NSMutableSet *set = [NSMutableSet setWithArray:[_listDescription browserAttributes]];
        if ([set containsObject:attr]) {
            [set removeObject:attr];
            if ([set count] == 0) {
                [set addObject:PRItemAttrArtist];
            }
        } else {
            [set addObject:attr];
            if ([set count] > 3) {
                if ([attr isEqual:PRItemAttrComposer]) {
                    [set removeObject:PRItemAttrGenre];
                } else {
                    [set removeObject:PRItemAttrComposer];
                }
            }
        }
        
        NSMutableArray *attrs = [NSMutableArray array];
        for (PRItemAttr *i in @[PRItemAttrGenre, PRItemAttrComposer, PRItemAttrArtist, PRItemAttrAlbum]) {
            if ([set containsObject:i]) {
                [attrs addObject:i];
            }
        }
        while ([attrs count] < 3) {
            [attrs insertObject:[NSNull null] atIndex:0];
        }
        [_listDescription setBrowserAttributes:attrs];
    } else {
        return;
    }
    [_listDescription setBrowserSelections:@[@[], @[], @[]]];
    [_bridge performTask:PRSetListDescriptionTask(_listDescription, _currentList)];
}

#pragma mark - Internal

- (void)_reloadData {
    if (_currentList) {
        __block PRList *listDescription = nil;
        __block NSArray *browserDescriptions = nil;
        [_bridge performTaskSync:^(PRCore *core){
            [[[core conn] playlists] zListForListID:_currentList out:&listDescription];
            [[[core conn] playlists] zBrowserDescriptionsForList:_currentList out:&browserDescriptions];
        }];
        _listDescription = listDescription;
        _browserDescriptions = browserDescriptions;
        
        [_libraryListVC setCurrentList:_currentList];
        [_browserListVC1 setBrowserDescription:_browserDescriptions[0]];
        [_browserListVC2 setBrowserDescription:_browserDescriptions[1]];
        [_browserListVC3 setBrowserDescription:_browserDescriptions[2]];
        [self _loadBrowser];
    }
}

- (void)_loadBrowser {
    PRBrowseView *view = (PRBrowseView *)[self view];
    [view setDetailView:[_libraryListVC view]];
    
    PRBrowserPosition browserPosition = [_listDescription vertical];
    if (browserPosition == PRBrowserPositionVertical) {
        [view setStyle:PRBrowseViewStyleVertical];
        [view setBrowseViews:@[[_browserListVC3 view]]];
        [view setDividerPosition:[_listDescription verticalBrowserWidth]];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [view setStyle:PRBrowseViewStyleHorizontal];
        NSArray *browserAttributes = [_listDescription browserAttributes];
        NSArray *browseViews = nil;
        if (browserAttributes[1] == [NSNull null]) {
            browseViews = @[[_browserListVC3 view]];
        } else if (browserAttributes[0] == [NSNull null]) {
            browseViews = @[[_browserListVC2 view], [_browserListVC3 view]];
        } else {
            browseViews = @[[_browserListVC1 view], [_browserListVC2 view], [_browserListVC3 view]];
        }
        [view setBrowseViews:browseViews];
        [view setDividerPosition:[_listDescription horizontalBrowserHeight]];
    } else if (browserPosition == PRBrowserPositionHidden){
        [view setStyle:PRBrowseViewStyleNone];
    }
}

- (void)_saveBrowser {
    PRBrowserPosition browserPosition = [_listDescription vertical];
    CGFloat width = [(PRBrowseView *)[self view] dividerPosition];
    if (browserPosition == PRBrowserPositionVertical) {
        [_listDescription setVerticalBrowserWidth:width];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [_listDescription setHorizontalBrowserHeight:width];
    }
    [_bridge performTask:PRSetListDescriptionTask(_listDescription, _currentList)];
}

@end
