#import "PRPlaylistsViewController.h"
#import "PRBridge_Front.h"
#import "PRBridge_Back.h"
#import "PRList.h"
#import "PRException.h"
#import "NSNotificationCenter+Extensions.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRPlaylists.h"
#import "PRMainWindowController.h"
#import "PRGradientView.h"
#import "PRScrollView.h"
#import "PRRolloverTableView.h"
#import "NSScrollView+Extensions.h"
#import "PRStringFormatter.h"
#import "PRCore.h"
#import "NSColor+Extensions.h"
#import "PRLibraryViewController.h"
#import "NSArray+Extensions.h"

@interface PRPlaylistsViewController () <NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>
@end

@implementation PRPlaylistsViewController {
    IBOutlet NSView *background;
    IBOutlet PRRolloverTableView *tableView;
    IBOutlet PRGradientView *divider;
    IBOutlet PRGradientView *divider2;
    IBOutlet NSButton *newPlaylistButton;
    IBOutlet NSButton *newSmartPlaylistButton;
    IBOutlet NSButton *tabButton0;
    IBOutlet NSImageView *_placeholder;
    
    PRStringFormatter *_stringFormatter;
    NSArray *_lists;

    PRBridge *_bridge;
    PRDb *_db;
    PRMainWindowController *_win;
}

#pragma mark - Initialization

- (id)initWithBridge:(PRBridge *)bridge {
    if ((self = [super initWithNibName:@"PRPlaylistsView" bundle:nil])) {
        _bridge = bridge;
        _win = [[bridge core] win];
        _db = [[bridge core] db];
        _stringFormatter = [[PRStringFormatter alloc] init];
        [_stringFormatter setMaxLength:80];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, 795)];
    [(NSScrollView *)[self view] setDocumentView:[background superview]];
    [(NSScrollView *)[self view] scrollToTop];
    
    [tableView setRowHeight:42];
    [tableView setIntercellSpacing:NSMakeSize(0, 0)];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableViewAction)];
    [tableView setTrackMouseWithinCell:YES];
    [[[[tableView tableColumns] objectAtIndex:0] dataCell] setFormatter:_stringFormatter];
    
    [divider setBotBorder2:[NSColor PRTabBorderColor]];
    [divider setBotBorder:[NSColor PRTabBorderHighlightColor]];
    [divider setColor:[NSColor PRTabBackgroundColor]];
    
    [divider2 setTopBorder:[NSColor PRGridColor]];
    [divider2 setBotBorder:[NSColor PRGridHighlightColor]];
    
    // buttons
    [newSmartPlaylistButton setTarget:self];
    [newSmartPlaylistButton setAction:@selector(newSmartPlaylist)];
    [newPlaylistButton setTarget:self];
    [newPlaylistButton setAction:@selector(newStaticPlaylist)];
        
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(update)];
    [[NSNotificationCenter defaultCenter] observePlaylistsChanged:self sel:@selector(update)];
//    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(update)];
    [self update];
}

#pragma mark - Action

- (void)tableViewAction {
    int idx = [tableView clickedRow];
    if (idx >= [_lists count]) {
        return;
    }
    PRListID *list = [_lists[idx] listID];
    [[_win libraryViewController] setCurrentList:list];
    [_win setCurrentMode:PRWindowModeLibrary];
}

- (void)newStaticPlaylist {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"New Playlist Title:"];
    [alert setInformativeText:@""];
    [alert setAccessoryView:[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 0)]];
    [(NSTextField *)[alert accessoryView] setStringValue:@"Untitled Playlist"];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert layout];
    NSRect frame2 = [[alert accessoryView] frame];
    frame2.size.height = 24;
    [[alert accessoryView] setFrame:frame2];
    NSRect frame = [[[alert accessoryView] superview] frame];
    frame.size.height = 24;
    [[[alert accessoryView] superview] setFrame:frame];
    [alert beginSheetModalForWindow:[[self view] window] modalDelegate:self didEndSelector:@selector(newPlaylistHandler:code:context:) contextInfo:NULL];
}

