#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRPlaybackOrder.h"
#import "NSArray+Extensions.h"
#import "PRListDescription.h"
#import "PRLibraryDescription.h"


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
    __weak PRConnection *_conn;
}

#pragma mark - Initialization

- (instancetype)initWithConnection:(PRConnection *)connection {
    if ((self = [super init])) {
        _conn = connection;
    }
    return self;
}

- (id)initWithDb:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _db = db;
    return self;
}

- (void)create {
    [(PRDb*)(_db?:(id)_conn) zExecute:PR_TBL_PLAYLISTS_SQL];
    [(PRDb*)(_db?:(id)_conn) zExecute:PR_TBL_PLAYLIST_ITEMS_SQL];
    [(PRDb*)(_db?:(id)_conn) zExecute:PR_IDX_PLAYLIST_ITEMS_SQL];
}

- (BOOL)initialize {
    NSArray *rlt = nil;
    [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT sql FROM sqlite_master WHERE name = 'playlists'" bindings:nil columns:@[PRColString] out:&rlt];
    if ([rlt count] != 1 || ![rlt[0][0] isEqualToString:PR_TBL_PLAYLISTS_SQL]) {
        return NO;
    }
    
    [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT sql FROM sqlite_master WHERE name = 'playlist_items'" bindings:nil columns:@[PRColString] out:&rlt];
    if ([rlt count] != 1 || ![rlt[0][0] isEqualToString:PR_TBL_PLAYLIST_ITEMS_SQL]) {
        return NO;
    }
    
    [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT sql FROM sqlite_master WHERE name = 'index_playlistItems'" bindings:nil columns:@[PRColString] out:&rlt];
    if ([rlt count] != 1 || ![rlt[0][0] isEqualToString:PR_IDX_PLAYLIST_ITEMS_SQL]) {
        return NO;
    }
    
    // Create library if it doesnt exist
    [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT playlist_id FROM playlists WHERE type=0" bindings:nil columns:@[PRColInteger] out:&rlt];
    if ([rlt count] != 1) {
        PRList *list = [self addList];
        [self setTitle:@"Music" forList:list];
        [self setType:PRListTypeLibrary forList:list];
        [self setAttr:PRItemAttrGenre forBrowser:1 list:list];
        [self setAttr:PRItemAttrArtist forBrowser:2 list:list];
        [self setAttr:PRItemAttrAlbum forBrowser:3 list:list];
    }
    
    // Create now playing playlist if it doesnt exist
    [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT playlist_id FROM playlists WHERE type=1" bindings:nil columns:@[PRColInteger] out:&rlt];
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
    NSString *stm = @"DELETE FROM playlist_items WHERE playlist_id IN "
        "(SELECT playlist_id FROM playlists WHERE type != ?1 || type != ?2)";
    [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:@(PRStaticPlaylistType), @2:@(PRNowPlayingPlaylistType)} columns:nil out:nil];
    
    // Make sure that there are no gaps in playlist_index
    NSArray *lists = [self lists];
    for (NSNumber *i in lists) {
        PRListType *type = [self typeForList:i];
        int count = [self countForList:i];
        if (!([type isEqual:PRListTypeStatic] || [type isEqual:PRListTypeNowPlaying]) || count == 0) {
            continue;
        }
        
        // get max and min values for playlist_index
        stm = @"SELECT max(playlist_index), min(playlist_index) FROM playlist_items WHERE playlist_id = ?1";
        NSArray *rlt = nil;
        [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:i} columns:@[PRColInteger, PRColInteger] out:&rlt];
        if ([rlt count] != 1) {
            [PRException raise:PRDbInconsistencyException format:@""];
        }
        int max = [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
        int min = [[[rlt objectAtIndex:0] objectAtIndex:1] intValue];
        
        // if max and min are invalid, update playlist_indexes of playlist_items
        if (min != 1 || max != count) {
            [(PRDb*)(_db?:(id)_conn) zTransaction:^{
                NSArray *playlistItems = nil;
                NSString *stm = @"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = :playlist ORDER BY playlist_index";
                [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:i} columns:@[PRColInteger] out:&playlistItems];
                
                for (int i = 0; i < [playlistItems count]; i++) {
                    stm = @"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2";
                    [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:@(i + 1), @2:playlistItems[i][0]} columns:nil out:nil];
                }
                return YES;
            }];
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
    NSArray *rlt = nil;
    [self zLists:&rlt];
    return rlt;
}

- (PRList *)libraryList {
    PRList *rlt = nil;
    [self zLibraryList:&rlt];
    return rlt;
}

- (PRList *)nowPlayingList {
    PRList *rlt = nil;
    [self zNowPlayingList:&rlt];
    return rlt;
}

- (PRList *)addList {
    PRList *rlt;
    [self zAddList:&rlt];
    return rlt;
}

- (PRList *)addStaticList {
    PRList *rlt;
    [self zAddStaticList:&rlt];
    return rlt;
}

- (PRList *)addSmartList {
    PRList *rlt;
    [self zAddSmartList:&rlt];
    return rlt;
}

- (void)removeList:(PRList *)list {
    [self zRemoveList:list];
}

- (void)setValue:(id)value forList:(PRList *)list attr:(PRListAttr *)attr {
    [self zSetValue:value forList:list attr:attr];
}

- (id)valueForList:(PRList *)list attr:(PRListAttr *)attr {
    id rlt = nil;
    [self zValueForList:list attr:attr out:&rlt];
    return rlt;
}

#pragma mark - zList Getters

- (BOOL)zLists:(NSArray **)outValue {
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT playlist_id FROM playlists ORDER BY type, title COLLATE NOCASE, playlist_id" bindings:nil columns:@[PRColInteger] out:&rlt];
    if (success && outValue) {
        *outValue = [rlt PRMap:^(NSInteger idx, id obj){return obj[0];}];
    }
    return success;
}

- (BOOL)zLibraryList:(PRList **)outValue {
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT playlist_id FROM playlists WHERE type = ?1" bindings:@{@1:@(PRLibraryPlaylistType)} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = rlt[0][0];
    }
    return YES;
}

- (BOOL)zNowPlayingList:(PRList **)outValue {
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT playlist_id FROM playlists WHERE type = ?1" bindings:@{@1:@(PRNowPlayingPlaylistType)} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = rlt[0][0];
    }
    return YES;
}

- (BOOL)zValueForList:(PRList *)list attr:(PRListAttr *)attr out:(id *)outValue {
    PRListDescription *listDescription = nil;
    BOOL success = [self zListDescriptionForList:list out:&listDescription];
    if (!success) {
        return NO;
    }
    if (outValue) {
        *outValue = [listDescription valueForAttr:attr];
    }
    return YES;
}

- (BOOL)zListDescriptionForList:(PRList *)list out:(PRListDescription **)outValue {
    if (outValue) {
        *outValue = [[PRListDescription alloc] initWithList:list connection:(PRConnection*)(_db?:(id)_conn)];
    }
    return *outValue != nil;
}

- (BOOL)zAllListDescriptions:(NSArray **)outValue {
    NSArray *lists = nil;
    BOOL success = [self zLists:&lists];
    if (!success) {
        return NO;
    }
    
    NSMutableArray *listDescriptions = [NSMutableArray array];
    for (PRList *i in lists) {
        PRListDescription *description = nil;
        success = [self zListDescriptionForList:i out:&description];
        if (!success) {
            return NO;
        }
        [listDescriptions addObject:description];
    }
    if (outValue) {
        *outValue = listDescriptions;
    }
    return YES;
}

- (BOOL)zLibraryDescriptionForList:(PRList *)list out:(PRLibraryDescription **)outValue {
    if (outValue) {
        *outValue = [[PRLibraryDescription alloc] initWithList:list connection:(PRConnection*)(_db?:(id)_conn)];
    }
    return *outValue != nil;
}

- (BOOL)zBrowserDescriptionsForList:(PRList *)list out:(NSArray **)outValue {
    if (outValue) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < 3; i++) {
            PRBrowserDescription *val = [[PRBrowserDescription alloc] initWithList:list browser:i connection:(PRConnection*)(_db?:(id)_conn)];
            if (!val) {
                return NO;
            }
            [array addObject:val];
        }
        *outValue = array;
    }
    return YES;
}

