#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRDb.h"
#import "PRPlaybackOrder.h"
#import "PRLog.h"

NSString * const PR_TBL_PLAYLISTS_SQL = @"CREATE TABLE playlists ("
"playlist_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
"type INT, "
"title TEXT, "
"rules BLOB, "
"listViewColumnInfo BLOB, "
"listViewSortColumn INT DEFAULT 2 NOT NULL, "
"listViewAscending INT DEFAULT 1 NOT NULL, "
"albumListViewColumnInfo BLOB, "
"albumListViewSortColumn INT DEFAULT -1 NOT NULL, "
"albumListViewAscending INT DEFAULT 1 NOT NULL, "
"search TEXT DEFAULT '' NOT NULL, "
"browser_1_attribute INT DEFAULT 0 NOT NULL, "
"browser_2_attribute INT DEFAULT 0 NOT NULL, "
"browser_3_attribute INT DEFAULT 2 NOT NULL, "
"browser_1_selection BLOB, "
"browser_2_selection BLOB, "
"browser_3_selection BLOB, "
"browserInfo BLOB, "
"libraryViewMode INT DEFAULT 0 NOT NULL "
")";
NSString * const PR_TBL_PLAYLIST_ITEMS_SQL = @"CREATE TABLE playlist_items ("
"playlist_item_id INTEGER PRIMARY KEY AUTOINCREMENT, "
"playlist_id INTEGER NOT NULL, "
"playlist_index INTEGER NOT NULL, "
"file_id INTEGER NOT NULL, "
"UNIQUE(playlist_id, playlist_index), "
"FOREIGN KEY(playlist_id) REFERENCES playlists(playlist_id) ON UPDATE CASCADE ON DELETE CASCADE, "
"FOREIGN KEY(file_id) REFERENCES library(file_id) ON UPDATE CASCADE ON DELETE CASCADE"
")";
NSString * const PR_IDX_PLAYLIST_ITEMS_SQL = @"CREATE INDEX index_playlistItems ON playlist_items ("
"file_id, playlist_item_id)";


@implementation PRPlaylists

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_
{
    self = [super init];
	if (self) {
		db = db_;
	}
	return self;
}

- (void)create
{
    NSString *string = PR_TBL_PLAYLISTS_SQL;
    [db executeString:string];

    string = PR_TBL_PLAYLIST_ITEMS_SQL;
    [db executeString:string];
    
    string = PR_IDX_PLAYLIST_ITEMS_SQL;
    [db executeString:string];
}

- (void)initialize
{
}

- (BOOL)validate
{
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'playlists'";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_PLAYLISTS_SQL]) {
        return FALSE;
    }

    string = @"SELECT sql FROM sqlite_master WHERE name = 'playlist_items'";
    result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_PLAYLIST_ITEMS_SQL]) {
        return FALSE;
    }
    
    string = @"SELECT sql FROM sqlite_master WHERE name = 'index_playlistItems'";
    result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_PLAYLIST_ITEMS_SQL]) {
        return FALSE;
    }

    // Create library if it doesnt exist
    string = @"SELECT playlist_id FROM playlists WHERE type=0";
    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1) {
        PRPlaylist libraryPlaylist = [self addPlaylist];
        [self setValue:@"Music" forPlaylist:libraryPlaylist attribute:PRTitlePlaylistAttribute];
        [self setValue:[NSNumber numberWithInt:PRLibraryPlaylistType] forPlaylist:libraryPlaylist attribute:PRTypePlaylistAttribute];
    }
	
	// Create now playing playlist if it doesnt exist
    string = @"SELECT playlist_id FROM playlists WHERE type=1";
    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1) {
        PRPlaylist nowPlayingPlaylist = [self addPlaylist];
        [self setValue:@"Now Playing" forPlaylist:nowPlayingPlaylist attribute:PRTitlePlaylistAttribute];
        [self setValue:[NSNumber numberWithInt:PRNowPlayingPlaylistType] forPlaylist:nowPlayingPlaylist attribute:PRTypePlaylistAttribute];
    }
        
    // Create Duplicate playlist if it doesnt exist
    string = @"SELECT playlist_id FROM playlists WHERE type=4";
    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1) {
        string = @"DELETE FROM playlists WHERE type=4";
        [db executeString:string];
        [self addDuplicatePlaylist];
    }
    
    // Create missing playlist if it doesnt exist
    string = @"SELECT playlist_id FROM playlists WHERE type=5";
    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1) {
        string = @"DELETE FROM playlists WHERE type=5";
        [db executeString:string];
        [self addMissingPlaylist];
    }
    
    // Clean up
    [self cleanPlaylists];
    [self cleanPlaylistItems_error:nil];
    return TRUE;
}

