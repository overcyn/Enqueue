#import "PRNowPlayingViewSource.h"
#import "PREnqueue.h"
#import "PRDb.h"
#import "PRUserDefaults.h"

@implementation PRNowPlayingViewSource

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

}

- (BOOL)initialize
{	
    NSString *string = @"CREATE TEMP TABLE now_playing_view_source ("
    "row INTEGER NOT NULL PRIMARY KEY, "
    "file_id INTEGER NOT NULL "
    ")";
    [db execute:string];
    return TRUE;
}

// ========================================
// Update
// ========================================

- (BOOL)refreshWithPlaylist:(PRPlaylist)playlist 
{
    NSString *string = @"DELETE FROM now_playing_view_source";
    [db execute:string];
    
    string = @"INSERT INTO now_playing_view_source (file_id) "
    "SELECT file_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    [db execute:string bindings:bindings columns:nil];
    return TRUE;
}

// ========================================
// Accessors
// ========================================

- (int)count
{
    NSString *string = @"SELECT COUNT(*) FROM now_playing_view_source";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[result objectAtIndex:0] intValue];
}

- (PRFile)fileForRow:(int)row
{
    NSString *string = @"SELECT file_id FROM now_playing_view_source WHERE row = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (NSArray *)albumCounts
{
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
    NSArray *columns = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:PRColumnString], 
                        [NSNumber numberWithInt:PRColumnString], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    
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