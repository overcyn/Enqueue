#import "PRPlaylistsViewController.h"
#import "PRDb.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRMainWindowController.h"
#import "PRGradientView.h"
#import "PRScrollView.h"
#import "PRRolloverTableView.h"
#import "NSScrollView+Extensions.h"
#import "PRStringFormatter.h"
#import "PRLog.h"


@implementation PRPlaylistsViewController

// ========================================
// Initialization
// ========================================

- (id)      initWithDb:(PRDb *)db_
  mainWindowController:(PRMainWindowController *)win_;
{
	if ((self = [super initWithNibName:@"PRPlaylistsView" bundle:nil])) {
		win = win_;
        db = db_;
        stringFormatter = [[PRStringFormatter alloc] init];
        [stringFormatter setMaxLength:80];
	}
	return self;
}

- (void)dealloc
{
    [stringFormatter release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, 795)];
    [(NSScrollView *)[self view] setDocumentView:[background superview]];
    [(NSScrollView *)[self view] scrollToTop];
    
    [tableView setRowHeight:42];
    [tableView setIntercellSpacing:NSMakeSize(0, 0)];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableViewAction)];
    [tableView setTrackMouseWithinCell:TRUE];
    [[[[tableView tableColumns] objectAtIndex:0] dataCell] setFormatter:stringFormatter];
    
    [divider setColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    
	[self playlistsDidChangeNotification:nil];
	
	// buttons
	[newSmartPlaylistButton setTarget:self];
	[newSmartPlaylistButton setAction:@selector(newSmartPlaylist)];
	[newPlaylistButton setTarget:self];
	[newPlaylistButton setAction:@selector(newStaticPlaylist)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(playlistsDidChangeNotification:)
												 name:PRPlaylistsDidChangeNotification 
											   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(playlistDidChangeNotification:)
												 name:PRPlaylistDidChangeNotification 
											   object:nil];
    [self update];
}

// ========================================
// Action
// ========================================

- (void)tableViewAction
{
    [win setCurrentMode:PRLibraryMode];
    int playlist = [[[_datasource objectAtIndex:[tableView clickedRow]] objectForKey:@"playlist"] intValue];
    [win setCurrentPlaylist:playlist];
}

- (void)newStaticPlaylist
{
	PRPlaylist playlist = [[db playlists] addStaticPlaylist];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification 
														object:self
													  userInfo:nil];
    [self renamePlaylist:playlist];
}

- (void)newSmartPlaylist
{
	[[db playlists] addSmartPlaylist];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification 
														object:self
													  userInfo:nil];
}

- (void)duplicatePlaylist:(PRPlaylist)playlist
{
    PRPlaylistType type = [[db playlists] typeForPlaylist:playlist];
    if (type == PRStaticPlaylistType) {
        int newPlaylist = [[db playlists] addStaticPlaylist];
        [[db playlists] copyFilesFromPlaylist:playlist toPlaylist:newPlaylist];
        NSString *title = [[db playlists] titleForPlaylist:playlist];
        NSString *title2 = [title stringByAppendingString:@" Copy"];
        [[db playlists] setValue:title2 forPlaylist:newPlaylist attribute:PRTitlePlaylistAttribute];
        [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification object:self userInfo:nil];
        [self renamePlaylist:newPlaylist];
    } else if (type == PRSmartPlaylistType) {
        int newPlaylist = [[db playlists] addSmartPlaylist];
        [[db playlists] setRule:[[db playlists] ruleForPlaylist:playlist] forPlaylist:newPlaylist];
        NSString *title = [[db playlists] titleForPlaylist:playlist];
        NSString *title2 = [title stringByAppendingString:@" Copy"];
        [[db playlists] setValue:title2 forPlaylist:newPlaylist attribute:PRTitlePlaylistAttribute];
        [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification object:self userInfo:nil];
        [self renamePlaylist:newPlaylist];
    }
}

- (void)deletePlaylist:(PRPlaylist)playlist
{
    [[db playlists] removePlaylist:playlist];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification object:self];
}

- (void)renamePlaylist:(PRPlaylist)playlist
{
    int row = [self rowForPlaylist:playlist];
    if (row != -1) {
        [tableView editColumn:0 row:row withEvent:nil select:TRUE];
    }
}