// ========================================
// Accessors
// ========================================

+ (NSDictionary *)columnDict
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
            @"title",                   [NSNumber numberWithInt:PRTitlePlaylistAttribute],
            @"type",                    [NSNumber numberWithInt:PRTypePlaylistAttribute],
            @"rules",                   [NSNumber numberWithInt:PRRulesPlaylistAttribute],
            @"listViewColumnInfo",      [NSNumber numberWithInt:PRListViewColumnInfoPlaylistAttribute],
            @"listViewSortColumn",      [NSNumber numberWithInt:PRListViewSortColumnPlaylistAttribute],
            @"listViewAscending",       [NSNumber numberWithInt:PRListViewAscendingPlaylistAttribute],
            @"albumListViewColumnInfo",	[NSNumber numberWithInt:PRAlbumListViewColumnInfoPlaylistAttribute],    	
            @"albumListViewSortColumn",	[NSNumber numberWithInt:PRAlbumListViewSortColumnPlaylistAttribute],
            @"albumListViewAscending",	[NSNumber numberWithInt:PRAlbumListViewAscendingPlaylistAttribute],
            @"search",                  [NSNumber numberWithInt:PRSearchPlaylistAttribute], 
            @"browser_1_attribute",     [NSNumber numberWithInt:PRBrowser1AttributePlaylistAttribute], 
            @"browser_2_attribute",     [NSNumber numberWithInt:PRBrowser2AttributePlaylistAttribute], 
            @"browser_3_attribute",     [NSNumber numberWithInt:PRBrowser3AttributePlaylistAttribute], 
            @"browser_1_selection",     [NSNumber numberWithInt:PRBrowser1SelectionPlaylistAttribute], 
            @"browser_2_selection",     [NSNumber numberWithInt:PRBrowser2SelectionPlaylistAttribute], 
            @"browser_3_selection",     [NSNumber numberWithInt:PRBrowser3SelectionPlaylistAttribute],
            @"browserInfo",             [NSNumber numberWithInt:PRBrowserInfoPlaylistAttribute],
            @"libraryViewMode",         [NSNumber numberWithInt:PRLibraryViewModePlaylistAttribute],
            nil];
}

+ (NSString *)columnNameForPlaylistAttribute:(PRPlaylistAttribute)attribute
{
	return [[PRPlaylists columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
}

+ (PRColumn)columnForPlaylistAttribute:(PRPlaylistAttribute)attribute
{
    NSDictionary *columns = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInt:PRColumnString],   [NSNumber numberWithInt:PRTitlePlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnInteger],  [NSNumber numberWithInt:PRTypePlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnData],     [NSNumber numberWithInt:PRRulesPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnData],     [NSNumber numberWithInt:PRListViewColumnInfoPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnInteger],  [NSNumber numberWithInt:PRListViewSortColumnPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnInteger],  [NSNumber numberWithInt:PRListViewAscendingPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnData],     [NSNumber numberWithInt:PRAlbumListViewColumnInfoPlaylistAttribute],    	
                             [NSNumber numberWithInt:PRColumnInteger],	[NSNumber numberWithInt:PRAlbumListViewSortColumnPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnInteger],	[NSNumber numberWithInt:PRAlbumListViewAscendingPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnString],   [NSNumber numberWithInt:PRSearchPlaylistAttribute], 
                             [NSNumber numberWithInt:PRColumnInteger],  [NSNumber numberWithInt:PRBrowser1AttributePlaylistAttribute], 
                             [NSNumber numberWithInt:PRColumnInteger],  [NSNumber numberWithInt:PRBrowser2AttributePlaylistAttribute], 
                             [NSNumber numberWithInt:PRColumnInteger],  [NSNumber numberWithInt:PRBrowser3AttributePlaylistAttribute], 
                             [NSNumber numberWithInt:PRColumnData],     [NSNumber numberWithInt:PRBrowser1SelectionPlaylistAttribute], 
                             [NSNumber numberWithInt:PRColumnData],     [NSNumber numberWithInt:PRBrowser2SelectionPlaylistAttribute], 
                             [NSNumber numberWithInt:PRColumnData],     [NSNumber numberWithInt:PRBrowser3SelectionPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnData],     [NSNumber numberWithInt:PRBrowserInfoPlaylistAttribute],
                             [NSNumber numberWithInt:PRColumnInteger], 	[NSNumber numberWithInt:PRLibraryViewModePlaylistAttribute],
                             nil];
    return [[columns objectForKey:[NSNumber numberWithInt:attribute]] intValue];
}

