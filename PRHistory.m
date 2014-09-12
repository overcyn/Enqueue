#import "PRHistory.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRConnection.h"
#import "NSArray+Extensions.h"


NSString * const PR_TBL_HISTORY_SQL = @"CREATE TABLE history ("
"file_id INTEGER NOT NULL, "
"date TEXT NOT NULL, "
"FOREIGN KEY(file_id) REFERENCES library(file_id) ON UPDATE CASCADE ON DELETE CASCADE)";


@implementation PRHistory {
    __weak PRDb *_db;
    __weak PRConnection *_conn;
}

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _db = db;
    return self;
}

- (instancetype)initWithConnection:(PRConnection *)connection {
    if ((self = [super init])) {
        _conn = connection;
    }
    return self;
}

- (void)create {
    [(PRDb*)(_db?:(id)_conn) zExecute:PR_TBL_HISTORY_SQL];
}

- (BOOL)initialize {
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT sql FROM sqlite_master WHERE name = 'history'" bindings:nil columns:@[PRColString] out:&rlt];
    if (!success || [rlt count] != 1 || ![rlt[0][0] isEqualToString:PR_TBL_HISTORY_SQL]) {
        return NO;
    }
    return YES;
}

#pragma mark - Accessors
 
- (BOOL)zAddItem:(PRItem *)item withDate:(NSDate *)date {
    NSString *stm = @"INSERT INTO history (file_id, date) VALUES (?1, ?2)";
    return [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:@{@1:item, @2:[[NSDate date] description]} columns:nil out:nil];
}

- (BOOL)zClear {
    return [(PRDb*)(_db?:(id)_conn) zExecute:@"DELETE FROM history"];
}

- (BOOL)zTopArtists:(NSArray **)out {
    NSString *stm;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        stm = @"SELECT file_id, sum(playCount), artistAlbumArtist FROM library "
        "GROUP BY artistAlbumArtist COLLATE NOCASE2 HAVING sum(playCount) > 0 AND artistAlbumArtist COLLATE NOCASE2 != '' "
        "ORDER BY 2 DESC, 3 DESC LIMIT 250";
    } else {
        stm = @"SELECT file_id, sum(playCount), artist FROM library "
        "GROUP BY artist COLLATE NOCASE2 HAVING sum(playCount) > 0 AND artist COLLATE NOCASE2 != '' "
        "ORDER BY 2 DESC, 3 DESC LIMIT 250";
    }
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:nil columns:@[PRColInteger, PRColInteger, PRColString] out:nil];
    if (!success) {
        return NO;
    }    
    if (out) {
        *out = [rlt PRMap:^(NSInteger idx, id obj){
            return @{
                @"file":obj[0],
                @"count":obj[1],
                @"artist":obj[2],
                @"max":rlt[0][1]
            };
        }];
    }
    return YES;
}

- (BOOL)zTopSongs:(NSArray **)out {
    NSString *stm;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        stm = @"SELECT file_id, playCount, title, artistAlbumArtist FROM library "
        "WHERE playCount > 0 ORDER BY playCount DESC LIMIT 250";
    } else {
        stm = @"SELECT file_id, playCount, title, artist FROM library "
        "WHERE playCount > 0 ORDER BY playCount DESC LIMIT 250";
    }
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:nil columns:@[PRColInteger, PRColInteger, PRColString, PRColString] out:&rlt];
    if (!success) {
        return NO;
    }
    if (out) {
        *out = [rlt PRMap:^(NSInteger idx, id obj){
            return @{
                @"file":obj[0],
                @"count":obj[1],
                @"title":obj[2],
                @"artist":obj[3],
                @"max":rlt[0][1]};
        }];
    }
    return YES;
}

- (BOOL)zRecentlyAdded:(NSArray **)out {
    NSString *stm;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        stm = @"SELECT file_id, dateAdded, count(album), artistAlbumArtist, album FROM library "
        "GROUP BY artistAlbumArtist COLLATE NOCASE2, album COLLATE NOCASE2 ORDER BY 2 DESC LIMIT 250";
    } else {
        stm = @"SELECT file_id, dateAdded, count(album), artist, album FROM library "
        "GROUP BY artistAlbumArtist COLLATE NOCASE2, album COLLATE NOCASE2 ORDER BY 2 DESC LIMIT 250";
    }
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:nil columns:@[PRColInteger, PRColString, PRColInteger, PRColString, PRColString] out:&rlt];
    if (!success) {
        return NO;
    }
    if (out) {
        *out = [rlt PRMap:^(NSInteger idx, id obj){
            return @{
                @"file":obj[0],
                @"count":obj[2],
                @"artist":obj[3],
                @"album":obj[4],
                @"date":[NSDate dateWithString:obj[1]] ?: [NSDate date]};
        }];
    }
    return YES;
}

- (BOOL)zRecentlyPlayed:(NSArray **)out {
    NSString *stm;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        stm = @"SELECT library.file_id, date, title, artistAlbumArtist FROM history "
        "JOIN library ON history.file_id = library.file_id ORDER BY date DESC LIMIT 250";
    } else {
        stm = @"SELECT library.file_id, date, title, artist FROM history "
        "JOIN library ON history.file_id = library.file_id ORDER BY date DESC LIMIT 250";
    }
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:nil columns:@[PRColInteger, PRColString, PRColString, PRColString] out:&rlt];
    if (!success) {
        return NO;
    }
    if (out) {
        *out = [rlt PRMap:^(NSInteger idx, id obj){
            return @{
                @"file":obj[0],
                @"title":obj[2],
                @"artist":obj[3],
                @"date":[NSDate dateWithString:obj[1]] ?: [NSDate date]};
        }];
    }
    return YES;
}
 
- (void)addItem:(PRItem *)item withDate:(NSDate *)date {
    [self zAddItem:item withDate:date];
}

- (void)clear {
    [self zClear];
}

- (NSArray *)topSongs {
    NSArray *rlt = nil;
    [self zTopSongs:&rlt];
    return rlt;
}

- (NSArray *)topArtists {
    NSArray *rlt = nil;
    [self zTopArtists:&rlt];
    return rlt;
}

- (NSArray *)recentlyAdded {
    NSArray *rlt = nil;
    [self zRecentlyAdded:&rlt];
    return rlt;
}

- (NSArray *)recentlyPlayed {
    NSArray *rlt = nil;
    [self zRecentlyPlayed:&rlt];
    return rlt;
}

#pragma mark - Update

- (BOOL)confirmFileDelete_error:(NSError **)error {
    return YES;
}

@end
