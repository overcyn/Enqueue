#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRPlaybackOrder.h"
#import "NSArray+Extensions.h"
#import "PRList.h"
#import "PRLibraryDescription.h"
#import "PRException.h"

typedef NS_ENUM(NSInteger, PRPlaylistType) {
    PRLibraryPlaylistType = 0,
    PRNowPlayingPlaylistType = 1,
    PRStaticPlaylistType = 2,
    PRSmartPlaylistType = 3,
};

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
        PRList *list = nil;
        [self zAddList:&list];
        [list setTitle:@"Music"];
        [list setType:PRListTypeLibrary];
        [list setBrowserAttributes:@[PRItemAttrGenre, PRItemAttrArtist, PRItemAttrAlbum]];
        [self zSetListDescription:list forList:[list listID]];
    }
    
    // Create now playing playlist if it doesnt exist
    [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT playlist_id FROM playlists WHERE type=1" bindings:nil columns:@[PRColInteger] out:&rlt];
    if ([rlt count] != 1) {
        PRList *list = nil;
        [self zAddList:&list];
        [list setTitle:@"Now Playing"];
        [list setType:PRListTypeNowPlaying];
        [self zSetListDescription:list forList:[list listID]];
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
    NSArray *lists = nil;
    [self zLists:&lists];
    for (PRList *list in lists) {
        PRListID *i = [list listID];
        PRListType *type = [list type];
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

- (PRListID *)libraryList {
    PRListID *rlt = nil;
    [self zLibraryList:&rlt];
    return rlt;
}

- (PRListID *)nowPlayingList {
    PRListID *rlt = nil;
    [self zNowPlayingList:&rlt];
    return rlt;
}

- (void)setValue:(id)value forList:(PRListID *)list attr:(PRListAttr *)attr {
    [self zSetValue:value forList:list attr:attr];
}

#pragma mark - zList Getters

- (BOOL)zListIDs:(NSArray **)outValue {
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT playlist_id FROM playlists ORDER BY type, title COLLATE NOCASE, playlist_id" bindings:nil columns:@[PRColInteger] out:&rlt];
    if (success && outValue) {
        *outValue = [rlt PRMap:^(NSInteger idx, id obj){return obj[0];}];
    }
    return success;
}

- (BOOL)zLibraryList:(PRListID **)outValue {
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

- (BOOL)zNowPlayingList:(PRListID **)outValue {
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

- (BOOL)zListForListID:(PRListID *)list out:(PRList **)outValue {
    if (outValue) {
        *outValue = [[PRList alloc] initWithListID:list connection:(PRConnection*)(_db?:(id)_conn)];
    }
    return *outValue != nil;
}

- (BOOL)zLists:(NSArray **)outValue {
    NSArray *lists = nil;
    BOOL success = [self zListIDs:&lists];
    if (!success) {
        return NO;
    }
    
    NSMutableArray *listDescriptions = [NSMutableArray array];
    for (PRListID *i in lists) {
        PRList *description = nil;
        success = [self zListForListID:i out:&description];
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

- (BOOL)zLibraryDescriptionForListID:(PRListID *)list out:(PRLibraryDescription **)outValue {
    if (outValue) {
        *outValue = [[PRLibraryDescription alloc] initWithListID:list connection:(PRConnection*)(_db?:(id)_conn)];
    }
    return *outValue != nil;
}

- (BOOL)zBrowserDescriptionsForList:(PRListID *)list out:(NSArray **)outValue {
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
    __block PRList *list = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zTransaction:^{
        BOOL success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"INSERT INTO playlists DEFAULT VALUES"];
        if (!success2) {
            return NO;
        }
        NSArray *rlt = nil;
        success2 = [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT MAX(playlist_id) FROM playlists" bindings:nil columns:@[PRColInteger] out:&rlt];
        if (!success2 || [rlt count] != 1) {
            return NO;
        }
        PRListID *listID = rlt[0][0];
        [self zListForListID:listID out:&list]; 
        return YES;
    }];
    if (success && outValue) {
        *outValue = list;
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
        [list setTitle:@"Untitled Playlist"];
        [list setType:PRListTypeStatic];
        [list setListViewSortAttr:PRListSortIndex];
        success2 = [self zSetListDescription:list forList:[list listID]];
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
        [list setTitle:@"Untitled Smart Playlist"];
        [list setType:PRListTypeSmart];
        [list setListViewSortAttr:PRListSortIndex];
        success2 = [self zSetListDescription:list forList:[list listID]];
        return success2;
    }];
    if (success && outValue) {
        *outValue = list;
    }
    return success;
}

- (BOOL)zRemoveList:(PRListID *)list {
    return [(PRDb*)(_db?:(id)_conn) zExecute:@"DELETE FROM playlists WHERE playlist_id = ?1" bindings:@{@1:list} columns:nil out:nil];
}

- (BOOL)zSetValue:(id)value forList:(PRListID *)list attr:(PRListAttr *)attr {
    PRList *listDescription = nil;
    BOOL success = [self zListForListID:list out:&listDescription];
    if (!success) {
        return NO;
    }
    [listDescription setValue:value forAttr:attr];
    return [listDescription writeToConnection:(PRConnection*)(_db?:(id)_conn)];
}

- (BOOL)zSetListDescription:(PRList *)value forList:(PRListID *)list {
    return [value writeToConnection:(PRConnection*)(_db?:(id)_conn)];
}

#pragma mark - ListItem Setters

- (BOOL)zAddItems:(NSArray *)items atIndex:(int)index toList:(PRListID *)list {
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

- (BOOL)zAppendItem:(PRListID *)item toList:(PRListID *)list {
    NSInteger count = 0;
    BOOL success = [self zCountForList:list out:&count];
    if (!success) {
        return NO;
    }
    NSString *stm = @"INSERT INTO playlist_items (playlist_id, playlist_index, file_id) VALUES (?1, ?2, ?3)";
    success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:list, @2:@(count + 1), @3:item} columns:nil out:nil];
    return success;
}

- (BOOL)zRemoveItemsAtIndexes:(NSIndexSet *)indexes fromList:(PRListID *)list {
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

- (BOOL)zClearList:(PRListID *)list {
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

- (BOOL)zClearList:(PRListID *)list exceptIndex:(NSInteger)index {
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

- (BOOL)zMoveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSInteger)index inList:(PRListID *)list {
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

- (BOOL)zAppendItemsFromLibraryViewSourceToList:(PRListID *)list {
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

- (BOOL)zCopyItemsFromList:(PRListID *)list toList:(PRListID *)list2 {
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

- (int)countForList:(PRListID *)list {
    NSInteger rlt = 0;
    [self zCountForList:list out:&rlt];
    return rlt;
}

#pragma mark - zListItem Getters

- (BOOL)zCountForList:(PRListID *)list out:(NSInteger *)outValue {
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

- (BOOL)zListItemAtIndex:(int)index inList:(PRListID *)list out:(PRListItemID **)outValue {
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

- (BOOL)zItemAtIndex:(int)index forList:(PRListID *)list out:(PRItemID **)outValue {
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

- (BOOL)zItemForListItem:(PRListItemID *)listItem out:(PRItemID **)outValue {
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

- (BOOL)zIndexForListItem:(PRListItemID *)listItem out:(NSInteger *)outValue {
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

- (BOOL)zListForListItem:(PRListItemID *)listItem out:(PRListID **)outValue {
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

- (BOOL)zList:(PRListID *)list containsItem:(PRItemID *)item out:(BOOL *)outValue {
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

- (BOOL)zIndexesOfItem:(PRItemID *)item inList:(PRListID *)list out:(NSIndexSet **)outValue {
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

#pragma mark - Update

- (BOOL)propagateListDelete {
    return [self propagateListItemDelete];
}

- (BOOL)propagateListItemDelete {
    return [[(PRDb*)(_db?:(id)_conn) playbackOrder] clean];
}

@end