- (BOOL)cleanPlaylists
{
    return TRUE;
}

- (BOOL)cleanPlaylistItems_error:(NSError **)error
{
    return TRUE;
    NSArray *playlists = [self playlists];
    for (NSNumber *i in playlists) {
        PRPlaylist playlist = [i intValue];
        PRPlaylistType playlistType = [[self valueForPlaylist:playlist attribute:PRTypePlaylistAttribute] intValue];
        int count = [self countForPlaylist:playlist];
        
        if (!(playlistType == PRStaticPlaylistType || playlistType == PRNowPlayingPlaylistType) || count == 0) {
            continue;
        }
        
        // get max and min values for playlist_index
        NSString *string = @"SELECT max(playlist_index) FROM playlist_items WHERE playlist_id = ?1";
        NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
        NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
        NSArray *result = [db executeString:string withBindings:bindings columns:columns];
        if ([result count] != 0) {
            [[PRLog sharedLog] presentFatalError:nil];
        }
        int max = [[[result objectAtIndex:0] objectAtIndex:0] intValue];
        
        string = @"SELECT min(playlist_index) FROM playlist_items WHERE playlist_id = ?1" ;
        bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
        columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
        result = [db executeString:string withBindings:bindings columns:columns];
        if ([result count] != 0) {
            [[PRLog sharedLog] presentFatalError:nil];
        }
        int min = [[[result objectAtIndex:0] objectAtIndex:0] intValue];
        
        // if max and min are invalid, update playlist_indexes of playlist_items
        if (min != 1 || max != count) {
            [db begin];
            string = @"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = :playlist ORDER BY playlist_index";
            bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
            columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
            NSArray *playlistItemArray = [db executeString:string withBindings:bindings columns:columns];
            
            for (int i = 0; i < [playlistItemArray count]; i++) {
                string = @"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2";
                bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:i + 1], [NSNumber numberWithInt:1],
                            [playlistItemArray objectAtIndex:i], [NSNumber numberWithInt:2], nil];
                [db executeString:string withBindings:bindings columns:nil];
            }
            [db commit];
        }
    }
    
    // get all playlist_ids
    if (![db executeStatement:@"SELECT playlist_id FROM playlist_items GROUP BY playlist_id" 
                 withBindings:nil 
                       result:&playlists 
                       _error:nil]) {
        return FALSE;
    }
    for (NSNumber *i in playlists) {
        PRPlaylistType playlistType = [self typeForPlaylist:[i intValue]];
        // if playlist_type is not PRStaticPlaylist, remove playlist_items with that playlist_id
        if (!(playlistType == PRStaticPlaylistType || playlistType == PRNowPlayingPlaylistType)) {
            NSLog(@"PRPlaylistItems Inconsistency error2!!!!!!!!!!!!!!!!!!!!!");
        }
    }
        
    return TRUE;
}

// ========================================
// Playlist Accessors
// ========================================

- (NSArray *)playlists
{
    NSString *string = @"SELECT playlist_id FROM playlists ORDER BY type, title COLLATE NOCASE, playlist_id";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db executeString:string withBindings:nil columns:columns];
    NSMutableArray *playlists = [NSMutableArray array];
    for (NSArray *i in results) {
        [playlists addObject:[i objectAtIndex:0]];
    }
    return playlists;
}

- (PRPlaylist)libraryPlaylist
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:PRLibraryPlaylistType], [NSNumber numberWithInt:1], nil];
    NSArray *result;
    if (![db executeStatement:@"SELECT playlist_id FROM playlists WHERE type = ?1"
                 withBindings:bindings
                       result:&result 
                       _error:nil]) {
        return FALSE;
    }
    return [[result objectAtIndex:0] intValue];
}

