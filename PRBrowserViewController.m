#import "PRBrowserViewController.h"
#import "NSColor+Extensions.h"
#import "NSMenuItem+Extensions.h"
#import "NSString+Extensions.h"
#import "NSTableView+Extensions.h"
#import "PRAction.h"
#import "PRActionCenter.h"
#import "PRBrowseView.h"
#import "PRBrowserListViewController.h"
#import "PRConnection.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRLibraryDescription.h"
#import "PRLibraryListViewController.h"
#import "PRLibraryViewController.h"
#import "PRListDescription.h"
#import "PRMainWindowController.h"
#import "PRNowPlayingController.h"
#import "PRPlaylists.h"
#import "PRTableView.h"
#import "PRTagger.h"
#import "sqlite_str.h"

@interface PRBrowserViewController () <PRBrowseViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate, PRTableViewDelegate, PRBrowserListViewController>
@end

@implementation PRBrowserViewController {
    __weak PRCore *_core;
    __weak PRDb *_db;
    
    PRList *_currentList;
    PRListDescription *_listDescription;
    PRLibraryDescription *_libraryDescription;
    NSArray *_browserDescriptions;
    
    PRLibraryListViewController *_libraryListVC;
    PRBrowserListViewController *_browserListVC1;
    PRBrowserListViewController *_browserListVC2;
    PRBrowserListViewController *_browserListVC3;
}

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super init])) {return nil;}
    _core = core;
    _db = [core db];
    return self;
}

#pragma mark - API

- (NSMenu *)browserHeaderMenu {
    return nil;
}

- (PRList *)currentList {
    return _currentList;
}

- (void)setCurrentList:(PRList *)list {
    _currentList = list;
    
    if (list) {
        [self reloadData:YES];
        [self loadBrowser];
        // [_detailTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        // [_detailTableView scrollRowToVisiblePretty:0];
        // [_browserListVC1 scrollToSelectedRow];
        // [_browserListVC2 scrollToSelectedRow];
        // [_browserListVC3 scrollToSelectedRow];
    }
}

- (NSDictionary *)info {
    return [_libraryDescription info];
}

- (NSArray *)selection {
    return [_libraryListVC selectedItems];
}

- (void)highlightItem:(PRItem *)item {
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
    // [_browserListVC1 scrollToSelectedRow];
    // [_browserListVC2 scrollToSelectedRow];
    // [_browserListVC3 scrollToSelectedRow];
}

#pragma mark - NSViewController