- (void)duplicatePlaylistMenuAction:(NSMenuItem *)menuItem
{
    [self duplicatePlaylist:[menuItem tag]];
}

- (void)renamePlaylistMenuAction:(NSMenuItem *)menuItem
{
    [self renamePlaylist:[menuItem tag]];
}

- (void)deletePlaylistMenuAction:(NSMenuItem *)menuItem
{
    [self deletePlaylist:[menuItem tag]];
}

// ========================================
// Update
// ========================================

- (void)playlistsDidChangeNotification:(NSNotification *)notification
{
    [self update];
}

- (void)playlistDidChangeNotification:(NSNotification *)notification
{
    [self update];
}

- (void)update
{
    [_datasource release];
    _datasource = [[[db playlists] playlistsViewSource] retain];
    [tableView reloadData];
    int rows = [self numberOfRowsInTableView:tableView];
    float height = 235 + 42 * (rows - 2);
    if (height < 400) {
        height = 400;
    }
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, height)];
    [(PRScrollView *)[self view] viewFrameDidChange:nil];
    [background setFrame:NSMakeRect([background frame].origin.x, [[background superview] frame].size.height - height, 650, height)];
    [tableView updateTrackingArea];
}

// ========================================
// NSTableView DataSource
// ========================================

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView_
{
    if (tableView_ != tableView) {
        return 0;
    }
    return [_datasource count];
}

- (id)            tableView:(NSTableView *)tableView_
  objectValueForTableColumn:(NSTableColumn *)tableColumn 
						row:(NSInteger)row
{
    if (tableView_ != tableView) {
        return nil;
    }
    if ([tableView_ editedRow] == row) {
        return [[_datasource objectAtIndex:row] objectForKey:@"title"];
    }

    int playlist = [[[_datasource objectAtIndex:row] objectForKey:@"playlist"] intValue];
    int count = [[db playlists] countForPlaylist:playlist];
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
            icon = [NSImage imageNamed:@"NSListViewTemplate"];
            [[PRLog sharedLog] presentFatalError:nil];
            break;
    }
    bool delete = !([[[_datasource objectAtIndex:row] objectForKey:@"type"] intValue] == PRNowPlayingPlaylistType);
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [[_datasource objectAtIndex:row] objectForKey:@"title"], @"title", 
                                subtitle, @"subtitle", 
                                icon, @"icon",
                                [NSNumber numberWithInt:playlist], @"playlist",
                                [NSNumber numberWithBool:delete], @"delete",
                                nil];
    return dictionary;
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)object 
   forTableColumn:(NSTableColumn *)tableColumn 
              row:(NSInteger)row
{
    if ([object isKindOfClass:[NSString class]]) {
        int playlist = [self playlistForRow:row];
        
        if (playlist == -1) {
            return;
        }
        [[db playlists] setValue:object forPlaylist:playlist attribute:PRTitlePlaylistAttribute];
        [[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistsDidChangeNotification object:self];
    }
}

// ========================================
// NSTableView Delegate
// ========================================

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
	return [NSIndexSet indexSet];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([[aCell objectValue] isKindOfClass:[NSString class]]) {
        return;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[aCell objectValue]];
	if ([(PRRolloverTableView *)aTableView mouseOverRow] == rowIndex) {
        [dictionary setObject:[NSNumber numberWithBool:TRUE] forKey:@"mouseOver"];
        [dictionary setObject:[NSValue valueWithPoint:[(PRRolloverTableView *)aTableView pointInCell]] forKey:@"point"];
    } else {
        [dictionary setObject:[NSNumber numberWithBool:FALSE] forKey:@"mouseOver"];
        [dictionary setObject:[NSValue valueWithPoint:NSMakePoint(0, 0)] forKey:@"point"];
    }
    
    [aCell setObjectValue:dictionary];
    [aCell setTarget:self];
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return FALSE;
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return TRUE;
}

// ========================================
// Misc
// ========================================

- (int)playlistForRow:(int)row
{
    return [[[_datasource objectAtIndex:row] objectForKey:@"playlist"] intValue];
}

- (int)rowForPlaylist:(PRPlaylist)playlist
{
    for (int i = 0; i < [_datasource count]; i++) {
        if ([[[_datasource objectAtIndex:i] objectForKey:@"playlist"] intValue] == playlist) {
            return i;
        }
    }
    return 0;
}

@end