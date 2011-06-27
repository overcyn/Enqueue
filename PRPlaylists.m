#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRPlaybackOrder.h"


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

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)create_error:(NSError **)error
{
    // create playlists table
    if (![db executeStatement:@"CREATE TABLE IF NOT EXISTS playlists ("
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
          ")" 
                       _error:nil]) {
        return FALSE;
    }
	
    // create playlist_items
    if (![db executeStatement:@"CREATE TABLE IF NOT EXISTS playlist_items ("
          "playlist_item_id INTEGER PRIMARY KEY AUTOINCREMENT, "
          "playlist_id INTEGER NOT NULL, "
          "playlist_index INTEGER NOT NULL, "
          "file_id INTEGER NOT NULL, "
          "UNIQUE(playlist_id, playlist_index), "
          "FOREIGN KEY(playlist_id) REFERENCES playlists(playlist_id) ON UPDATE CASCADE ON DELETE CASCADE, "
          "FOREIGN KEY(file_id) REFERENCES library(file_id) ON UPDATE CASCADE ON DELETE CASCADE"
          ")" 
                       _error:nil]) {
        return FALSE;
    }
    
    if (![db executeStatement:@"CREATE INDEX IF NOT EXISTS index_playlistItems ON playlist_items ("
          "file_id, "
          "playlist_item_id"
          ")"
                       _error:nil]) {
        return FALSE;
    }
	return TRUE;
}

- (BOOL)initialize_error:(NSError **)error
{
    return TRUE;
}

- (BOOL)validate_error:(NSError **)error
{
    // check if library exists. if not create.
    NSArray *result;
    if (![db executeStatement:@"SELECT playlist_id FROM playlists WHERE type=0"
                 withBindings:nil
                       result:&result
                       _error:nil]) {
        return FALSE;
    }
    if ([result count] != 1) {
        PRPlaylist libraryPlaylist;
        if (![self appendPlaylist:&libraryPlaylist _error:nil] ||
            ![self setValue:@"Music" forPlaylist:libraryPlaylist attribute:PRTitlePlaylistAttribute _error:error] ||
            ![self setValue:[NSNumber numberWithInt:PRLibraryPlaylistType] forPlaylist:libraryPlaylist attribute:PRTypePlaylistAttribute _error:error]) {
            return FALSE;
        }
    }
	
	// check if queue playlist exists. if not create.
    if (![db executeStatement:@"SELECT playlist_id FROM playlists WHERE type=1"
                 withBindings:nil
                       result:&result
                       _error:nil]) {
        return FALSE;
    }
    if ([result count] != 1) {
        PRPlaylist nowPlayingPlaylist;
        if (![self appendPlaylist:&nowPlayingPlaylist _error:nil] ||
            ![self setValue:@"Now Playing" forPlaylist:nowPlayingPlaylist attribute:PRTitlePlaylistAttribute _error:error] ||
            ![self setValue:[NSNumber numberWithInt:PRNowPlayingPlaylistType] forPlaylist:nowPlayingPlaylist attribute:PRTypePlaylistAttribute _error:error]) {
            return FALSE;
        }
    }
	
    // clean up
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
			@"title",					[NSNumber numberWithInt:PRTitlePlaylistAttribute],
			@"type",					[NSNumber numberWithInt:PRTypePlaylistAttribute],
			@"rules",					[NSNumber numberWithInt:PRRulesPlaylistAttribute],
			@"listViewColumnInfo",		[NSNumber numberWithInt:PRListViewColumnInfoPlaylistAttribute],
			@"listViewSortColumn",		[NSNumber numberWithInt:PRListViewSortColumnPlaylistAttribute],
			@"listViewAscending",		[NSNumber numberWithInt:PRListViewAscendingPlaylistAttribute],
			@"albumListViewColumnInfo",	[NSNumber numberWithInt:PRAlbumListViewColumnInfoPlaylistAttribute],			
			@"albumListViewSortColumn",	[NSNumber numberWithInt:PRAlbumListViewSortColumnPlaylistAttribute],
			@"albumListViewAscending",	[NSNumber numberWithInt:PRAlbumListViewAscendingPlaylistAttribute],
			@"search",					[NSNumber numberWithInt:PRSearchPlaylistAttribute], 
			@"browser_1_attribute",		[NSNumber numberWithInt:PRBrowser1AttributePlaylistAttribute], 
			@"browser_2_attribute",		[NSNumber numberWithInt:PRBrowser2AttributePlaylistAttribute], 
			@"browser_3_attribute",		[NSNumber numberWithInt:PRBrowser3AttributePlaylistAttribute], 
			@"browser_1_selection",		[NSNumber numberWithInt:PRBrowser1SelectionPlaylistAttribute], 
			@"browser_2_selection",		[NSNumber numberWithInt:PRBrowser2SelectionPlaylistAttribute], 
			@"browser_3_selection",		[NSNumber numberWithInt:PRBrowser3SelectionPlaylistAttribute],
			@"browserInfo",				[NSNumber numberWithInt:PRBrowserInfoPlaylistAttribute],
			@"libraryViewMode",			[NSNumber numberWithInt:PRLibraryViewModePlaylistAttribute],
			nil];
}