- (void)loadView {
    // Browser
    PRBrowseView *view = [[PRBrowseView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
    [view setDelegate:self];
    [self setView:view];
    
    // Library list
    _libraryListVC = [[PRLibraryListViewController alloc] init];
    
    // Browser list
    _browserListVC1 = [[PRBrowserListViewController alloc] init];
    [_browserListVC1 setDelegate:self];
    _browserListVC2 = [[PRBrowserListViewController alloc] init];
    [_browserListVC2 setDelegate:self];
    _browserListVC3 = [[PRBrowserListViewController alloc] init];
    [_browserListVC3 setDelegate:self];
    
    // Key Views
    [[self firstKeyView] setNextKeyView:[_browserListVC1 view]];
    [[_browserListVC1 view] setNextKeyView:[_browserListVC2 view]];
    [[_browserListVC2 view] setNextKeyView:[_browserListVC3 view]];
    [[_browserListVC3 view] setNextKeyView:[_libraryListVC view]];
    [[_libraryListVC view] setNextKeyView:[self lastKeyView]];
    
    // Update
    [[NSNotificationCenter defaultCenter] observeLibraryChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeItemsChanged:self sel:@selector(tagsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeUseAlbumArtistChanged:self sel:@selector(libraryDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistFilesChanged:)];
    [[NSNotificationCenter defaultCenter] observePlayingFileChanged:self sel:@selector(playingFileChanged:)];
}

#pragma mark - PRBrowseViewDelegate

- (void)browseViewDidChangeDividerPosition:(PRBrowseView *)view {
    [self saveBrowser];
}

#pragma mark - PRBrowserViewControllerDelegate

- (void)browserViewControllerDidChangeSelection:(PRBrowserListViewController *)browserVC {
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
    
    PRSetListDescriptionAction *action = [[PRSetListDescriptionAction alloc] init];
    [action setList:_currentList];
    [action setListDescription:_listDescription];
    [PRActionCenter performAction:action];
}

#pragma mark - Notifications

- (void)playingFileChanged:(NSNotification *)note {
    // NSIndexSet *rows = [NSIndexSet indexSetWithIndexesInRange:[_detailTableView rowsInRect:[_detailTableView visibleRect]]];
    // NSIndexSet *columns = [NSIndexSet indexSetWithIndex:[_detailTableView columnWithIdentifier:PRItemAttrTrackNumber]];
    // [_detailTableView reloadDataForRowIndexes:rows columnIndexes:columns];
}

- (void)libraryDidChange:(NSNotification *)note {
    if (_currentList) {
        [self reloadData:YES];
    }
}

- (void)tagsDidChange:(NSNotification *)note {
    if (_currentList) {
        [self reloadData:YES];
    }
}

- (void)playlistDidChange:(NSNotification *)note {
    if (!_currentList || ![[[note userInfo] valueForKey:@"playlist"] isEqual:_currentList]) {
        return;
    }
    [self reloadData:NO];
    // [_detailTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    // [_detailTableView scrollRowToVisible:[_detailTableView selectedRow]];
    // [_browserListVC1 scrollToSelectedRow];
    // [_browserListVC2 scrollToSelectedRow];
    // [_browserListVC3 scrollToSelectedRow];
}

- (void)playlistFilesChanged:(NSNotification *)note {
    if (_currentList && [[[note userInfo] valueForKey:@"playlist"] isEqual:_currentList]) {
        [self reloadData:YES];
    }
}

#pragma mark - Internal

- (void)reloadData:(BOOL)force {
    PRListDescription *listDescription = nil;
    BOOL success = [[[_core conn] playlists] zListDescriptionForList:_currentList out:&listDescription];
    _listDescription = listDescription;
    
    PRLibraryDescription *libraryDescriptions = nil;
    success = [[[_core conn] playlists] zLibraryDescriptionForList:_currentList out:&libraryDescriptions];
    _libraryDescription = libraryDescriptions;
    
    NSArray *browserDescriptions = nil;
    success = [[[_core conn] playlists] zBrowserDescriptionsForList:_currentList out:&browserDescriptions];
    _browserDescriptions = browserDescriptions;
    
    [_libraryListVC setLibraryDescription:_libraryDescription];
    [_browserListVC1 setBrowserDescription:_browserDescriptions[0]];
    [_browserListVC2 setBrowserDescription:_browserDescriptions[1]];
    [_browserListVC3 setBrowserDescription:_browserDescriptions[2]];
}

- (void)toggleBrowser:(PRItemAttr *)attr {
    if ([[_db playlists] verticalForList:_currentList]) {
        [[_db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:attr forBrowser:3 list:_currentList];
    } else {
        NSMutableSet *set = [NSMutableSet set];
        for (int i = 1; i < 4; i++) {
            if ([[_db playlists] attrForBrowser:i list:_currentList]) {
                [set addObject:[[_db playlists] attrForBrowser:i list:_currentList]];
            }
        }
        
        if ([set containsObject:attr]) { // if removing browser
            [set removeObject:attr];
            if ([set count] == 0) {
                [set addObject:PRItemAttrArtist];
            }
        } else { // if adding browser
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
        for (PRItemAttr *i in @[PRItemAttrAlbum, PRItemAttrArtist, PRItemAttrComposer, PRItemAttrGenre]) {
            if ([set containsObject:i]) {
                [attrs addObject:i];
            }
        }
        [attrs addObject:[NSNull null]];
        [attrs addObject:[NSNull null]];
        [attrs addObject:[NSNull null]];
        
        // save
        for (int i = 0; i < 3; i++) {
            if ([attrs objectAtIndex:i] == [NSNull null]) {
                [[_db playlists] setAttr:nil forBrowser:3-i list:_currentList];
            } else {
                [[_db playlists] setAttr:[attrs objectAtIndex:i] forBrowser:3-i list:_currentList];
            }
        }
    }
    [[_db playlists] setSelection:@[] forBrowser:1 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:2 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:3 list:_currentList];
    [self loadBrowser];
    [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
}

- (void)setBrowserPosition:(PRBrowserPosition)position {
    if (position == PRBrowserPositionHorizontal) {
        [[_db playlists] setVertical:PRBrowserPositionHorizontal forList:_currentList];
        [[_db playlists] setAttr:PRItemAttrGenre forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:PRItemAttrArtist forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:PRItemAttrAlbum forBrowser:3 list:_currentList];
    } else if (position == PRBrowserPositionVertical) {
        [[_db playlists] setVertical:PRBrowserPositionVertical forList:_currentList];
        [[_db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:PRItemAttrArtist forBrowser:3 list:_currentList];
    } else if (position == PRBrowserPositionHidden) {
        [[_db playlists] setVertical:PRBrowserPositionHidden forList:_currentList];
        [[_db playlists] setAttr:nil forBrowser:1 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:2 list:_currentList];
        [[_db playlists] setAttr:nil forBrowser:3 list:_currentList];
    }
    [[_db playlists] setSelection:@[] forBrowser:1 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:2 list:_currentList];
    [[_db playlists] setSelection:@[] forBrowser:3 list:_currentList];
    [self loadBrowser];
    [[NSNotificationCenter defaultCenter] postListDidChange:_currentList];
}

- (void)loadBrowser {
    PRBrowseView *view = (PRBrowseView *)[self view];
    [view setDetailView:[_libraryListVC view]];
    
    int browserPosition = [[_db playlists] verticalForList:_currentList];
    if (browserPosition == PRBrowserPositionVertical) {
        [view setStyle:PRBrowseViewStyleVertical];
        [view setBrowseViews:@[[_browserListVC3 view]]];
        [view setDividerPosition:[[_db playlists] verticalBrowserWidthForList:_currentList]];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [view setStyle:PRBrowseViewStyleHorizontal];
        NSArray *browseViews = nil;
        if (![[_db playlists] attrForBrowser:2 list:_currentList]) {
            browseViews = @[[_browserListVC3 view]];
        } else if (![[_db playlists] attrForBrowser:1 list:_currentList]) {
            browseViews = @[[_browserListVC2 view], [_browserListVC3 view]];
        } else {
            browseViews = @[[_browserListVC1 view], [_browserListVC2 view], [_browserListVC3 view]];
        }
        [view setBrowseViews:browseViews];
        [view setDividerPosition:[[_db playlists] horizontalBrowserHeightForList:_currentList]];
    } else if (browserPosition == PRBrowserPositionHidden){
        [view setStyle:PRBrowseViewStyleNone];
    }
}

- (void)saveBrowser {
    if (!_currentList) {
        return;
    }
    int browserPosition = [[_db playlists] verticalForList:_currentList];
    float width = [(PRBrowseView *)[self view] dividerPosition];
    if (browserPosition == PRBrowserPositionVertical) {
        [[_db playlists] setVerticalBrowserWidth:width forList:_currentList];
    } else if (browserPosition == PRBrowserPositionHorizontal) {
        [[_db playlists] setHorizontalBrowserHeight:width forList:_currentList];
    }
}

@end
