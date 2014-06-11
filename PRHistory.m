#import "PRHistory.h"
#import "PRDb.h"
#import "PRDefaults.h"


NSString * const PR_TBL_HISTORY_SQL = @"CREATE TABLE history ("
"file_id INTEGER NOT NULL, "
"date TEXT NOT NULL, "
"FOREIGN KEY(file_id) REFERENCES library(file_id) ON UPDATE CASCADE ON DELETE CASCADE)";


@implementation PRHistory

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _db = db;
    return self;
}

- (void)create {
    [_db execute:PR_TBL_HISTORY_SQL];
}

- (BOOL)initialize {
    NSArray *result = [_db execute:@"SELECT sql FROM sqlite_master WHERE name = 'history'" 
                          bindings:nil 
                           columns:@[PRColString]];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_HISTORY_SQL]) {
        return NO;
    }
    return YES;
}

#pragma mark - Accessors
 
- (void)addItem:(PRItem *)item withDate:(NSDate *)date {
    [_db execute:@"INSERT INTO history (file_id, date) VALUES (?1, ?2)"
        bindings:@{@1:item, @2:[[NSDate date] description]}
         columns:nil];
}

- (void)clear {
    [_db execute:@"DELETE FROM history"];
}

- (NSArray *)topSongs {
    NSString *stm;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        stm = @"SELECT file_id, playCount, title, artistAlbumArtist FROM library "
        "WHERE playCount > 0 ORDER BY playCount DESC LIMIT 250";
    } else {
        stm = @"SELECT file_id, playCount, title, artist FROM library "
        "WHERE playCount > 0 ORDER BY playCount DESC LIMIT 250";
    }
    NSArray *rlt = [_db execute:stm bindings:nil columns:@[PRColInteger, PRColInteger, PRColString, PRColString]];
    NSMutableArray *topSongs = [NSMutableArray array];
    
    for (NSArray *i in rlt) {
        [topSongs addObject:@{
         @"file":[i objectAtIndex:0],
         @"count":[i objectAtIndex:1],
         @"title":[i objectAtIndex:2],
         @"artist":[i objectAtIndex:3],
         @"max":[[rlt objectAtIndex:0] objectAtIndex:1]}];
    }
    return topSongs;
}

- (NSArray *)topArtists {
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
    NSArray *results = [_db execute:stm bindings:nil columns:@[PRColInteger, PRColInteger, PRColString]];
    NSMutableArray *topArtists = [NSMutableArray array];
    
    for (NSArray *i in results) {
        [topArtists addObject:@{
         @"file":[i objectAtIndex:0],
         @"count":[i objectAtIndex:1],
         @"artist":[i objectAtIndex:2],
         @"max":[[results objectAtIndex:0] objectAtIndex:1]}];
    }
    return topArtists;
}

- (NSArray *)recentlyAdded {
    NSString *stm;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        stm = @"SELECT file_id, dateAdded, count(album), artistAlbumArtist, album FROM library "
        "GROUP BY artistAlbumArtist COLLATE NOCASE2, album COLLATE NOCASE2 ORDER BY 2 DESC LIMIT 250";
    } else {
        stm = @"SELECT file_id, dateAdded, count(album), artist, album FROM library "
        "GROUP BY artistAlbumArtist COLLATE NOCASE2, album COLLATE NOCASE2 ORDER BY 2 DESC LIMIT 250";
    }
    NSArray *rlt = [_db execute:stm bindings:nil columns:@[PRColInteger, PRColString, PRColInteger, PRColString, PRColString]];
    
    NSMutableArray *recentlyAdded = [NSMutableArray array];
    for (NSArray *i in rlt) {
        NSDate *date = [NSDate dateWithString:[i objectAtIndex:1]];
        if (!date) {
            date = [NSDate date];
        }
        [recentlyAdded addObject:
         @{@"file":[i objectAtIndex:0],
         @"count":[i objectAtIndex:2],
         @"artist":[i objectAtIndex:3],
         @"album":[i objectAtIndex:4],
         @"date":date}];
    }
    return recentlyAdded;
}

- (NSArray *)recentlyPlayed {
    NSString *stm;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
        stm = @"SELECT library.file_id, date, title, artistAlbumArtist FROM history "
        "JOIN library ON history.file_id = library.file_id ORDER BY date DESC LIMIT 250";
    } else {
        stm = @"SELECT library.file_id, date, title, artist FROM history "
        "JOIN library ON history.file_id = library.file_id ORDER BY date DESC LIMIT 250";
    }
    NSArray *results = [_db execute:stm bindings:nil columns:@[PRColInteger, PRColString, PRColString, PRColString]];
    NSMutableArray *recentlyPlayed = [NSMutableArray array];
    for (NSArray *i in results) {
        NSDate *date = [NSDate dateWithString:[i objectAtIndex:1]];
        if (!date) {
            date = [NSDate date];
        }
        [recentlyPlayed addObject:@{
         @"file":[i objectAtIndex:0],
         @"title":[i objectAtIndex:2],
         @"artist":[i objectAtIndex:3],
         @"date":date}];
    }
    return recentlyPlayed;
}

#pragma mark - Update

- (BOOL)confirmFileDelete_error:(NSError **)error {
    return YES;
}

@end