+ (NSString *)columnNameForPlaylistAttribute:(PRPlaylistAttribute)attribute
{
	return [[PRPlaylists columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
}

- (BOOL)cleanPlaylists
{
    return TRUE;
}

- (BOOL)cleanPlaylistItems_error:(NSError **)error
{
    NSArray *playlists;
    if (![self playlistArray:&playlists _error:nil]) {
        return FALSE;
    }
    
    for (NSNumber *i in playlists) {
        PRPlaylist playlist = [i intValue];
        
        PRPlaylistType playlistType;
        [self intValue:(int *)&playlistType forPlaylist:playlist attribute:PRTypePlaylistAttribute _error:nil];
        int count;
        [self count:&count forPlaylist:playlist _error:nil];
        if (!(playlistType == PRStaticPlaylistType || playlistType == PRNowPlayingPlaylistType) || count == 0) {
            continue;
        }
        
        // get max and min values for playlist_index
        NSArray *result;
        NSDictionary *bindings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist] 
                                                             forKey:[NSNumber numberWithInt:1]];
        if (![db executeStatement:@"SELECT max(playlist_index) FROM playlist_items WHERE playlist_id = ?1" 
                     withBindings:bindings
                           result:&result
                           _error:nil]) {
            return FALSE;
        }
        int max = [[result objectAtIndex:0] intValue];
        if (![db executeStatement:@"SELECT min(playlist_index) FROM playlist_items WHERE playlist_id = ?1" 
                     withBindings:bindings
                           result:&result
                           _error:nil]) {
            return FALSE;
        }
        int min = [[result objectAtIndex:0] intValue];
        
        // if max and min are invalid, update playlist_indexes of playlist_items
        if (min != 1 || max != count) {
            // clean playlist
            NSLog(@"PRPlaylistItems Inconsistency error!!!!!!!!!!!!!!!!!!!!!");            
            
            if (![db executeStatement:@"BEGIN" _error:nil]) {
                [db executeStatement:@"ROLLBACK" _error:nil];
                return FALSE;
            }
            
            NSArray *playlistItemArray;
            if (![db executeStatement:@"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = :playlist ORDER BY playlist_index" 
                         withBindings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist] 
                                                                  forKey:[NSNumber numberWithInt:1]]
                               result:&playlistItemArray
                               _error:nil]) {
                [db executeStatement:@"ROLLBACK" _error:nil];
                return FALSE;
            }
            
            for (int i = 0; i < [playlistItemArray count]; i++) {
                NSDictionary *bindings = 
                    [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSNumber numberWithInt:i + 1], [NSNumber numberWithInt:1],
                     [playlistItemArray objectAtIndex:i], [NSNumber numberWithInt:2], nil];
                if (![db executeStatement:@"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2" 
                             withBindings:bindings 
                                   result:nil 
                                   _error:nil]) {
                    [db executeStatement:@"ROLLBACK" _error:nil];
                }
            }
            
            if (![db executeStatement:@"COMMIT" _error:nil]) {
                [db executeStatement:@"ROLLBACK" _error:nil];
            }
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
        PRPlaylistType playlistType;
        [self intValue:(int *)&playlistType 
           forPlaylist:[i intValue]
             attribute:PRTypePlaylistAttribute 
                _error:nil];
        
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
    NSString *statementString = @"SELECT playlist_id FROM playlists ORDER BY type, title COLLATE NOCASE, playlist_id";
    NSArray *columnTypes = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [PRStatement executeString:statementString withDb:db bindings:nil columnTypes:columnTypes];
    NSMutableArray *playlists = [NSMutableArray array];
    for (NSArray *i in results) {
        [playlists addObject:[i objectAtIndex:0]];
    }
    return playlists;
}