- (PRPlaylist)nowPlayingPlaylist
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:PRNowPlayingPlaylistType], [NSNumber numberWithInt:1], nil];
    NSArray *result;
    if (![db executeStatement:@"SELECT playlist_id FROM playlists WHERE type = ?1"
                 withBindings:bindings
                       result:&result 
                       _error:nil]) {
        return FALSE;
    }
    return [[result objectAtIndex:0] intValue];
}

- (PRPlaylist)addPlaylist
{
    [db begin];
    [db executeString:@"INSERT INTO playlists DEFAULT VALUES"];
    NSString *string = @"SELECT MAX(playlist_id) FROM playlists";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1) {
        [db rollback];
        [[PRLog sharedLog] presentFatalError:nil];
    }
    [db commit];
    return [[[result objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRPlaylist)addStaticPlaylist
{
    [db begin];
    PRPlaylist playlist = [self addPlaylist];
    [self setValue:@"Untitled Playlist" forPlaylist:playlist attribute:PRTitlePlaylistAttribute];
    [self setValue:[NSNumber numberWithInt:PRStaticPlaylistType] forPlaylist:playlist attribute:PRTypePlaylistAttribute];
    [db commit];
    return playlist;
}

- (PRPlaylist)addSmartPlaylist
{
    [db begin];
    PRPlaylist playlist = [self addPlaylist];
    [self setValue:@"Untitled Smart Playlist" forPlaylist:playlist attribute:PRTitlePlaylistAttribute];
    [self setValue:[NSNumber numberWithInt:PRSmartPlaylistType] forPlaylist:playlist attribute:PRTypePlaylistAttribute];
    [db commit];
    return playlist;
}

- (PRPlaylist)addDuplicatePlaylist
{
    [db begin];
    PRPlaylist playlist = [self addPlaylist];
    [self setValue:@"Duplicate Files" forPlaylist:playlist attribute:PRTitlePlaylistAttribute];
    [self setValue:[NSNumber numberWithInt:PRDuplicatePlaylistType] forPlaylist:playlist attribute:PRTypePlaylistAttribute];
    [db commit];
    return playlist;
}

- (PRPlaylist)addMissingPlaylist
{
    [db begin];
    PRPlaylist playlist = [self addPlaylist];
    [self setValue:@"Missing Files" forPlaylist:playlist attribute:PRTitlePlaylistAttribute];
    [self setValue:[NSNumber numberWithInt:PRMissingPlaylistType] forPlaylist:playlist attribute:PRTypePlaylistAttribute];
    [db commit];
    return playlist;
}

- (void)removePlaylist:(PRPlaylist)playlist
{
    NSString *string = @"DELETE FROM playlists WHERE playlist_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    [db executeString:string withBindings:bindings columns:nil];
}

- (void)setValue:(id)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute 
{
    NSString *string = [NSString stringWithFormat:@"UPDATE playlists SET %@ = ?1 WHERE playlist_id = ?2",
                                 [PRPlaylists columnNameForPlaylistAttribute:attribute]];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              value, [NSNumber numberWithInt:1], 
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
}

- (id)valueForPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute
{
    NSString *string = [NSString stringWithFormat:@"SELECT %@ FROM playlists WHERE playlist_id = ?1", 
                           [PRPlaylists columnNameForPlaylistAttribute:attribute]];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObject:[NSNumber numberWithInt:[PRPlaylists columnForPlaylistAttribute:attribute]]];
    NSArray *result = [db executeString:string withBindings:bindings columns:columns];
    if ([result count] != 1) {
        NSLog(@"valueForPlaylist:%d attribute:%d",playlist, attribute);
        [[PRLog sharedLog] presentFatalError:nil];
    }
    return [[result objectAtIndex:0] objectAtIndex:0];
}

- (NSArray *)playlistsViewSource
{
    NSString *string = @"SELECT playlist_id, type, title FROM playlists "
    "ORDER BY type, title COLLATE NOCASE, playlist_id"
    "WHERE type IN (1,2,3)";
    NSArray *columns = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:PRColumnInteger], 
                        [NSNumber numberWithInt:PRColumnInteger], 
                        [NSNumber numberWithInt:PRColumnString], nil];
    NSArray *results = [db executeString:string withBindings:nil columns:columns];
    NSMutableArray *playlists = [NSMutableArray array];
    for (NSArray *i in results) {
        [playlists addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              [i objectAtIndex:0], @"playlist", 
                              [i objectAtIndex:1], @"type", 
                              [i objectAtIndex:2], @"title", 
                              nil]];
    }
    return playlists;
}