#pragma mark - zList Setters

- (BOOL)zAddList:(PRList **)outValue {
    __block NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"INSERT INTO playlists DEFAULT VALUES"];
        if (!success2) {
            return NO;
        }
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT MAX(playlist_id) FROM playlists" bindings:nil columns:@[PRColInteger] out:&rlt];
        if (!success2 || [rlt count] != 1) {
            return NO;
        }
        return YES;
    }];
    if (success && outValue) {
        *outValue = rlt[0][0];
    }
    return success;
}

- (BOOL)zAddStaticList:(PRList **)outValue {
    __block PRList *list = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        BOOL success2 = [self zAddList:&list];
        if (!success2) {
            return NO;
        }
        [self setTitle:@"Untitled Playlist" forList:list];
        [self setType:PRListTypeStatic forList:list];
        [self setListViewSortAttr:PRListSortIndex forList:list];
        return success2;
    }];
    if (success && outValue) {
        *outValue = list;
    }
    return success;
}

- (BOOL)zAddSmartList:(PRList **)outValue {
    __block PRList *list = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        BOOL success2 = [self zAddList:&list];
        if (!success2) {
            return NO;
        }
        [self setTitle:@"Untitled Smart Playlist" forList:list];
        [self setType:PRListTypeSmart forList:list];
        [self setListViewSortAttr:PRListSortIndex forList:list];
        return success2;
    }];
    if (success && outValue) {
        *outValue = list;
    }
    return success;
}