- (NSArray *)playlistsWithAttributes
{
    return nil;
}

- (BOOL)playlistCount:(int *)count _error:(NSError **)error
{
	return [db count:count forTable:@"playlists" _error:error];
}

- (BOOL)playlistArray:(NSArray **)playlistArray _error:(NSError **)error
{
    return [db executeStatement:@"SELECT playlist_id FROM playlists ORDER BY type, title COLLATE NOCASE, playlist_id" 
                   withBindings:nil 
                         result:playlistArray 
                         _error:error];
}

- (BOOL)addPlaylist:(PRPlaylist *)playlist atIndex:(int)index _error:(NSError **)error
{
    *playlist = index;
    return [db executeStatement:@"INSERT INTO playlists (playlist_id) VALUES (?)" 
                   withBindings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] 
                                                            forKey:[NSNumber numberWithInt:1]]
                         _error:error];
}

- (BOOL)appendPlaylist:(PRPlaylist *)playlist _error:(NSError **)error
{
    if (![db executeStatement:@"BEGIN" _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    if (![db executeStatement:@"INSERT INTO playlists DEFAULT VALUES" _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    NSArray *array;
    if (![db executeStatement:@"SELECT MAX(playlist_id) FROM playlists" 
                 withBindings:nil 
                       result:&array
                       _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    *playlist = [[array objectAtIndex:0] intValue];
    if (![db executeStatement:@"COMMIT" _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    return TRUE;
}

- (BOOL)removePlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist]
                                                         forKey:[NSNumber numberWithInt:1]];
    if (![db executeStatement:@"DELETE FROM playlists WHERE playlist_id = :playlist_id" 
                withBindings:bindings
                      _error:error]) {
        return FALSE;
    }
    
    if (![self propagatePlaylistDelete_error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)addStaticPlaylist:(PRPlaylist *)playlist _error:(NSError *)error
{
	if (![self appendPlaylist:playlist _error:NULL]) {
        return FALSE;
    }
	if (![self setValue:@"Untitled Playlist" 
            forPlaylist:*playlist 
              attribute:PRTitlePlaylistAttribute 
                 _error:NULL]) {
        return FALSE;
    }
	if (![self setValue:[NSNumber numberWithInt:PRStaticPlaylistType] 
            forPlaylist:*playlist 
              attribute:PRTypePlaylistAttribute 
                 _error:NULL]) {
        return FALSE;
    }
	return TRUE;
}

- (BOOL)addSmartPlaylist:(PRPlaylist *)playlist _error:(NSError *)error
{
	if (![self appendPlaylist:playlist _error:NULL]) {
        return FALSE;
    }
	if (![self setValue:@"Untitled Smart Playlist" 
            forPlaylist:*playlist 
              attribute:PRTitlePlaylistAttribute 
                 _error:NULL]) {
        return FALSE;
    }
	if (![self setValue:[NSNumber numberWithInt:PRSmartPlaylistType] 
            forPlaylist:*playlist 
              attribute:PRTypePlaylistAttribute 
                 _error:NULL]) {
        return FALSE;
    }
	return TRUE;
}

- (BOOL)value:(id *)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error
{
	NSString *column = [[PRPlaylists columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	return [db value:value forColumn:column row:playlist key:@"playlist_id" table:@"playlists" _error:error];
}

- (BOOL)intValue:(int *)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error
{
	NSString *column = [[PRPlaylists columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	return [db intValue:value forColumn:column row:playlist key:@"playlist_id" table:@"playlists" _error:error];
}

- (BOOL)setValue:(id)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error
{
	NSString *column = [PRPlaylists columnNameForPlaylistAttribute:attribute];
	return [db setValue:value forColumn:column row:playlist key:@"playlist_id" table:@"playlists" _error:error];
}

- (BOOL)setIntValue:(int)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error
{
	NSString *column = [[PRPlaylists columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	return [db setIntValue:value forColumn:column row:playlist key:@"playlist_id" table:@"playlists" _error:error];
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

- (BOOL)count:(int *)count forPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    NSArray *result;
    if (![db executeStatement:@"SELECT COUNT(*) FROM playlist_items WHERE playlist_id = ?" 
                 withBindings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist] 
                                                          forKey:[NSNumber numberWithInt:1]]
                       result:&result 
                       _error:error]) {
        return FALSE;
    }
    *count = [[result objectAtIndex:0] intValue];
    return TRUE; 
}

- (BOOL)file:(PRFile *)file atIndex:(int)index forPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    NSArray *result;
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"SELECT file_id FROM playlist_items WHERE playlist_id = ? AND playlist_index = ?" 
                 withBindings:bindings
                       result:&result 
                       _error:error]) {
        return FALSE;
    }
    if ([result count] != 1 || ![[result objectAtIndex:0] isKindOfClass:[NSNumber class]]) {
        return FALSE;
    }
    *file = [[result objectAtIndex:0] intValue];
    return TRUE;
}

- (BOOL)contains:(BOOL *)contains file:(PRFile)file inPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    NSArray *result;
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"SELECT file_id FROM playlist_items WHERE file_id = ?1 AND playlist_id = ?2" 
                 withBindings:bindings
                      result:&result
                      _error:error]) {
        return FALSE;
    }
    *contains = [result count] > 0;
    return TRUE;
}

- (BOOL)addFile:(PRFile)file atIndex:(int)index toPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{	
	// increment playlist_indexes greater than or equal to index
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"UPDATE playlist_items "
          "SET playlist_index = playlist_index + 10000001 "
          "WHERE playlist_index >= ?1 AND playlist_id = ?2" 
                 withBindings:bindings 
                       _error:nil]) {
        return FALSE;
    }
	
    // increment playlist_indexes greater than or equal to index
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"UPDATE playlist_items "
          "SET playlist_index = playlist_index - 10000000 "
          "WHERE playlist_index >= ?1 AND playlist_id = ?2" 
                 withBindings:bindings 
                       _error:nil]) {
        return FALSE;
    }
	
	// insert file
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], 
                [NSNumber numberWithInt:file], [NSNumber numberWithInt:3], nil];
    if (![db executeStatement:@"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
          "VALUES (?1, ?2, ?3)" 
                withBindings:bindings 
                       _error:nil]) {
        return FALSE;
    }
	return TRUE;
}

