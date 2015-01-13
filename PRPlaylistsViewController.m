#import "PRPlaylistsViewController.h"
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


@implementation PRPlaylistsViewController

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super initWithNibName:@"PRPlaylistsView" bundle:nil])) {return nil;}
    _core = core;
    win = [core win];
    db = [core db];
    smartPlaylistEditorViewController = nil;
    stringFormatter = [[PRStringFormatter alloc] init];
    [stringFormatter setMaxLength:80];
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
    [[[[tableView tableColumns] objectAtIndex:0] dataCell] setFormatter:stringFormatter];
    
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
    if (idx >= [_datasource count]) {return;}
    PRListID *list = [[_datasource objectAtIndex:idx] objectForKey:@"playlist"];
    [[win libraryViewController] setCurrentList:list];
    [win setCurrentMode:PRWindowModeLibrary];
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
    [alert beginSheetModalForWindow:[win window] modalDelegate:self didEndSelector:@selector(newPlaylistHandler:code:context:) contextInfo:NULL];
}

- (void)newPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context {
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    PRListID *list = [[db playlists] addStaticList];
    [[db playlists] setValue:[(NSTextField *)[alert accessoryView] stringValue] forList:list attr:PRListAttrTitle];
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
    [alert beginSheetModalForWindow:[win window] modalDelegate:self didEndSelector:@selector(newSmartPlaylistHandler:code:context:) contextInfo:NULL];
}

- (void)newSmartPlaylistHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context {
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    PRListID *list = [[db playlists] addSmartList];
    [[db playlists] setValue:[(NSTextField *)[alert accessoryView] stringValue] forList:list attr:PRListAttrTitle];
    [[NSNotificationCenter defaultCenter] postListsDidChange];
}

- (void)duplicatePlaylist:(PRPlaylist)playlist {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"New playlist title:"];
    [alert setInformativeText:@""];
    [alert setAccessoryView:[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 0)]];
    NSString *title = @"";
    PRListType *type = [[db playlists] typeForList:[PRListID numberWithInt:playlist]];
    if ([type isEqual:PRListTypeStatic]) {
        title = [[[db playlists] titleForList:[NSNumber numberWithInt:playlist]] stringByAppendingString:@" Copy"];
    } else if ([type isEqual:PRListTypeNowPlaying]) {
        title = @"Untitled Playlist";
    }
    [(NSTextField *)[alert accessoryView] setStringValue:title];   
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert layout];
    NSRect frame2 = [[alert accessoryView] frame];
    frame2.size.height = 24;
    [[alert accessoryView] setFrame:frame2];
    NSRect frame = [[[alert accessoryView] superview] frame];
    frame.size.height = 24;
    [[[alert accessoryView] superview] setFrame:frame];
    [alert beginSheetModalForWindow:[win window] modalDelegate:self didEndSelector:@selector(duplicateHandler:code:context:) contextInfo:(__bridge_retained void *)@(playlist)];
}

- (void)duplicateHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context  {
    NSNumber *l = (__bridge_transfer NSNumber *)context;
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    PRListID *list = [[db playlists] addStaticList];
    [[db playlists] setValue:[(NSTextField *)[alert accessoryView] stringValue] forList:list attr:PRListAttrTitle];
    [[db playlists] copyItemsFromList:l toList:list];
    [[NSNotificationCenter defaultCenter] postListsDidChange];
    [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
}

- (void)deletePlaylist:(PRPlaylist)playlist {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithFormat:@"Delete playlist '%@'?", [[db playlists] valueForList:[NSNumber numberWithInt:playlist] attr:PRListAttrTitle]]];
    [alert setInformativeText:@"This action cannot be undone."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert layout];
    [alert beginSheetModalForWindow:[win window] modalDelegate:self didEndSelector:@selector(deleteHandler:code:context:) contextInfo:(__bridge_retained void *)@(playlist)];
}