- (void)newPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context {
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    PRList *list = nil;
    [[_db playlists] zAddStaticList:&list];
    [[_db playlists] setValue:[(NSTextField *)[alert accessoryView] stringValue] forList:[list listID] attr:PRListAttrTitle];
    [[NSNotificationCenter defaultCenter] postListsDidChange];
}

- (void)newSmartPlaylist {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"New Smart Playlist Title:"];
    [alert setInformativeText:@""];
    [alert setAccessoryView:[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 0)]];
    [(NSTextField *)[alert accessoryView] setStringValue:@"Untitled Playlist"];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert layout];
    NSRect frame2 = [[alert accessoryView] frame];
    frame2.size.height = 24;
    [[alert accessoryView] setFrame:frame2];
    NSRect frame = [[[alert accessoryView] superview] frame];
    frame.size.height = 24;
    [[[alert accessoryView] superview] setFrame:frame];
    [alert beginSheetModalForWindow:[[self view] window] modalDelegate:self didEndSelector:@selector(newSmartPlaylistHandler:code:context:) contextInfo:NULL];
}

- (void)newSmartPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context {
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    PRList *list = nil;
    [[_db playlists] zAddSmartList:&list];
    [[_db playlists] setValue:[(NSTextField *)[alert accessoryView] stringValue] forList:[list listID] attr:PRListAttrTitle];
    [[NSNotificationCenter defaultCenter] postListsDidChange];
}

- (void)duplicatePlaylist:(PRListID *)playlist {
    // NSAlert *alert = [[NSAlert alloc] init];
    // [alert addButtonWithTitle:@"Save"];
    // [alert addButtonWithTitle:@"Cancel"];
    // [alert setMessageText:@"New playlist title:"];
    // [alert setInformativeText:@""];
    // [alert setAccessoryView:[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 0)]];
    // NSString *title = @"";
    // PRListType *type = [[_db playlists] typeForList:[PRListID numberWithInt:playlist]];
    // if ([type isEqual:PRListTypeStatic]) {
    //     title = [[[_db playlists] titleForList:[NSNumber numberWithInt:playlist]] stringByAppendingString:@" Copy"];
    // } else if ([type isEqual:PRListTypeNowPlaying]) {
    //     title = @"Untitled Playlist";
    // }
    // [(NSTextField *)[alert accessoryView] setStringValue:title];   
    // [alert setAlertStyle:NSWarningAlertStyle];
    // [alert layout];
    // NSRect frame2 = [[alert accessoryView] frame];
    // frame2.size.height = 24;
    // [[alert accessoryView] setFrame:frame2];
    // NSRect frame = [[[alert accessoryView] superview] frame];
    // frame.size.height = 24;
    // [[[alert accessoryView] superview] setFrame:frame];
    // [alert beginSheetModalForWindow:[_win window] modalDelegate:self didEndSelector:@selector(duplicateHandler:code:context:) contextInfo:(__bridge_retained void *)@(playlist)];
}

- (void)duplicateHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context  {
    NSNumber *l = (__bridge_transfer NSNumber *)context;
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    PRList *list = nil;
    [[_db playlists] zAddStaticList:&list];
    [[_db playlists] setValue:[(NSTextField *)[alert accessoryView] stringValue] forList:[list listID] attr:PRListAttrTitle];
    [[_db playlists] zCopyItemsFromList:l toList:[list listID]];
    [[NSNotificationCenter defaultCenter] postListsDidChange];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:[list listID]];
}

- (void)deletePlaylist:(PRListID *)listID {
    // NSAlert *alert = [[NSAlert alloc] init];
    // [alert addButtonWithTitle:@"Delete"];
    // [alert addButtonWithTitle:@"Cancel"];
    // // [alert setMessageText:[NSString stringWithFormat:@"Delete playlist '%@'?", [[_db playlists] valueForList:@(playlist) attr:PRListAttrTitle]]];
    // [alert setInformativeText:@"This action cannot be undone."];
    // [alert setAlertStyle:NSWarningAlertStyle];
    // [alert layout];
    // [alert beginSheetModalForWindow:[_win window] modalDelegate:self didEndSelector:@selector(deleteHandler:code:context:) contextInfo:(__bridge_retained void *)listID];
}