- (BOOL)zRemoveList:(PRList *)list {
    return [(PRDb*)(_db?:(id)_conn) zExecute:@"DELETE FROM playlists WHERE playlist_id = ?1" bindings:@{@1:list} columns:nil out:nil];
}

- (BOOL)zSetValue:(id)value forList:(PRList *)list attr:(PRListAttr *)attr {
    PRListDescription *listDescription = nil;
    BOOL success = [self zListDescriptionForList:list out:&listDescription];
    if (!success) {
        return NO;
    }
    [listDescription setValue:value forAttr:attr];
    return [listDescription writeToConnection:(PRConnection*)(_db?:(id)_conn)];
}

- (BOOL)zSetListDescription:(PRListDescription *)value forList:(PRList *)list {
    return [value writeToConnection:(PRConnection*)(_db?:(id)_conn)];
}

#pragma mark - ListItem Setters

- (void)addItems:(NSArray *)items atIndex:(int)index toList:(PRList *)list {
    [self zAddItems:items atIndex:index toList:list];
}

- (void)appendItem:(PRList *)item toList:(PRList *)list {
    [self zAppendItem:item toList:list];
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes fromList:(PRList *)list {
    [self zRemoveItemsAtIndexes:indexes fromList:list];
}

- (void)clearList:(PRList *)list {
    [self zClearList:list];
}

- (void)clearList:(PRList *)list exceptIndex:(int)index {
    [self zClearList:list exceptIndex:index];
}

- (void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(int)index inList:(PRList *)list {
    [self zMoveItemsAtIndexes:indexes toIndex:index inList:list];
}

- (void)appendItemsFromLibraryViewSourceToList:(PRList *)list {
    [self zAppendItemsFromLibraryViewSourceToList:list];
}

- (void)copyItemsFromList:(PRList *)list toList:(PRList *)list2 {
    [self zCopyItemsFromList:list toList:list2];
}

#pragma mark - ListItem Setters

- (BOOL)zAddItems:(NSArray *)items atIndex:(int)index toList:(PRList *)list {
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        NSString *stm = @"UPDATE playlist_items SET playlist_index = playlist_index + ?3 WHERE playlist_index >= ?1 AND playlist_id = ?2";
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:@(index), @2:list, @3:@(10000000 + [items count])} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        stm = @"UPDATE playlist_items SET playlist_index = playlist_index - 10000000 WHERE playlist_index >= ?1 AND playlist_id = ?2";
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:@(index), @2:list} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        for (int i = 0; i < [items count]; i++) {
            stm = @"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) VALUES (?1, ?2, ?3)";
            success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:@(index + i), @3:[items objectAtIndex:i]} columns:nil out:nil];
            if (!success2) {
                return NO;
            }
        }
        return YES;
    }];
    return success;
}

