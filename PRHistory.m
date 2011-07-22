#import "PRHistory.h"
#import "PRDb.h"
#import "PRLog.h"
#import "PRAlbumArtController.h"


NSString * const PR_TBL_HISTORY_SQL = @"CREATE TABLE history ("
"file_id INTEGER NOT NULL, "
"date TEXT NOT NULL, "
"FOREIGN KEY(file_id) REFERENCES library(file_id) ON UPDATE CASCADE ON DELETE CASCADE)";

@implementation PRHistory

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_
{
	if ((self = [super init])) {
		db = db_;
	}
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)create;
{
    NSString *string = PR_TBL_HISTORY_SQL;
    [db executeString:string];
}

- (void)initialize
{
    
}

- (BOOL)validate
{
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'history'";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_HISTORY_SQL]) {
        return FALSE;
    }
    return TRUE;
}

// ========================================
// Accessors
// ========================================
 
- (void)addFile:(PRFile)file withDate:(NSDate *)date
{
    NSString *string = @"INSERT INTO history (file_id, date) VALUES (?1, ?2)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1],
                              [[NSDate date] description], [NSNumber numberWithInt:2], nil];
    [db executeString:string withBindings:bindings columns:nil];
}

- (void)clearHistory
{
    [db executeString:@"DELETE FROM history"];
}

- (NSArray *)topSongs
{
    NSString *string = @"SELECT file_id, playCount, title, artist FROM library "
    "WHERE playCount > 0 ORDER BY playCount DESC LIMIT 50";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:PRColumnInteger], 
                            [NSNumber numberWithInt:PRColumnString], [NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    NSMutableArray *topSongs = [NSMutableArray array];
    
    for (NSArray *i in result) {
        NSImage *icon;
        [[db albumArtController] albumArt:&icon forFile:[[i objectAtIndex:0] intValue] _error:nil];
        if (!icon) {
            icon = [NSImage imageNamed:@"PRLightAlbumArt"];
        }
        
        [topSongs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                             [i objectAtIndex:0], @"file", 
                             [i objectAtIndex:1], @"count", 
                             [i objectAtIndex:2], @"title", 
                             [i objectAtIndex:3], @"artist", 
                             [[result objectAtIndex:0] objectAtIndex:1], @"max", 
                             icon, @"icon", 
                             nil]];
    }
    return topSongs;
}

- (NSArray *)topArtists
{
    NSString *string = @"SELECT file_id, sum(playCount), artist FROM library "
    "GROUP BY artist COLLATE NOCASE2 HAVING sum(playCount) > 0 "
    "ORDER BY 2 DESC, 3 DESC LIMIT 50";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    NSMutableArray *topArtists = [NSMutableArray array];
    
    for (NSArray *i in result) {
        NSImage *icon;
        [[db albumArtController] albumArt:&icon forArtist:[i objectAtIndex:2] _error:nil];
        if (!icon) {
            icon = [NSImage imageNamed:@"PRLightAlbumArt"];
        }

        [topArtists addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               [i objectAtIndex:0], @"file", 
                               [i objectAtIndex:1], @"count", 
                               [i objectAtIndex:2], @"artist", 
                               [[result objectAtIndex:0] objectAtIndex:1], @"max", 
                               icon, @"icon", 
                               nil]];
    }
    return topArtists;
}

- (NSArray *)recentlyAdded
{
    NSString *string = @"SELECT file_id, dateAdded, title, artist FROM library ORDER BY 2 DESC LIMIT 50";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:PRColumnString], 
                            [NSNumber numberWithInt:PRColumnString], [NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    
    NSMutableArray *recentlyAdded = [NSMutableArray array];
    for (NSArray *i in result) {
        NSDate *date = [NSDate dateWithString:[i objectAtIndex:1]];
        if (!date) {
            [[PRLog sharedLog] presentFatalError:nil];
        }
        NSImage *icon;
        [[db albumArtController] albumArt:&icon forFile:[[i objectAtIndex:0] intValue] _error:nil];
        if (!icon) {
            icon = [NSImage imageNamed:@"PRLightAlbumArt"];
        }
        [recentlyAdded addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [i objectAtIndex:0], @"file", 
                                  [i objectAtIndex:2], @"title", 
                                  [i objectAtIndex:3], @"artist", 
                                  date, @"date", 
                                  icon, @"icon",
                                  nil]];
    }
    return recentlyAdded;
}

- (NSArray *)recentlyPlayed
{
    NSString *string = @"SELECT library.file_id, date, title, artist FROM history "
    "JOIN library ON history.file_id = library.file_id ORDER BY date DESC LIMIT 50";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], [NSNumber numberWithInt:PRColumnString], 
                        [NSNumber numberWithInt:PRColumnString], [NSNumber numberWithInt:PRColumnString],nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    NSMutableArray *recentlyPlayed = [NSMutableArray array];
    for (NSArray *i in result) {
        NSDate *date = [NSDate dateWithString:[i objectAtIndex:1]];
        if (!date) {
            [[PRLog sharedLog] presentFatalError:nil];
        }
        [recentlyPlayed addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [i objectAtIndex:0], @"file", 
                                   [i objectAtIndex:2], @"title",
                                   [i objectAtIndex:3], @"artist", 
                                   date, @"date", 
                                   nil]];
    }
    return recentlyPlayed;
}

// ========================================
// Update
// ========================================

- (BOOL)confirmFileDelete_error:(NSError **)error
{
    return TRUE;
}

@end
