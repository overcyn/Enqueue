#import "PRNowPlayingViewSource.h"
#import "PRDb.h"
#import "PRUserDefaults.h"


@implementation PRNowPlayingViewSource

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_ {
    self = [super init];
	if (self) {
		_db = db_;
	}
	return self;
}

- (void)create {

}

- (BOOL)initialize {	
    NSString *string = @"CREATE TEMP TABLE now_playing_view_source ("
    "row INTEGER NOT NULL PRIMARY KEY, "
    "file_id INTEGER NOT NULL "
    ")";
    [_db execute:string];
    return TRUE;
}

// ========================================
// Update

- (void)refresh {
    [_db execute:@"DELETE FROM now_playing_view_source"];
    [_db execute:@"INSERT INTO now_playing_view_source (file_id) "
     "SELECT file_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index"
       bindings:[NSDictionary dictionaryWithObjectsAndKeys:[[_db playlists] nowPlayingList], [NSNumber numberWithInt:1], nil]
        columns:nil];
}

// ========================================
// Accessors

- (int)count {
    NSString *string = @"SELECT COUNT(*) FROM now_playing_view_source";
    NSArray *columns = [NSArray arrayWithObjects:PRColInteger, nil];
    NSArray *result = [_db execute:string bindings:nil columns:columns];
    if ([result count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[result objectAtIndex:0] intValue];
}

- (PRItem *)itemForRow:(int)row {
    NSArray *rlt = [_db execute:@"SELECT file_id FROM now_playing_view_source WHERE row = ?1"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (NSArray *)albumCounts {
    NSString *string;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        string = @"SELECT library.album, library.artistAlbumArtist "
        "FROM now_playing_view_source "
        "JOIN library ON now_playing_view_source.file_id = library.file_id";
	} else {
        string = @"SELECT library.album, library.artist "
        "FROM now_playing_view_source "
        "JOIN library ON now_playing_view_source.file_id = library.file_id";
    }
    NSArray *columns = [NSArray arrayWithObjects:PRColString, PRColString, nil];
    NSArray *results = [_db execute:string bindings:nil columns:columns];
    
    if ([results count] == 0) {
        return [NSArray array];
    } else if ([results count] == 1) {
        return [NSArray arrayWithObject:[NSNumber numberWithInt:1]];
    }
    
    NSMutableArray *array = [NSMutableArray array];
    int count = 1;
    
    for (int i = 0; i < [results count] - 1; i++) {
        NSString *albumString = [[results objectAtIndex:i] objectAtIndex:0];
        NSString *artistString = [[results objectAtIndex:i] objectAtIndex:1];
        NSString *albumString2 = [[results objectAtIndex:i + 1] objectAtIndex:0];
        NSString *artistString2 = [[results objectAtIndex:i + 1] objectAtIndex:1];
        if ([albumString noCaseCompare:albumString2] != NSOrderedSame ||
            [artistString noCaseCompare:artistString2] != NSOrderedSame) {
                [array addObject:[NSNumber numberWithInt:count]];
                count = 0;
            }
        count++;
    }
    
    [array addObject:[NSNumber numberWithInt:count]];
    return array;
}

@end