// ========================================
// Playlist Update
// ========================================

- (BOOL)propagatePlaylistDelete_error:(NSError **)error
{
    if (![[db playlists] confirmPlaylistDelete_error:nil]) {
        return FALSE;
    }
    return TRUE;
}

// ========================================
// PlaylistItems Accessors
// ========================================

- (void)addFile:(PRFile)file atIndex:(int)index toPlaylist:(PRPlaylist)playlist
{
    [db begin];
    NSString *string = @"UPDATE playlist_items "
    "SET playlist_index = playlist_index + 10000001 "
    "WHERE playlist_index >= ?1 AND playlist_id = ?2";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    string = @"UPDATE playlist_items "
    "SET playlist_index = playlist_index - 10000000 "
    "WHERE playlist_index >= ?1 AND playlist_id = ?2";
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    string = @"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
    "VALUES (?1, ?2, ?3)";
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], 
                [NSNumber numberWithInt:file], [NSNumber numberWithInt:3], nil];
    [db executeString:string withBindings:bindings columns:nil];
    [db commit];
}

- (void)appendFile:(PRFile)file toPlaylist:(PRPlaylist)playlist
{
    [db begin];
    int count = [self countForPlaylist:playlist];
    NSString *string = @"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
    "VALUES (?1, ?2, ?3)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:count + 1], [NSNumber numberWithInt:2],
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:3], nil];
    [db executeString:string withBindings:bindings columns:nil];
    [db commit];
}

- (void)appendFiles:(NSIndexSet *)files toPlaylist:(PRPlaylist)playlist
{
    [db begin];
    NSInteger file = [files firstIndex];
    while (file != NSNotFound) {
        [self appendFile:file toPlaylist:playlist];
        file = [files indexGreaterThanIndex:file];
    }
    [db commit];
}

- (void)removeFileAtIndex:(int)index fromPlaylist:(PRPlaylist)playlist
{
    [db begin];
    NSString *string = @"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index = ?2";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    string = @"UPDATE playlist_items SET playlist_index = playlist_index + 10000000 "
    "WHERE playlist_index > ?1 AND playlist_id = ?2";
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    string = @"UPDATE playlist_items SET playlist_index = playlist_index - 10000001 "
    "WHERE playlist_index > ?1 AND playlist_id = ?2";
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    [self propagatePlaylistDelete_error:nil];
    [self propagatePlaylistItemDelete_error:nil];
    [db commit];
}

- (void)removeFilesAtIndexes:(NSIndexSet *)indexes fromPlaylist:(PRPlaylist)playlist
{
    [db begin];
    
    // create temp table
    NSString *string = @"CREATE TEMP TABLE IF NOT EXISTS indexesToRemove (index2 INTEGER PRIMARY KEY)";
    NSDictionary *bindings;
    [db executeString:string];
    
    // fill temp table with indexes to remove
	NSInteger index = [indexes firstIndex];
	while (index != NSNotFound) {
        string = @"INSERT INTO indexesToRemove (index2) VALUES (?1)";
        bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:index], [NSNumber numberWithInt:1], nil];
        [db executeString:string withBindings:bindings columns:nil];
        index = [indexes indexGreaterThanIndex:index];
	}
    
    // Delete files at indexes
    string = @"DELETE FROM playlist_items WHERE playlist_id = ?1 "
    "AND playlist_index IN (SELECT index2 FROM indexesToRemove)";
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    // Delete temp table
    string = @"DROP TABLE indexesToRemove";
    [db executeString:string];
    
    // Get array of playlist_item_ids ordered by playlists_index
    string = @"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index" ;
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [db executeString:string withBindings:bindings columns:columns];
    
    // for each playlist_item_id update with new playlist_index
    for (int i = 0; i < [result count]; i++) {
        string = @"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2" ;
        bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:i+1], [NSNumber numberWithInt:1], 
                                  [[result objectAtIndex:i] objectAtIndex:0], [NSNumber numberWithInt:2], nil];
        [db executeString:string withBindings:bindings columns:nil];
    }
    
    [self propagatePlaylistItemDelete_error:nil];
    [db commit];
}