- (BOOL)zAppendItem:(PRList *)item toList:(PRList *)list {
    NSInteger count = 0;
    BOOL success = [self zCountForList:list out:&count];
    if (!success) {
        return NO;
    }
    NSString *stm = @"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) VALUES (?1, ?2, ?3)";
    success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:@(count + 1), @3:item} columns:nil out:nil];
    return success;
}

- (BOOL)zRemoveItemsAtIndexes:(NSIndexSet *)indexes fromList:(PRList *)list {
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"CREATE TEMP TABLE indexesToRemove (index2 INTEGER PRIMARY KEY)"];
        if (!success2) {
            return NO;
        }
        
        // fill temp table with indexes to remove
        NSInteger index = [indexes firstIndex];
        while (index != NSNotFound) {
            success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"INSERT INTO indexesToRemove (index2) VALUES (?1)" bindings:@{@1:@(index)} columns:nil out:nil];
            if (!success2) {
                return NO;
            }
            index = [indexes indexGreaterThanIndex:index];
        }
        
        // Delete files at indexes
        NSString *stm = @"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index IN (SELECT index2 FROM indexesToRemove)";
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        
        // Delete temp table
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"DROP TABLE indexesToRemove"];
        if (!success2) {
            return NO;
        }
        
        // Get array of playlist_item_ids ordered by playlists_index
        stm = @"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index";
        NSArray *rlt = nil;
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list} columns:@[PRColInteger] out:&rlt];
        if (!success2) {
            return NO;
        }
        
        // for each playlist_item_id update with new playlist_index
        for (int i = 0; i < [rlt count]; i++) {
            stm = @"UPDATE playlist_items SET playlist_index = ?1 WHERE playlist_item_id = ?2";
            success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:@(i+1), @2:rlt[i][0]} columns:nil out:nil];
            if (!success2) {
                return NO;
            }
        }
        [self propagateListItemDelete];
        return YES;
    }];
    return success;
}

- (BOOL)zClearList:(PRList *)list {
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"DELETE FROM playlist_items WHERE playlist_id = ?1" bindings:@{@1:list} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        [self propagateListItemDelete];
        return success2;
    }];
    return success;
}

- (BOOL)zClearList:(PRList *)list exceptIndex:(NSInteger)index {
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        NSString *stm = @"DELETE FROM playlist_items WHERE playlist_id = ?1 AND playlist_index != ?2";
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:@(index)} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        stm = @"UPDATE playlist_items SET playlist_index = 1 WHERE playlist_id = ?1";
        [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        [self propagateListItemDelete];
        return success2;
    }];
    return success;
}

- (BOOL)zMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)index inList:(PRList *)list {
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        // Get array of playlist_item_ids ordered by playlists_index
        NSString *stm = @"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index";
        NSArray *playlistItemIDArray = nil;
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list} columns:@[PRColInteger] out:&playlistItemIDArray];
        
        // Set playlist_id = -1 for all files
        stm = @"UPDATE playlist_items SET playlist_id = ?1 WHERE playlist_id = ?2";
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:[self libraryList], @2:list} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        
        // Update each playlistItemID with new playlistIndex
        NSInteger newPlaylistIndex;
        NSInteger newIndex = index - [indexes countOfIndexesInRange:NSMakeRange(1, index - 1)];
        NSInteger count = 1;
        NSInteger count2 = newIndex;
        
        for (NSInteger i = 0; i < [playlistItemIDArray count]; i++) {
            NSInteger playlistItemID = [playlistItemIDArray[i][0] integerValue];
            if (count == newIndex) {
                count = newIndex + [indexes count];
            }
            if ([indexes containsIndex:i+1]) {
                newPlaylistIndex = count2++;
            } else {
                newPlaylistIndex = count++;
            }
            
            stm = @"UPDATE playlist_items SET playlist_id = ?1, playlist_index = ?2 WHERE playlist_item_id = ?3";
            success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:@(newPlaylistIndex), @3:@(playlistItemID)} columns:nil out:nil];
            if (!success2) {
                return NO;
            }
        }
        return YES;
    }];
    return success;
}

