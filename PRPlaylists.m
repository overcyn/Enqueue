#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRPlaybackOrder.h"


NSString * const PRListTypeLibrary = @"PRListTypeLibrary";
NSString * const PRListTypeNowPlaying = @"PRListTypeNowPlaying";
NSString * const PRListTypeStatic = @"PRListTypeStatic";
NSString * const PRListTypeSmart = @"PRListTypeSmart";

NSString * const PRListAttrTitle = @"PRListAttrTitle";
NSString * const PRListAttrType = @"PRListAttrType";
NSString * const PRListAttrRules = @"PRListAttrRules";
NSString * const PRListAttrViewMode = @"PRListAttrViewMode";
NSString * const PRListAttrListViewInfo = @"PRListAttrListViewInfo";
NSString * const PRListAttrListViewSortAttr = @"PRListAttrListViewSortAttr";
NSString * const PRListAttrListViewAscending = @"PRListAttrListViewAscending";
NSString * const PRListAttrAlbumListViewInfo = @"PRListAttrAlbumListViewInfo";
NSString * const PRListAttrAlbumListViewSortAttr = @"PRListAttrAlbumListViewSortAttr";
NSString * const PRListAttrAlbumListViewAscending = @"PRListAttrAlbumListViewAscending";
NSString * const PRListAttrSearch = @"PRListAttrSearch";
NSString * const PRListAttrBrowser1Attr = @"PRListAttrBrowser1Attr";
NSString * const PRListAttrBrowser1Selection = @"PRListAttrBrowser1Selection";
NSString * const PRListAttrBrowser2Attr = @"PRListAttrBrowser2Attr";
NSString * const PRListAttrBrowser2Selection = @"PRListAttrBrowser2Selection";
NSString * const PRListAttrBrowser3Attr = @"PRListAttrBrowser3Attr";
NSString * const PRListAttrBrowser3Selection = @"PRListAttrBrowser3Selection";
NSString * const PRListAttrBrowserInfo = @"PRListAttrBrowserInfo";

PRListSort * const PRListSortArtistAlbum = @"PRListSortArtistAlbum";
PRListSort * const PRListSortIndex = @"PRListSortIndex";


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


@implementation PRPlaylists {
    __weak PRDb *_db;
}

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _db = db;
    return self;
}

- (void)create {
    [_db execute:PR_TBL_PLAYLISTS_SQL];
    [_db execute:PR_TBL_PLAYLIST_ITEMS_SQL];
    [_db execute:PR_IDX_PLAYLIST_ITEMS_SQL];
}