- (void)clearPlaylist:(PRPlaylist)playlist
{
    [db begin];
    NSString *string = @"DELETE FROM playlist_items WHERE playlist_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    [db executeString:string withBindings:bindings columns:nil];
    [self propagatePlaylistItemDelete_error:nil];
    [db commit];
}

- (void)clearPlaylist:(PRPlaylist)playlist exceptForIndex:(int)index
{
    [db begin];
    NSString *string = @"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index != ?2";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], 
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    string = @"UPDATE playlist_items SET playlist_index = 1 WHERE playlist_id = ?1";
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    [self propagatePlaylistItemDelete_error:nil];
    [db commit];
}

- (void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(int)index inPlaylist:(PRPlaylist)playlist
{
    // validate input
	int countForPlaylist = [self countForPlaylist:playlist];
    if ([indexes firstIndex] < 1 ||
		[indexes lastIndex] > countForPlaylist ||
		[indexes count] == 0 || 
		index > countForPlaylist + 1 ||
		index < 1) {
		[[PRLog sharedLog] presentFatalError:nil];
	}
	
	[db begin];
	// Get array of playlist_item_ids ordered by playlists_index
    NSString *string = @"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *playlistItemIDArray = [db executeString:string withBindings:bindings columns:columns];
    
	// Set playlist_id = -1 for all files
    string = @"UPDATE playlist_items SET playlist_id = ?1 WHERE playlist_id = ?2";
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:[self libraryPlaylist]], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
	// Update each playlistItemID with new playlistIndex
	int newPlaylistIndex;
	index = index - [indexes countOfIndexesInRange:NSMakeRange(1, index - 1)];
	int count = 1;
	int count2 = index;
	
	for (int i = 0; i < [playlistItemIDArray count]; i++) {
		int playlistItemID = [[[playlistItemIDArray objectAtIndex:i] objectAtIndex:0] intValue];
		if (count == index) {
			count = index + [indexes count];
		}
		if ([indexes containsIndex:i+1]) {
			newPlaylistIndex = count2++;
		} else {
			newPlaylistIndex = count++;
		}
		
        string = @"UPDATE playlist_items SET playlist_id = ?1, playlist_index = ?2 WHERE playlist_item_id = ?3";
		bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                    [NSNumber numberWithInt:newPlaylistIndex], [NSNumber numberWithInt:2],
                    [NSNumber numberWithInt:playlistItemID], [NSNumber numberWithInt:3], nil];
        [db executeString:string withBindings:bindings columns:nil];
	}
	[db commit];
}

- (void)appendFilesFromLibraryViewSourceToPlaylist:(PRPlaylist)playlist
{
    [db begin];
    
	// create temp table
    NSString *string = [NSString stringWithFormat:@"CREATE TEMP TABLE temp_table "
                        "(playlist_index INTEGER PRIMARY KEY, "
                        "file_id INTEGER, "
                        "playlist_id INTEGER DEFAULT %d)", playlist];
    [db executeString:string];
    
    // insert temp value into temp table to increase the integer primary key
    int count = [self countForPlaylist:playlist];
    string = @"INSERT INTO temp_table (playlist_index, playlist_id) VALUES (?1, -1)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:count], [NSNumber numberWithInt:1], nil];
    [db executeString:string withBindings:bindings columns:nil];
    
    // add files from libraryViewSource to temp table
    string = @"INSERT INTO temp_table (file_id) SELECT file_id FROM libraryViewSource ORDER BY row";
    [db executeString:string];
    
    // copy files from temp table to playlist
    string = @"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
    "SELECT playlist_id, playlist_index, file_id FROM temp_table WHERE playlist_id != -1";
    [db executeString:string];
    
    // Drop temp table
    string = @"DROP TABLE temp_table";
    [db executeString:string];
    
    [db commit];
}

- (void)copyFilesFromPlaylist:(PRPlaylist)playlist toPlaylist:(PRPlaylist)playlist2
{
    [db begin];
    [self clearPlaylist:playlist2];
    NSString *string = @"INSERT INTO playlist_items (file_id, playlist_id, playlist_index) "
    "SELECT file_id, ?1, playlist_index FROM playlist_items WHERE playlist_id = ?2;";
    NSDictionary *bindings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist2], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2],
                              nil];
    [db executeString:string withBindings:bindings columns:nil];    
}