- (BOOL)zAppendItemsFromLibraryViewSourceToList:(PRList *)list {
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        // create temp table
        NSString *stm = [NSString stringWithFormat:@"CREATE TEMP TABLE temp_table (playlist_index INTEGER PRIMARY KEY, "
        "file_id INTEGER, playlist_id INTEGER DEFAULT %ld)", (long)[list integerValue]];
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm];
        if (!success2) {
            return NO;
        }
        
        // insert temp value into temp table to increase the integer primary key
        stm = @"INSERT INTO temp_table (playlist_index, playlist_id) VALUES (?1, -1)";
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:@([self countForList:list])} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        
        // add files from libraryViewSource to temp table
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"INSERT INTO temp_table (file_id) SELECT file_id FROM libraryViewSource ORDER BY row"];
        if (!success2) {
            return NO;
        }
        
        // copy files from temp table to playlist
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) "
            "SELECT playlist_id, playlist_index, file_id FROM temp_table WHERE playlist_id != -1"];
        if (!success2) {
            return NO;
        }
        
        // Drop temp table
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"DROP TABLE temp_table"];
        if (!success2) {
            return NO;
        }
        return YES;
    }];
    return success;
}

- (BOOL)zCopyItemsFromList:(PRList *)list toList:(PRList *)list2 {
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        BOOL success2 = [self zClearList:list2];
        if (!success2) {
            return NO;
        }
        NSString *stm = @"INSERT INTO playlist_items (file_id, playlist_id, playlist_index) SELECT file_id, ?1, playlist_index FROM playlist_items WHERE playlist_id = ?2;";
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list2, @2:list} columns:nil out:nil];
        if (!success2) {
            return NO;
        }
        return YES;
    }];
    return success;
}

#pragma mark - ListItem Getters 

- (int)countForList:(PRList *)list {
    NSInteger rlt = 0;
    [self zCountForList:list out:&rlt];
    return rlt;
}

- (PRListItem *)listItemAtIndex:(int)index inList:(PRList *)list {
    PRListItem *rlt;
    [self zListItemAtIndex:index inList:list out:&rlt];
    return rlt;
}

- (PRItem *)itemAtIndex:(int)index forList:(PRList *)list {
    PRItem *rlt;
    [self zItemAtIndex:index forList:list out:&rlt];
    return rlt;
}

- (PRItem *)itemForListItem:(PRListItem *)listItem {
    PRItem *rlt;
    [self zItemForListItem:listItem out:&rlt];
    return rlt;
}

- (int)indexForListItem:(PRListItem *)listItem {
    NSInteger rlt = 0;
    [self zIndexForListItem:listItem out:&rlt];
    return rlt;
}

- (PRList *)listForListItem:(PRListItem *)listItem {
    PRList *rlt;
    [self zListForListItem:listItem out:&rlt];
    return rlt;
}

- (BOOL)list:(PRList *)list containsItem:(PRItem *)item {
    BOOL rlt;
    [self zList:list containsItem:item out:&rlt];
    return rlt;
}

- (NSIndexSet *)indexesOfItem:(PRItem *)item inList:(PRList *)list {
    NSIndexSet *rlt;
    [self zIndexesOfItem:item inList:list out:&rlt];
    return rlt;
} 