- (void)deleteHandler:(NSAlert *)alert code:(NSInteger)code context:(void *)context  {
    NSNumber *l = (__bridge_transfer NSNumber *)context;
    if (code != NSAlertFirstButtonReturn) {
        return;
    }
    [[[_core win] libraryViewController] setCurrentList:[[[_core db] playlists] libraryList]];
    [[db playlists] removeList:l];
    [[NSNotificationCenter defaultCenter] postListsDidChange];
}

- (void)renamePlaylist:(PRPlaylist)playlist {
    int row = [self rowForPlaylist:playlist];
    if (row != -1) {
        [tableView editColumn:0 row:row withEvent:nil select:YES];
    }
}

- (void)editPlaylist:(PRPlaylist)playlist {
    
}

- (void)duplicatePlaylistMenuAction:(NSMenuItem *)menuItem {
    [self duplicatePlaylist:[menuItem tag]];
}

- (void)renamePlaylistMenuAction:(NSMenuItem *)menuItem {
    [self renamePlaylist:[menuItem tag]];
}

- (void)deletePlaylistMenuAction:(NSMenuItem *)menuItem {
    [self deletePlaylist:[menuItem tag]];
}

- (void)editPlaylistMenuAction:(NSMenuItem *)menuItem {
    [self editPlaylist:[menuItem tag]];
}

#pragma mark - Update

- (void)update {
    [newPlaylistButton setState:NSOffState];
    _datasource = [[db playlists] playlistsViewSource];
    [tableView reloadData];
    int rows = [self numberOfRowsInTableView:tableView];
    if (rows < 5) {
        rows = 5;
    }
    float height = 53 + 42 * rows + 50;
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, height)];
    [tableView updateTrackingArea];
    
    [_placeholder setHidden:[_datasource count] != 0];
}

#pragma mark - NSTableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView_ {
    if (tableView_ != tableView) {
        return 0;
    }
    return [_datasource count];
}

- (id)tableView:(NSTableView *)tableView_ objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView_ != tableView) {
        return nil;
    }
    if ([tableView_ editedRow] == row) {
        return [[_datasource objectAtIndex:row] objectForKey:@"title"];
    }

    int playlist = [[[_datasource objectAtIndex:row] objectForKey:@"playlist"] intValue];
    int count = [[db playlists] countForList:[NSNumber numberWithInt:playlist]];
    NSString *subtitle = [NSString stringWithFormat:@"%d songs", count];
    NSImage *icon;
    switch ([[[_datasource objectAtIndex:row] objectForKey:@"type"] intValue]) {
        case PRNowPlayingPlaylistType:
            icon = [NSImage imageNamed:@"PRNoteIcon"];
            break;
        case PRSmartPlaylistType:
            icon = [NSImage imageNamed:@"NSSmartBadgeTemplate"];
            break;
        case PRStaticPlaylistType:
            icon = [NSImage imageNamed:@"NSListViewTemplate"];
            break;
        default:
            [PRException raise:NSInternalInconsistencyException format:@"Invalid Playlist Type"];return nil;
            break;
    }
    bool delete = !([[[_datasource objectAtIndex:row] objectForKey:@"type"] intValue] == PRNowPlayingPlaylistType);
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [[_datasource objectAtIndex:row] objectForKey:@"title"], @"title",
                                [[_datasource objectAtIndex:row] objectForKey:@"type"], @"type",
                                subtitle, @"subtitle", 
                                icon, @"icon",
                                [NSNumber numberWithInt:playlist], @"playlist",
                                [NSNumber numberWithBool:delete], @"delete",
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
    //     [[db playlists] setTitle:object forList:list];
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

- (int)playlistForRow:(int)row {
    return [[[_datasource objectAtIndex:row] objectForKey:@"playlist"] intValue];
}

- (int)rowForPlaylist:(PRPlaylist)playlist {
    for (int i = 0; i < [_datasource count]; i++) {
        if ([[[_datasource objectAtIndex:i] objectForKey:@"playlist"] intValue] == playlist) {
            return i;
        }
    }
    return 0;
}

@end