- (BOOL)initialize {
    NSArray *rlt = [_db execute:@"SELECT sql FROM sqlite_master WHERE name = 'playlists'"
                      bindings:nil 
                       columns:@[PRColString]];
    if ([rlt count] != 1 || ![[[rlt objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_PLAYLISTS_SQL]) {
        return NO;
    }
    
    rlt = [_db execute:@"SELECT sql FROM sqlite_master WHERE name = 'playlist_items'"
             bindings:nil 
              columns:@[PRColString]];
    if ([rlt count] != 1 || ![[[rlt objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_PLAYLIST_ITEMS_SQL]) {
        return NO;
    }
    
    rlt = [_db execute:@"SELECT sql FROM sqlite_master WHERE name = 'index_playlistItems'"
             bindings:nil 
              columns:@[PRColString]];
    if ([rlt count] != 1 || ![[[rlt objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_PLAYLIST_ITEMS_SQL]) {
        return NO;
    }
    
    // Create library if it doesnt exist
    rlt = [_db execute:@"SELECT playlist_id FROM playlists WHERE type=0"
             bindings:nil 
              columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    if ([rlt count] != 1) {
        PRList *list = [self addList];
        [self setTitle:@"Music" forList:list];
        [self setType:PRListTypeLibrary forList:list];
        [self setAttr:PRItemAttrGenre forBrowser:1 list:list];
        [self setAttr:PRItemAttrArtist forBrowser:2 list:list];
        [self setAttr:PRItemAttrAlbum forBrowser:3 list:list];
    }
    
    // Create now playing playlist if it doesnt exist
    rlt = [_db execute:@"SELECT playlist_id FROM playlists WHERE type=1" 
             bindings:nil 
              columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    if ([rlt count] != 1) {
        PRList *list = [self addList];
        [self setTitle:@"Now Playing" forList:list];
        [self setType:PRListTypeNowPlaying forList:list];
    }
    
    // Clean up
    [self cleanPlaylists];
    [self cleanPlaylistItems];
    return YES;
}

- (BOOL)cleanPlaylists {
    return YES;
}

- (BOOL)cleanPlaylistItems {
    // remove playlist_items where the playlist type is not static or nowplaying
    [_db execute:@"DELETE FROM playlist_items WHERE playlist_id IN "
     "(SELECT playlist_id FROM playlists WHERE type != ?1 || type != ?2)"
       bindings:@{@1:[NSNumber numberWithInt:PRStaticPlaylistType],
     @2:[NSNumber numberWithInt:PRNowPlayingPlaylistType]}
        columns:nil];
    
    // Make sure that there are no gaps in playlist_index
    NSArray *lists = [self lists];
    for (NSNumber *i in lists) {
        PRListType *type = [self typeForList:i];
        int count = [self countForList:i];
        if (!([type isEqual:PRListTypeStatic] || [type isEqual:PRListTypeNowPlaying]) || count == 0) {
            continue;
        }
        
        // get max and min values for playlist_index
        NSArray *rlt = [_db execute:@"SELECT max(playlist_index), min(playlist_index) "
                        "FROM playlist_items WHERE playlist_id = ?1"
                          bindings:@{@1:i}
                           columns:@[PRColInteger, PRColInteger]];
        if ([rlt count] != 1) {
            [PRException raise:PRDbInconsistencyException format:@""];
        }
        int max = [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
        int min = [[[rlt objectAtIndex:0] objectAtIndex:1] intValue];
        
        // if max and min are invalid, update playlist_indexes of playlist_items
        if (min != 1 || max != count) {
            [_db begin];
            NSArray *playlistItems = [_db execute:@"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = :playlist ORDER BY playlist_index"
                                        bindings:@{@1:i}
                                         columns:@[PRColInteger]];
            
            for (int i = 0; i < [playlistItems count]; i++) {
                [_db execute:@"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2" 
                   bindings:@{@1:[NSNumber numberWithInt:i + 1], @2:[[playlistItems objectAtIndex:i] objectAtIndex:0]}
                    columns:nil];
            }
            [_db commit];
        }
    }
    return YES;
}

#pragma mark - Misc

+ (NSArray *)listAttrProperties {
    static NSArray *array = nil; 
    if (!array) {
        array = @[
            @{@"listAttr":PRListAttrTitle, @"columnType":PRColString, @"columnName":@"title"},
            @{@"listAttr":PRListAttrType, @"columnType":PRColInteger, @"columnName":@"type"},
            @{@"listAttr":PRListAttrRules, @"columnType":PRColData, @"columnName":@"rules"},
            @{@"listAttr":PRListAttrListViewInfo, @"columnType":PRColData, @"columnName":@"listViewColumnInfo"},
            @{@"listAttr":PRListAttrListViewSortAttr, @"columnType":PRColInteger, @"columnName":@"listViewSortColumn"},
            @{@"listAttr":PRListAttrListViewAscending, @"columnType":PRColInteger, @"columnName":@"listViewAscending"},
            @{@"listAttr":PRListAttrAlbumListViewInfo, @"columnType":PRColData, @"columnName":@"albumListViewColumnInfo"},
            @{@"listAttr":PRListAttrAlbumListViewSortAttr, @"columnType":PRColInteger, @"columnName":@"albumListViewSortColumn"},
            @{@"listAttr":PRListAttrAlbumListViewAscending, @"columnType":PRColInteger, @"columnName":@"albumListViewAscending"},
            @{@"listAttr":PRListAttrSearch, @"columnType":PRColString, @"columnName":@"search"},
            @{@"listAttr":PRListAttrBrowser1Attr, @"columnType":PRColInteger, @"columnName":@"browser_1_attribute"},
            @{@"listAttr":PRListAttrBrowser2Attr, @"columnType":PRColInteger, @"columnName":@"browser_2_attribute"},
            @{@"listAttr":PRListAttrBrowser3Attr, @"columnType":PRColInteger, @"columnName":@"browser_3_attribute"},
            @{@"listAttr":PRListAttrBrowser1Selection, @"columnType":PRColData, @"columnName":@"browser_1_selection"},
            @{@"listAttr":PRListAttrBrowser2Selection, @"columnType":PRColData, @"columnName":@"browser_2_selection"},
            @{@"listAttr":PRListAttrBrowser3Selection, @"columnType":PRColData, @"columnName":@"browser_3_selection"},
            @{@"listAttr":PRListAttrBrowserInfo, @"columnType":PRColData, @"columnName":@"browserInfo"},
            @{@"listAttr":PRListAttrViewMode, @"columnType":PRColInteger, @"columnName":@"libraryViewMode"},
        ];
    }
    return array;
}

+ (NSString *)columnNameForListAttr:(PRListAttr *)attr {
    for (NSDictionary *i in [PRPlaylists listAttrProperties]) {
        if ([[i objectForKey:@"listAttr"] isEqual:attr]) {
            return [i objectForKey:@"columnName"];
        }
    }
    return @"";
}

+ (PRCol *)columnTypeForListAttr:(PRListAttr *)attr {
    for (NSDictionary *i in [PRPlaylists listAttrProperties]) {
        if ([[i objectForKey:@"listAttr"] isEqual:attr]) {
            return [i objectForKey:@"columnType"];
        }
    }
    return @"";
}

+ (NSNumber *)internalForListType:(PRListType *)listType {
    static NSDictionary *dict = nil;
    if (!dict) {
        dict = @{PRListTypeLibrary:@0,PRListTypeNowPlaying:@1, PRListTypeStatic:@2, PRListTypeSmart:@3};
    }
    return [dict objectForKey:listType];
}

+ (PRListType *)listTypeForInternal:(NSNumber *)internal {
    static NSDictionary *dict = nil;
    if (!dict) {
        dict = @{@0:PRListTypeLibrary, @1:PRListTypeNowPlaying, @2:PRListTypeStatic, @3:PRListTypeSmart};
    }
    return [dict objectForKey:internal];
}

+ (NSString *)columnNameForSortAttr:(PRItemAttr *)sortAttr {
    if ([sortAttr isEqual:PRListSortIndex]) {
        sortAttr = PRItemAttrArtist;
    } else if ([sortAttr isEqual:PRListSortArtistAlbum]) {
        sortAttr = PRItemAttrArtist;
    }
    return [PRLibrary columnNameForItemAttr:sortAttr];
}

+ (NSNumber *)internalForSortAttr:(PRItemAttr *)sortAttr {
    if ([sortAttr isEqual:PRListSortIndex]) {
        return [NSNumber numberWithInt:-2];
    } else if ([sortAttr isEqual:PRListSortArtistAlbum]) {
        return [NSNumber numberWithInt:-1];
    }
    return [PRLibrary internalForItemAttr:sortAttr];
}

+ (PRItemAttr *)sortAttrForInternal:(NSNumber *)internal {
    if ([internal intValue] == -2) {
        return PRListSortIndex;
    } else if ([internal intValue] == -1) {
        return PRListSortArtistAlbum;
    }
    return [PRLibrary itemAttrForInternal:internal];
}

#pragma mark - List Getters

- (NSArray *)lists {
    NSArray *rlt = [_db execute:@"SELECT playlist_id FROM playlists ORDER BY type, title COLLATE NOCASE, playlist_id"
                      bindings:nil 
                       columns:@[PRColInteger]];
    NSMutableArray *playlists = [NSMutableArray array];
    for (NSArray *i in rlt) {
        [playlists addObject:[i objectAtIndex:0]];
    }
    return playlists;    
}

- (PRList *)libraryList {
    NSArray *rlt = [_db execute:@"SELECT playlist_id FROM playlists WHERE type = ?1" 
                      bindings:@{@1:[NSNumber numberWithInt:PRLibraryPlaylistType]}
                       columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (PRList *)nowPlayingList {
    NSArray *rlt = [_db execute:@"SELECT playlist_id FROM playlists WHERE type = ?1" 
                      bindings:@{@1:[NSNumber numberWithInt:PRNowPlayingPlaylistType]}
                       columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (PRList *)addList {
    [_db begin];
    [_db execute:@"INSERT INTO playlists DEFAULT VALUES"];
    NSArray *rlt = [_db execute:@"SELECT MAX(playlist_id) FROM playlists"
                      bindings:nil 
                       columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [_db rollback];
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    [_db commit];
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (PRList *)addStaticList {
    [_db begin];
    PRList *list = [self addList];
    [self setTitle:@"Untitled Playlist" forList:list];
    [self setType:PRListTypeStatic forList:list];
    [self setListViewSortAttr:PRListSortIndex forList:list];
    [_db commit];
    return list;
}

- (PRList *)addSmartList {
    [_db begin];
    PRList *list = [self addList];
    [self setTitle:@"Untitled Smart Playlist" forList:list];
    [self setType:PRListTypeSmart forList:list];
    [self setListViewSortAttr:PRListSortIndex forList:list];
    [_db commit];
    return list;
}

- (void)removeList:(PRList *)list {
    [_db execute:@"DELETE FROM playlists WHERE playlist_id = ?1"
       bindings:@{@1:list}
        columns:nil];
}

- (void)setValue:(id)value forList:(PRList *)list attr:(PRListAttr *)attr {
    [_db execute:[NSString stringWithFormat:@"UPDATE playlists SET %@ = ?1 WHERE playlist_id = ?2", [PRPlaylists columnNameForListAttr:attr]]
       bindings:@{@1:value, @2:list}
        columns:nil];
}

- (id)valueForList:(PRList *)list attr:(PRListAttr *)attr {
    NSArray *rlt = [_db execute:[NSString stringWithFormat:@"SELECT %@ FROM playlists WHERE playlist_id = ?1",
                                [PRPlaylists columnNameForListAttr:attr]]
                      bindings:@{@1:list}
                       columns:@[[PRPlaylists columnTypeForListAttr:attr]]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

#pragma mark - ListItem Setters

- (void)addItem:(PRItem *)item atIndex:(int)index toList:(PRList *)list {
    [self addItems:@[item] atIndex:index toList:list];
}

- (void)addItems:(NSArray *)items atIndex:(int)index toList:(PRList *)list {
    [_db begin];
    [_db execute:@"UPDATE playlist_items "
     "SET playlist_index = playlist_index + ?3 "
     "WHERE playlist_index >= ?1 AND playlist_id = ?2" 
       bindings:@{@1:[NSNumber numberWithInt:index], @2:list, @3:[NSNumber numberWithInt:10000000 + [items count]]}
        columns:nil];
    
    [_db execute:@"UPDATE playlist_items "
     "SET playlist_index = playlist_index - 10000000 "
     "WHERE playlist_index >= ?1 AND playlist_id = ?2" 
       bindings:@{@1:[NSNumber numberWithInt:index], @2:list}
        columns:nil];
    
    for (int i = 0; i < [items count]; i++) {
        [_db execute:@"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) VALUES (?1, ?2, ?3)"
           bindings:@{@1:list, @2:[NSNumber numberWithInt:index + i], @3:[items objectAtIndex:i]}
            columns:nil];
    }
    [_db commit];
}

- (void)appendItem:(PRList *)item toList:(PRList *)list {
    [_db begin];
    [_db execute:@"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) VALUES (?1, ?2, ?3)"
       bindings:@{@1:list, @2:[NSNumber numberWithInt:[self countForList:list] + 1], @3:item}
        columns:nil];
    [_db commit];
}

- (void)appendItems:(NSArray *)items toList:(PRList *)list {
    [_db begin];
    for (PRItem *i in items) {
        [self appendItem:i toList:list];
    }
    [_db commit];
}

- (void)removeItemAtIndex:(int)index fromList:(PRList *)list {
    [_db begin];
    [_db execute:@"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index = ?2"
       bindings:@{@1:list, @2:[NSNumber numberWithInt:index]}
        columns:nil];
    
    [_db execute:@"UPDATE playlist_items SET playlist_index = playlist_index + 10000000 "
     "WHERE playlist_index > ?1 AND playlist_id = ?2"
       bindings:@{@1:[NSNumber numberWithInt:index], @2:list}
        columns:nil];
    
    [_db execute:@"UPDATE playlist_items SET playlist_index = playlist_index - 10000001 "
     "WHERE playlist_index > ?1 AND playlist_id = ?2"
       bindings:@{@1:[NSNumber numberWithInt:index], @2:list}
        columns:nil];
    
    [self propagateListDelete];
    [self propagateListItemDelete];
    [_db commit];
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes fromList:(PRList *)list {
    [_db begin];    
    [_db execute:@"CREATE TEMP TABLE IF NOT EXISTS indexesToRemove (index2 INTEGER PRIMARY KEY)"];
    
    // fill temp table with indexes to remove
    NSInteger index = [indexes firstIndex];
    while (index != NSNotFound) {
        [_db execute:@"INSERT INTO indexesToRemove (index2) VALUES (?1)"
           bindings:@{@1:[NSNumber numberWithInt:index]}
            columns:nil];
        index = [indexes indexGreaterThanIndex:index];
    }
    
    // Delete files at indexes
    [_db execute:@"DELETE FROM playlist_items WHERE playlist_id = ?1 "
     "AND playlist_index IN (SELECT index2 FROM indexesToRemove)"
       bindings:@{@1:list}
        columns:nil];
    
    // Delete temp table
    [_db execute:@"DROP TABLE indexesToRemove"];
    
    // Get array of playlist_item_ids ordered by playlists_index
    NSArray *rlt = [_db execute:@"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index"
                      bindings:@{@1:list}
                       columns:@[PRColInteger]];
    
    // for each playlist_item_id update with new playlist_index
    for (int i = 0; i < [rlt count]; i++) {
        [_db execute:@"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2"
           bindings:@{@1:[NSNumber numberWithInt:i+1], @2:[[rlt objectAtIndex:i] objectAtIndex:0],}
            columns:nil];
    }
    
    [self propagateListItemDelete];
    [_db commit];
}

- (void)clearList:(PRList *)list {
    [_db begin];
    [_db execute:@"DELETE FROM playlist_items WHERE playlist_id = ?1"
       bindings:@{@1:list}
        columns:nil];
    [self propagateListItemDelete];
    [_db commit];
}

- (void)clearList:(PRList *)list exceptIndex:(int)index {
    [_db begin];
    [_db execute:@"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index != ?2"
        bindings:@{@1:list, @2:@(index)}
         columns:nil];
    
    [_db execute:@"UPDATE playlist_items SET playlist_index = 1 WHERE playlist_id = ?1"
        bindings:@{@1:list}
         columns:nil];
    
    [self propagateListItemDelete];
    [_db commit];
}

- (void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(int)index inList:(PRList *)list {
    [_db begin];
    // Get array of playlist_item_ids ordered by playlists_index
    NSArray *playlistItemIDArray = [_db execute:@"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index"
                                      bindings:@{@1:list}
                                       columns:@[PRColInteger]];
    
    // Set playlist_id = -1 for all files
    [_db execute:@"UPDATE playlist_items SET playlist_id = ?1 WHERE playlist_id = ?2"
       bindings:@{@1:[self libraryList], @2:list}
        columns:nil];
    
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
        
        [_db execute:@"UPDATE playlist_items SET playlist_id = ?1, playlist_index = ?2 WHERE playlist_item_id = ?3"
           bindings:@{@1:list, @2:@(newPlaylistIndex), @3:@(playlistItemID)}
            columns:nil];
    }
    [_db commit];
}

- (void)appendItemsFromLibraryViewSourceToList:(PRList *)list {
    [_db begin];
    // create temp table
    [_db execute:[NSString stringWithFormat:@"CREATE TEMP TABLE temp_table "
                 "(playlist_index INTEGER PRIMARY KEY, "
                 "file_id INTEGER, "
                 "playlist_id INTEGER DEFAULT %d)", [list intValue]]];
    
    // insert temp value into temp table to increase the integer primary key
    [_db execute:@"INSERT INTO temp_table (playlist_index, playlist_id) VALUES (?1, -1)"
       bindings:@{@1:[NSNumber numberWithInt:[self countForList:list]]}
        columns:nil];
    
    // add files from libraryViewSource to temp table
    [_db execute:@"INSERT INTO temp_table (file_id) SELECT file_id FROM libraryViewSource ORDER BY row"];
    
    // copy files from temp table to playlist
    [_db execute:@"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
     "SELECT playlist_id, playlist_index, file_id FROM temp_table WHERE playlist_id != -1"];
    
    // Drop temp table
    [_db execute:@"DROP TABLE temp_table"];
    [_db commit];
}

- (void)copyItemsFromList:(PRList *)list toList:(PRList *)list2 {
    [_db begin];
    [self clearList:list2];
    [_db execute:@"INSERT INTO playlist_items (file_id, playlist_id, playlist_index) "
     "SELECT file_id, ?1, playlist_index FROM playlist_items WHERE playlist_id = ?2;"
       bindings:@{@1:list2, @2:list}
        columns:nil];
    [_db commit];
}

#pragma mark - ListItem Getters 

- (int)countForList:(PRList *)list {
    NSArray *rlt = [_db execute:@"SELECT COUNT(*) FROM playlist_items WHERE playlist_id = ?1"
                      bindings:@{@1:list}
                       columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRListItem *)listItemAtIndex:(int)index inList:(PRList *)list {
    NSArray *rlt = [_db execute:@"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 AND playlist_index = ?2"
                      bindings:@{@1:list, @2:[NSNumber numberWithInt:index]}
                       columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (PRItem *)itemAtIndex:(int)index forList:(PRList *)list {
    NSArray *rlt = [_db execute:@"SELECT file_id FROM playlist_items WHERE playlist_id = ? AND playlist_index = ?"
                      bindings:@{@1:list, @2:[NSNumber numberWithInt:index]}
                       columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (PRItem *)itemForListItem:(PRListItem *)listItem {
    NSArray *rlt = [_db execute:@"SELECT file_id FROM playlist_items WHERE playlist_item_id = ?1"
                      bindings:@{@1:listItem}
                       columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (int)indexForListItem:(PRListItem *)listItem {
    NSArray *results = [_db execute:@"SELECT playlist_index FROM playlist_items WHERE playlist_item_id = ?1"
                          bindings:@{@1:listItem}
                           columns:@[PRColInteger]];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRList *)listForListItem:(PRListItem *)listItem {
    NSArray *results = [_db execute:@"SELECT playlist_id FROM playlist_items WHERE playlist_item_id = ?1"
                          bindings:@{@1:listItem}
                           columns:@[PRColInteger]];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[results objectAtIndex:0] objectAtIndex:0];
}

- (BOOL)list:(PRList *)list containsItem:(PRItem *)item {
    NSArray *result = [_db execute:@"SELECT file_id FROM playlist_items WHERE file_id = ?1 AND playlist_id = ?2 LIMIT 1"
                         bindings:@{@1:item, @2:list}
                          columns:@[PRColInteger]];
    return [result count] > 0;
}

- (NSIndexSet *)indexesOfItem:(PRItem *)item inList:(PRList *)list {
    NSArray *results = [_db execute:@"SELECT playlist_index FROM playlist_items WHERE file_id = ?2 AND playlist_id = ?1"
                          bindings:@{@1:list, @2:item}
                           columns: @[PRColInteger]];
    NSMutableIndexSet *mutableIndexes= [[NSMutableIndexSet alloc] init];
    for (NSArray *i in results) {
        [mutableIndexes addIndex:[[i objectAtIndex:0] intValue]];
    }
    return mutableIndexes;
} 

#pragma mark - ListItem Getters Misc

- (NSArray *)playlistsViewSource {
    NSString *string = @"SELECT playlist_id, type, title FROM playlists "
    "WHERE type IN (2,3) ORDER BY type, title COLLATE NOCASE2, playlist_id ";
    NSArray *results = [_db execute:string
                          bindings:nil
                           columns:@[PRColInteger, PRColInteger, PRColString]];
    NSMutableArray *playlists = [NSMutableArray array];
    for (NSArray *i in results) {
        [playlists addObject:@{@"playlist":[i objectAtIndex:0], @"type":[i objectAtIndex:1],@"title":[i objectAtIndex:2]}];
    }
    return playlists;
}

#pragma mark - Update

- (BOOL)propagateListDelete {
    return [self propagateListItemDelete];
}

- (BOOL)propagateListItemDelete {
    return [[_db playbackOrder] clean];
}

// ========================================

- (NSMutableDictionary *)browserInfoForList:(PRList *)list {
    NSData *data = [self valueForList:list attr:PRListAttrBrowserInfo];
    NSDictionary *info = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:nil errorDescription:nil];
    if (!info || ![info isKindOfClass:[NSDictionary class]] ||
        ([info objectForKey:@"isVertical"] && ![[info objectForKey:@"isVertical"] isKindOfClass:[NSNumber class]]) ||
        ([info objectForKey:@"verticalBrowser3Width"] && ![[info objectForKey:@"verticalBrowser3Width"] isKindOfClass:[NSNumber class]]) ||
        ([info objectForKey:@"horizontalBrowserHeight"] && ![[info objectForKey:@"horizontalBrowserHeight"] isKindOfClass:[NSNumber class]])) {
        return [NSMutableDictionary dictionary];
    }
    return [NSMutableDictionary dictionaryWithDictionary:info];
}

- (void)setBrowserInfo:(NSMutableDictionary *)info forList:(PRList *)list {
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:info format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    [self setValue:data forList:list attr:PRListAttrBrowserInfo];
}

- (int)verticalForList:(PRList *)list {
    NSNumber *isVertical = [[self browserInfoForList:list] objectForKey:@"isVertical"];
    if (isVertical) {
        return [isVertical intValue];
    }
    if ([list isEqual:[self libraryList]]) {
        return PRBrowserPositionHorizontal;
    } else {
        return PRBrowserPositionHidden;
    }
}

- (void)setVertical:(int)vertical forList:(PRList *)list {
    NSMutableDictionary *info = [self browserInfoForList:list];
    [info setObject:[NSNumber numberWithInt:vertical] forKey:@"isVertical"];
    [self setBrowserInfo:info forList:list];
}

- (float)verticalBrowserWidthForList:(PRList *)list {
    NSNumber *width = [[self browserInfoForList:list] objectForKey:@"verticalBrowser3Width"];
    if (width) {
        return [width floatValue];
    } 
    return 200;
}

- (void)setVerticalBrowserWidth:(float)width forList:(PRList *)list {
    NSMutableDictionary *info = [self browserInfoForList:list];
    [info setObject:[NSNumber numberWithFloat:width] forKey:@"verticalBrowser3Width"];
    [self setBrowserInfo:info forList:list];
}

- (float)horizontalBrowserHeightForList:(PRList *)list {
    NSNumber *height = [[self browserInfoForList:list] objectForKey:@"horizontalBrowserHeight"];
    if (height) {
        return [height floatValue];
    }
    return 250;
}

- (void)setHorizontalBrowserHeight:(float)height forList:(PRList *)list {
    NSMutableDictionary *info = [self browserInfoForList:list];
    [info setObject:[NSNumber numberWithFloat:height] forKey:@"horizontalBrowserHeight"];
    [self setBrowserInfo:info forList:list];
}

- (BOOL)listViewAscendingForList:(PRList *)list {
    return [[self valueForList:list attr:PRListAttrListViewAscending] boolValue];
}

- (void)setListViewAscending:(BOOL)ascending forList:(PRList *)list {
    [self setValue:[NSNumber numberWithBool:ascending] forList:list attr:PRListAttrListViewAscending];
}

- (BOOL)albumListViewAscendingForList:(PRList *)list {
    return [[self valueForList:list attr:PRListAttrAlbumListViewAscending] boolValue];
}

- (void)setAlbumListViewAscending:(BOOL)ascending forList:(PRList *)list {
    [self setValue:[NSNumber numberWithBool:ascending] forList:list attr:PRListAttrAlbumListViewAscending];
}

- (PRItemAttr *)listViewSortAttrForList:(PRList *)list {
    return [PRPlaylists sortAttrForInternal:[self valueForList:list attr:PRListAttrListViewSortAttr]];
}

- (void)setListViewSortAttr:(PRItemAttr *)attr forList:(PRList *)list {
    [self setValue:[PRPlaylists internalForSortAttr:attr] forList:list attr:PRListAttrListViewSortAttr];
}

- (PRItemAttr *)albumListViewSortAttrForList:(PRList *)list {
    return [PRPlaylists sortAttrForInternal:[self valueForList:list attr:PRListAttrAlbumListViewSortAttr]];
}

- (void)setAlbumListViewSortAttr:(PRItemAttr *)attr forList:(PRList *)list {
    [self setValue:[PRPlaylists internalForSortAttr:attr] forList:list attr:PRListAttrAlbumListViewSortAttr];
}

- (NSArray *)listViewInfoForList:(PRList *)list {
    NSData *columnInfoData = [self valueForList:list attr:PRListAttrListViewInfo];
    if ([columnInfoData isEqualToData:[NSData data]]) {
        NSString *defaultData  = [[NSBundle mainBundle] pathForResource:@"PRListViewTableColumnsInfo" ofType:@"plist"];
        columnInfoData = [NSData dataWithContentsOfFile:defaultData];
    }
    return [NSPropertyListSerialization propertyListFromData:columnInfoData mutabilityOption:0 format:nil errorDescription:nil];
}

- (void)setListViewInfo:(NSArray *)info forList:(PRList *)list {
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:info format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    [self setValue:data forList:list attr:PRListAttrListViewInfo];
}

- (NSArray *)albumListViewInfoForList:(PRList *)list {
    NSData *columnInfoData = [self valueForList:list attr:PRListAttrAlbumListViewInfo];
    if ([columnInfoData isEqualToData:[NSData data]]) {
        NSString *defaultData  = [[NSBundle mainBundle] pathForResource:@"PRAlbumListViewTableColumnsInfo" ofType:@"plist"];
        columnInfoData = [NSData dataWithContentsOfFile:defaultData];
    }
    return [NSPropertyListSerialization propertyListFromData:columnInfoData mutabilityOption:0 format:nil errorDescription:nil];
}

- (void)setAlbumListViewInfo:(NSArray *)info forList:(PRList *)list {
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:info format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    [self setValue:data forList:list attr:PRListAttrAlbumListViewInfo];
}

- (NSArray *)selectionForBrowser:(int)browser list:(PRList *)list {
    PRListAttr *attr;
    if (browser == 1) {
        attr = PRListAttrBrowser1Selection;
    } else if (browser == 2) {
        attr = PRListAttrBrowser2Selection;
    } else if (browser == 3) {
        attr = PRListAttrBrowser3Selection;
    } else {
        @throw NSInvalidArgumentException;
    }
    NSData *data = [self valueForList:list attr:attr];
    if ([data length] == 0) {
        return @[];
    }
    @try {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } @catch (NSException *exception) {
        return @[];
    }
}

- (void)setSelection:(NSArray *)selection forBrowser:(int)browser list:(PRList *)list {
    PRListAttr *attr;
    if (browser == 1) {
        attr = PRListAttrBrowser1Selection;
    } else if (browser == 2) {
        attr = PRListAttrBrowser2Selection;
    } else if (browser == 3) {
        attr = PRListAttrBrowser3Selection;
    } else {
        @throw NSInvalidArgumentException;
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selection];
    [self setValue:data forList:list attr:attr];
}

- (PRItemAttr *)attrForBrowser:(int)browser list:(PRList *)list {
    PRListAttr *attr;
    if (browser == 1) {
        attr = PRListAttrBrowser1Attr;
    } else if (browser == 2) {
        attr = PRListAttrBrowser2Attr;
    } else if (browser == 3) {
        attr = PRListAttrBrowser3Attr;
    } else {
        @throw NSInvalidArgumentException;
    }
    return [PRLibrary itemAttrForInternal:[self valueForList:list attr:attr]];
}

- (void)setAttr:(PRItemAttr *)attr forBrowser:(int)browser list:(PRList *)list {
    PRListAttr *listAttr;
    if (browser == 1) {
        listAttr = PRListAttrBrowser1Attr;
    } else if (browser == 2) {
        listAttr = PRListAttrBrowser2Attr;
    } else if (browser == 3) {
        listAttr = PRListAttrBrowser3Attr;
    } else {
        @throw NSInvalidArgumentException;
    }
    [self setValue:[PRLibrary internalForItemAttr:attr] forList:list attr:listAttr];
}

- (PRListType *)typeForList:(PRList *)list {
    return [PRPlaylists listTypeForInternal:[self valueForList:list attr:PRListAttrType]];
}

- (void)setType:(PRListType *)type forList:(PRList *)list {
    [self setValue:[PRPlaylists internalForListType:type] forList:list attr:PRListAttrType];
}

- (NSString *)titleForList:(PRList *)list {
    return [self valueForList:list attr:PRListAttrTitle];
}

- (void)setTitle:(NSString *)title forList:(PRList *)list {
    [self setValue:title forList:list attr:PRListAttrTitle];
}

- (NSString *)searchForList:(PRList *)list {
    return [self valueForList:list attr:PRListAttrSearch];
}

- (void)setSearch:(NSString *)search forList:(PRList *)list {
    [self setValue:search forList:list attr:PRListAttrSearch];
}

- (int)viewModeForList:(PRList *)list {
    return [[self valueForList:list attr:PRListAttrViewMode] intValue];
}

- (void)setViewMode:(int)viewMode forList:(PRList *)list {
    [self setValue:[NSNumber numberWithInt:viewMode] forList:list attr:PRListAttrViewMode];
}

- (NSDictionary *)ruleForList:(PRList *)list {
    return nil;
}

- (void)setRule:(NSDictionary *)rule forList:(PRList *)list {

}

@end