#pragma mark - zListItem Getters

- (BOOL)zCountForList:(PRList *)list out:(NSInteger *)outValue {
    NSString *stm = @"SELECT COUNT(*) FROM playlist_items WHERE playlist_id = ?1";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = [rlt[0][0] integerValue];
    }
    return YES;
}

- (BOOL)zListItemAtIndex:(int)index inList:(PRList *)list out:(PRListItem **)outValue {
    NSString *stm = @"SELECT playlist_item_id FROM playlist_items WHERE playlist_id = ?1 AND playlist_index = ?2";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:@(index)} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = rlt[0][0];
    }
    return YES;
}

- (BOOL)zItemAtIndex:(int)index forList:(PRList *)list out:(PRItem **)outValue {
    NSString *stm = @"SELECT file_id FROM playlist_items WHERE playlist_id = ? AND playlist_index = ?";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:@(index)} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = rlt[0][0];
    }
    return YES;
}

- (BOOL)zItemForListItem:(PRListItem *)listItem out:(PRItem **)outValue {
    NSString *stm = @"SELECT file_id FROM playlist_items WHERE playlist_item_id = ?1";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:listItem} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = rlt[0][0];
    }
    return YES;
}

- (BOOL)zIndexForListItem:(PRListItem *)listItem out:(NSInteger *)outValue {
    NSString *stm = @"SELECT playlist_index FROM playlist_items WHERE playlist_item_id = ?1";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:listItem} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = [rlt[0][0] integerValue];
    }
    return YES;
}

- (BOOL)zListForListItem:(PRListItem *)listItem out:(PRList **)outValue {
    NSString *stm = @"SELECT playlist_id FROM playlist_items WHERE playlist_item_id = ?1";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:listItem} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = rlt[0][0];
    }
    return YES;
}

- (BOOL)zList:(PRList *)list containsItem:(PRItem *)item out:(BOOL *)outValue {
    NSString *stm = @"SELECT file_id FROM playlist_items WHERE file_id = ?1 AND playlist_id = ?2 LIMIT 1";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:item, @2:list} columns:@[PRColInteger] out:&rlt];
    if (!success) {
        return NO;
    }
    if (outValue) {
        *outValue = [rlt count] > 0;
    }
    return YES;
}

- (BOOL)zIndexesOfItem:(PRItem *)item inList:(PRList *)list out:(NSIndexSet **)outValue {
    NSString *stm = @"SELECT playlist_index FROM playlist_items WHERE file_id = ?2 AND playlist_id = ?1";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:item} columns: @[PRColInteger] out:&rlt];
    if (!success) {
        return NO;
    }
    NSMutableIndexSet *indexes= [[NSMutableIndexSet alloc] init];
    for (NSArray *i in rlt) {
        [indexes addIndex:[i[0] integerValue]];
    }
    if (outValue) {
        *outValue = indexes;
    }
    return YES;
}

#pragma mark - ListItem Getters Misc

- (NSArray *)playlistsViewSource {
    NSArray *rlt = nil;
    [self zPlaylistsViewSource:&rlt];
    return rlt;
}

#pragma mark - zListItem Getters Misc

- (BOOL)zPlaylistsViewSource:(NSArray **)outValue {
    NSString *stm = @"SELECT playlist_id, type, title FROM playlists WHERE type IN (2,3) ORDER BY type, title COLLATE NOCASE2, playlist_id ";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:nil columns:@[PRColInteger, PRColInteger, PRColString] out:&rlt];
    if (!success) {
        return NO;
    }
    if (outValue) {
        *outValue = [rlt PRMap:^(NSInteger idx, NSArray *obj){
            return @{@"playlist":obj[0], @"type":obj[1],@"title":obj[2]};
        }];
    }
    return YES;
}

#pragma mark - Update

- (BOOL)propagateListDelete {
    return [self propagateListItemDelete];
}

- (BOOL)propagateListItemDelete {
    return [[(PRDb*)(_db?:(id)_conn) playbackOrder] clean];
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