- (BOOL)appendFile:(PRFile)file toPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
	int count;
    if (![self count:&count forPlaylist:playlist _error:error]) {
        return FALSE;
    }
    
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:count + 1], [NSNumber numberWithInt:2],
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:3], nil];
	if (![db executeStatement:@"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
          "VALUES (?1, ?2, ?3)" 
                 withBindings:bindings 
                       _error:nil]) {
        return FALSE;
    }
	return TRUE;
}

- (BOOL)removeFileAtIndex:(int)index forPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    // Begin
    if (![db executeStatement:@"BEGIN" _error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // delete playlist ids
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index = ?2"
                 withBindings:bindings 
                       _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // decrement playlists_ids greater than index
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"UPDATE playlist_items SET playlist_index = playlist_index + 10000000 WHERE playlist_index > ?1 AND playlist_id = ?2"
                 withBindings:bindings 
                       _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:index], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"UPDATE playlist_items SET playlist_index = playlist_index - 10000001 WHERE playlist_index > ?1 AND playlist_id = ?2"
                 withBindings:bindings 
                       _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    if ([self propagatePlaylistItemDelete_error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    if (![db executeStatement:@"COMMIT" _error:nil]) {
		[db executeStatement:@"ROLLBACK" _error:nil];
		return FALSE;
	}

	return TRUE;
}

- (BOOL)removeFilesAtIndexes:(NSIndexSet *)indexSet forPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{	
	// check for valid indexes
	int count;
	[self count:&count forPlaylist:playlist _error:error];
	if ([indexSet firstIndex] < 1 ||
		[indexSet lastIndex] > count ||
		[indexSet count] == 0) {
		NSLog(@"PRPlaylists removeFileAtIndexes:%@ forPlaylist:%d error: Invalid Indexes", indexSet, playlist);
		return FALSE;
	}
	
	// Begin
    if (![db executeStatement:@"BEGIN" _error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // create temp table
    if (![db executeStatement:@"CREATE TEMP TABLE IF NOT EXISTS indexesToRemove (index2 INTEGER PRIMARY KEY)" _error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
	
	// fill temp table with indexes to remove
	NSInteger index = 0;
	while ((index = [indexSet indexGreaterThanIndex:index]) != NSNotFound) {
		if (![db executeStatement:@"INSERT INTO indexesToRemove (index2) VALUES (?1)"
                     withBindings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] 
                                                              forKey:[NSNumber numberWithInt:1]]
                           _error:error]) {
			[db executeStatement:@"ROLLBACK" _error:nil];
			return FALSE;
		}
	}
	
	// Delete files at indexes
	if (![db executeStatement:@"DELETE FROM playlist_items WHERE playlist_id = ?1 "
          "AND playlist_index IN (SELECT index2 FROM indexesToRemove)"
                 withBindings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist] 
                                                          forKey:[NSNumber numberWithInt:1]]
                       _error:error]) {
		[db executeStatement:@"ROLLBACK" _error:nil];
		return FALSE;
	}
	
	// Delete temp table
	if (![db executeStatement:@"DROP TABLE indexesToRemove" _error:nil]) {
		[db executeStatement:@"ROLLBACK" _error:nil];
		return FALSE;
	}
	
	// Get array of playlist_item_ids ordered by playlists_index
    NSArray *result;
    if (![db executeStatement:@"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index" 
                 withBindings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlist]
                                                          forKey:[NSNumber numberWithInt:1]]
                       result:&result
                       _error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // for each playlist_item_id update with new playlist_index
    for (int i = 0; i < [result count]; i++) {
        NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:i+1], [NSNumber numberWithInt:1], 
                                  [result objectAtIndex:i], [NSNumber numberWithInt:2], nil];
        if (![db executeStatement:@"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2" 
                     withBindings:bindings
                           _error:nil]) {
            [db executeStatement:@"ROLLBACK" _error:nil];
			return FALSE;
        }
    }
    
    if ([self propagatePlaylistItemDelete_error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
	// Commit
	if (![db executeStatement:@"COMMIT" _error:nil]) {
		[db executeStatement:@"ROLLBACK" _error:nil];
		return FALSE;
	}
	return TRUE;
}

- (BOOL)clearPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    // Begin
    if (![db executeStatement:@"BEGIN" _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // Clear playlist
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    if (![db executeStatement:@"DELETE FROM playlist_items WHERE playlist_id = ?1" 
                 withBindings:bindings
                       _error:error]) {
        return FALSE;
    }
    
    // Propogate
    if ([self propagatePlaylistItemDelete_error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // Commit
    if (![db executeStatement:@"COMMIT" _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    return TRUE;
}

- (BOOL)clearPlaylist:(PRPlaylist)playlist exceptForIndex:(int)index _error:(NSError **)error
{
    // Begin
    if (![db executeStatement:@"BEGIN" _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // Delete all items execpt index
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], 
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index != ?2" 
                 withBindings:bindings
                       _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // set new playlist_index
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    if (![db executeStatement:@"UPDATE playlist_items SET playlist_index = 1 WHERE playlist_id = ?1" 
                 withBindings:bindings
                       _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // Propogate
    if ([self propagatePlaylistItemDelete_error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
    // Commit
    if (![db executeStatement:@"COMMIT" _error:error]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
	return TRUE;
}

- (BOOL)moveItemsAtIndexes:(NSIndexSet *)indexSet inPlaylist:(PRPlaylist)playlist toRow:(int)row error:(NSError **)error
{
	// validate input
	int countForPlaylist;
	if (![self count:&countForPlaylist forPlaylist:playlist _error:error]) {
		return FALSE;
	}
	if ([indexSet firstIndex] < 1 ||
		[indexSet lastIndex] > countForPlaylist ||
		[indexSet count] == 0 || 
		row > countForPlaylist + 1 ||
		row < 1) {
		NSLog(@"PRPlaylists moveFileAtIndexes:forPlaylist:error: Invalid Indexes or playlist");
		return FALSE;
	}
	
	// Begin    
	if (![db executeStatement:@"BEGIN" _error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
		return FALSE;
	}
	
	// Get array of playlist_item_ids ordered by playlists_index
    NSArray *playlistItemIDArray;
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
	if (![db executeStatement:@"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index" 
                 withBindings:bindings
                       result:&playlistItemIDArray
                       _error:nil]) {
		[db executeStatement:@"ROLLBACK" _error:nil];
		return FALSE;
	}

	// Set playlist_id = -1 for all files
    bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:[self libraryPlaylist]], [NSNumber numberWithInt:1],
                [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2], nil];
	if (![db executeStatement:@"UPDATE playlist_items SET playlist_id = ?1 WHERE playlist_id = ?2"
                 withBindings:bindings
                       _error:nil]) {
        [db executeStatement:@"ROLLBACK" _error:nil];
        return FALSE;
    }
    
	// Update each playlistItemID with new playlistIndex
	int newPlaylistIndex;
	
	row = row - [indexSet countOfIndexesInRange:NSMakeRange(1, row - 1)];
	int count = 1;
	int count2 = row;
	
	for (int i = 0; i < [playlistItemIDArray count]; i++) {
		int playlistItemID = [[playlistItemIDArray objectAtIndex:i] intValue];
		if (count == row) {
			count = row + [indexSet count];
		}
		if ([indexSet containsIndex:i+1]) {
			newPlaylistIndex = count2++;
		} else {
			newPlaylistIndex = count++;
		}
		
		bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                    [NSNumber numberWithInt:newPlaylistIndex], [NSNumber numberWithInt:2],
                    [NSNumber numberWithInt:playlistItemID], [NSNumber numberWithInt:3], nil];
		if (![db executeStatement:@"UPDATE playlist_items SET playlist_id = ?1, playlist_index = ?2 WHERE playlist_item_id = ?3" 
                     withBindings:bindings
                           _error:error]) {
			[db executeStatement:@"ROLLBACK" _error:nil];
			return FALSE;
		}
	}
	
	// Commit
	if (![db executeStatement:@"COMMIT" _error:nil]) {
		[db executeStatement:@"ROLLBACK" _error:nil];
		return FALSE;
	}
	return TRUE;
}

- (BOOL)appendFilesFromLibraryViewSourceToPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    // Begin    
	if (![db executeStatement:@"BEGIN" _error:nil]) {
		return FALSE;
	}
    
    // playlist count
	int count;
    if (![self count:&count forPlaylist:playlist _error:error]) {
        return FALSE;
    }
	
	// create temp table
    NSString *statement = [NSString stringWithFormat:@"CREATE TEMP TABLE temp_table "
                           "(playlist_index INTEGER PRIMARY KEY, "
                           "file_id INTEGER, "
                           "playlist_id INTEGER DEFAULT %d)", playlist];
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    
    // insert temp value into temp table to increase the integer primary key
    statement = @"INSERT INTO temp_table (playlist_index, playlist_id) VALUES (?1, -1)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:count], [NSNumber numberWithInt:1], nil];
    if (![db executeStatement:statement withBindings:bindings _error:nil]) {
        return FALSE;
    }
    
    // add files from libraryViewSource to temp table
    statement = @"INSERT INTO temp_table (file_id) SELECT file_id FROM libraryViewSource ORDER BY row";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    
    // copy files from temp table to playlist
    statement = @"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
    "SELECT playlist_id, playlist_index, file_id FROM temp_table WHERE playlist_id != -1";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    
    // Drop temp table
    if (![db executeStatement:@"DROP TABLE temp_table" _error:nil]) {
        return FALSE;
    }
    
    // Commit
	if (![db executeStatement:@"COMMIT" _error:nil]) {
		return FALSE;
	}
	return TRUE;
}

- (BOOL)copyFilesFromPlaylist:(PRPlaylist)playlist toPlaylist:(PRPlaylist)playlist2 _error:(NSError **)error
{
    if (![self clearPlaylist:playlist2 _error:nil]) {
        return FALSE;
    }
    NSDictionary *bindings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist2], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:2],
                              nil];
    if (![db executeStatement:@"INSERT INTO playlist_items (file_id, playlist_id, playlist_index) "
          "SELECT file_id, ?1, playlist_index FROM playlist_items WHERE playlist_id = ?2;"
                 withBindings:bindings
                       _error:error]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)playlistItem:(PRPlaylistItem *)playlistItem atIndex:(int)index forPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    NSArray *result;
    if (![db executeStatement:@"SELECT playlist_item_id FROM playlist_items "
          "WHERE playlist_id = ?1 AND playlist_index = ?2"
                 withBindings:bindings
                       result:&result
                       _error:error]) {
        return FALSE;
    }
    if ([result count] != 1) {
        return FALSE;
    }
    *playlistItem = [[result objectAtIndex:0] intValue];
    return TRUE;
}

- (BOOL)index:(int *)index andPlaylist:(PRPlaylist *)playlist forPlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error
{	
	[db intValue:index 
	   forColumn:@"playlist_index" 
			 row:playlistItem
			 key:@"playlist_item_id" 
		   table:@"playlist_items" 
		  _error:error];
	
	[db intValue:playlist 
	   forColumn:@"playlist_id" 
			 row:playlistItem
			 key:@"playlist_item_id" 
		   table:@"playlist_items" 
		  _error:error];
	
	return TRUE;
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