- (int)countForPlaylist:(PRPlaylist)playlist
{
    NSString *string = @"SELECT COUNT(*) FROM playlist_items WHERE playlist_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [db executeString:string withBindings:bindings columns:columns];
    if ([result count] != 1) {
        [[PRLog sharedLog] presentFatalError:nil];
    }
    return [[[result objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRPlaylistItem)playlistItemAtIndex:(int)index inPlaylist:(PRPlaylist)playlist
{
    NSString *string = @"SELECT playlist_item_id FROM playlist_items "
    "WHERE playlist_id = ?1 AND playlist_index = ?2";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [db executeString:string withBindings:bindings columns:columns];
    if ([result count] != 1) {
        [[PRLog sharedLog] presentFatalError:nil];
    }
    return [[[result objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRFile)fileAtIndex:(int)index forPlaylist:(PRPlaylist)playlist
{
    NSString *string = @"SELECT file_id FROM playlist_items WHERE playlist_id = ? AND playlist_index = ?";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [db executeString:string withBindings:bindings columns:columns];
    if ([result count] != 1) {
        [[PRLog sharedLog] presentFatalError:nil];
    }
    return [[[result objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRFile)fileForPlaylistItem:(PRPlaylistItem)playlistItem
{
    NSString *string = @"SELECT file_id FROM playlist_items WHERE playlist_item_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:1] , nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db executeString:string withBindings:bindings columns:columns];
    if ([results count] != 1) {
        [[PRLog sharedLog] presentFatalError:nil];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (int)indexForPlaylistItem:(PRPlaylistItem)playlistItem
{
    NSString *string = @"SELECT playlist_index FROM playlist_items WHERE playlist_item_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlistItem], [NSNumber numberWithInt:1] , nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db executeString:string withBindings:bindings columns:columns];
    if ([results count] != 1) {
        NSLog(@"indexForPlaylistItem:%d",playlistItem);
        [[PRLog sharedLog] presentFatalError:nil];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRPlaylist)playlistForPlaylistItem:(PRPlaylistItem)playlistItem
{
    NSString *string = @"SELECT playlist_id FROM playlist_items WHERE playlist_item_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:1] , nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db executeString:string withBindings:bindings columns:columns];
    if ([results count] != 1) {
        [[PRLog sharedLog] presentFatalError:nil];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (BOOL)playlist:(PRPlaylist)playlist containsFile:(PRFile)file
{
    NSString *string = @"SELECT file_id FROM playlist_items WHERE file_id = ?1 AND playlist_id = ?2 LIMIT 1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    NSArray *columns = [NSArray arrayWithObject:[NSNumber numberWithInt:PRColumnInteger]];
    NSArray *result = [db executeString:string withBindings:bindings columns:columns];
    return [result count] > 0;
}

- (BOOL)playlistIndexes:(NSIndexSet **)indexes forPlaylist:(PRPlaylist)playlist file:(PRFile)file _error:(NSError **)error
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:2], nil];
    NSArray *results;
    if (![db executeStatement:@"SELECT playlist_index FROM playlist_items "
          "WHERE file_id = ?2 AND playlist_id = ?1"
                 withBindings:bindings 
                       result:&results 
                       _error:error]) {
        return FALSE;
    }
    
    NSMutableIndexSet *mutableIndexes= [[[NSMutableIndexSet alloc] init] autorelease];
    for (NSNumber *i in results) {
        [mutableIndexes addIndex:[i intValue]];
    }
    *indexes = [[[NSIndexSet alloc] initWithIndexSet:mutableIndexes] autorelease];
    return TRUE;
}

// ========================================
// PlaylistItems Update
// ========================================

- (BOOL)confirmFileDelete_error:(NSError **)error
{
    if (![self cleanPlaylistItems_error:nil]) {
        return FALSE;
    }
    if (![self propagatePlaylistItemDelete_error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)confirmPlaylistDelete_error:(NSError **)error
{
    if (![self propagatePlaylistItemDelete_error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)propagatePlaylistItemDelete_error:(NSError **)error
{
    if (![[db playbackOrder] confirmPlaylistItemDelete:nil]) {
        return FALSE;
    }
    return TRUE;
}

@end