- (void)deleteHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context  {
    NSNumber *l = (__bridge_transfer NSNumber *)context;
    if (code == NSAlertFirstButtonReturn) {
        [_bridge performTask:PRDeleteListTask(l)];
    }
}

- (void)renamePlaylist:(PRListID *)listID {
    int row = [self rowForListID:listID];
    if (row != -1) {
        [tableView editColumn:0 row:row withEvent:nil select:YES];
    }
}

- (void)editPlaylist:(PRListID *)playlist {
    
}

- (void)duplicatePlaylistMenuAction:(NSMenuItem *)menuItem {
    [self duplicatePlaylist:@([menuItem tag])];
}

- (void)renamePlaylistMenuAction:(NSMenuItem *)menuItem {
    [self renamePlaylist:@([menuItem tag])];
}

- (void)deletePlaylistMenuAction:(NSMenuItem *)menuItem {
    [self deletePlaylist:@([menuItem tag])];
}

- (void)editPlaylistMenuAction:(NSMenuItem *)menuItem {
    [self editPlaylist:@([menuItem tag])];
}

#pragma mark - Update

- (void)update {
    [newPlaylistButton setState:NSOffState];
    
    NSArray *lists = nil;
    [[_db playlists] zLists:&lists];
    lists = [lists PRMap:^(NSInteger idx, PRList *i){
        if ([[i type] isEqual:PRListTypeLibrary] || [[i type] isEqual:PRListTypeNowPlaying]) {
            return (PRList *)nil;
        }
        return i;
    }];
    _lists = lists;
    
    [tableView reloadData];
    int rows = [self numberOfRowsInTableView:tableView];
    if (rows < 5) {
        rows = 5;
    }
    float height = 53 + 42 * rows + 50;
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, height)];
    [tableView updateTrackingArea];
    
    [_placeholder setHidden:[_lists count] != 0];
}

#pragma mark - NSTableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView_ {
    if (tableView_ != tableView) {
        return 0;
    }
    return [_lists count];
}

- (id)tableView:(NSTableView *)tableView_ objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView_ != tableView) {
        return nil;
    }
    PRList *list = _lists[row];
    if ([tableView_ editedRow] == row) {
        return [_lists[row] title];
    }

    NSInteger count = 0;
    [[_db playlists] zCountForList:[list listID] out:&count];
    NSString *subtitle = [NSString stringWithFormat:@"%ld songs", (long)count];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [list title], @"title",
                                [list type], @"type",
                                subtitle, @"subtitle", 
                                [NSImage imageNamed:@"NSListViewTemplate"], @"icon",
                                [list listID], @"playlist",
                                @(YES), @"delete",
                                nil];
    return dictionary;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // if ([object isKindOfClass:[NSString class]]) {
    //     int playlist = [self playlistForRow:row];
    //     if (playlist == -1) {
    //         return;
    //     }
    //     PRList *list = [PRList numberWithInt:playlist];
    //     [[_db playlists] setTitle:object forList:list];
    //     [[NSNotificationCenter defaultCenter] postListDidChange:list];
    // }
}

#pragma mark - NSTableView Delegate

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    return [NSIndexSet indexSet];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aCell objectValue] isKindOfClass:[NSString class]]) {
        return;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[aCell objectValue]];
    if ([(PRRolloverTableView *)aTableView mouseOverRow] == rowIndex) {
        [dictionary setObject:@YES forKey:@"mouseOver"];
        [dictionary setObject:[NSValue valueWithPoint:[(PRRolloverTableView *)aTableView pointInCell]] forKey:@"point"];
    } else {
        [dictionary setObject:@NO forKey:@"mouseOver"];
        [dictionary setObject:[NSValue valueWithPoint:NSMakePoint(0, 0)] forKey:@"point"];
    }
    
    [aCell setObjectValue:dictionary];
    [aCell setTarget:self];
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return YES;
}

#pragma mark - Misc

- (PRListID *)listIDForRow:(int)row {
    return [_lists[row] listID];
}

- (int)rowForListID:(PRListID *)listID {
    for (int i = 0; i < [_lists count]; i++) {
        if ([[_lists[i] listID] isEqual:listID]) {
            return i;
        }
    }
    return 0;
}

@end
