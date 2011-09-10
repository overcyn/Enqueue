#import "PRPlaybackOrder.h"
#import "PRDb.h"


NSString * const PR_TBL_PLAYBACK_ORDER_SQL = @"CREATE TABLE playback_order ("
"index_ INTEGER PRIMARY KEY, "
"playlist_item_id INTEGER NOT NULL, "
"CHECK (index_ > 0), "
"FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE RESTRICT ON DELETE CASCADE)";

@implementation PRPlaybackOrder

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
    NSString *string = PR_TBL_PLAYBACK_ORDER_SQL;
    [db execute:string];
}

- (BOOL)initialize
{   
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'playback_order'";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_PLAYBACK_ORDER_SQL]) {
        return FALSE;
    }
    
    string = @"DELETE FROM playback_order";
    [db execute:string];
    return TRUE;
}

// ========================================
// Validation
// ========================================

- (void)clean
{
    NSString *string = @"DELETE FROM playback_order";
    [db execute:string];
//    int count = [self count];
//    NSString *string = @"SELECT MAX(index_) from playback_order";
//    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
//    NSArray *results = [db execute:string bindings:nil columns:columns];
//    if ([results count] != 1) {
//        [PRException raise:PRDbInconsistencyException format:@""];
//    }
//    int max = [[[results objectAtIndex:0] objectAtIndex:0] intValue];
//    
//    string = @"SELECT MIN(index_) from playback_order";
//    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
//    results = [db execute:string bindings:nil columns:columns];
//    if ([results count] != 1) {
//        [PRException raise:PRDbInconsistencyException format:@""];
//    }
//    int min = [[[results objectAtIndex:0] objectAtIndex:0] intValue];
//    
//    if (min != 0 && max != count - 1) {
//        // clean up playback order
//        NSLog(@"PRPlaylistItems Inconsistency error!!!!!!!!!!!!!!!!!!!!");
//    }
//
//    
//    string = @"SELECT index_ FROM playback_order ORDER BY index_";
//    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
//    results = [db execute:string bindings:nil columns:columns];
//    
//    for (int i = 0; i < [results count]; i++) {
//        int oldIndex = [[[results objectAtIndex:i] objectAtIndex:0] intValue];
//        string = @"UPDATE playback_order SET index_ = ?1 WHERE index_ = ?2";
//        NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                  [NSNumber numberWithInt:i + 1], [NSNumber numberWithInt:1],
//                                  [NSNumber numberWithInt:oldIndex], [NSNumber numberWithInt:2], nil];
//        [db execute:string bindings:bindings columns:nil];
//    }
}

// ========================================
// Accessors
// ========================================

- (int)count
{
    NSString *string = @"SELECT COUNT(*) FROM playback_order";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRPlaylistItem)playlistItemAtIndex:(int)index
{
    NSString *string = @"SELECT playlist_item_id FROM playback_order WHERE index_ = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:index],[NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (void)appendPlaylistItem:(PRPlaylistItem)playlistItem
{
    int count = [self count];
    NSString *string = @"INSERT INTO playback_order (index_, playlist_item_id) VALUES (?1, ?2)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:count + 1], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlistItem], [NSNumber numberWithInt:2], nil];
    [db execute:string bindings:bindings columns:nil];
}

- (void)clear
{
    [db execute:@"DELETE FROM playback_order"];
}

- (NSArray *)playlistItemsInPlaylist:(PRPlaylist)playlist notInPlaybackOrderAfterIndex:(int)index
{
    NSString *string = @"SELECT playlist_item_id FROM playlist_items "
    "LEFT OUTER JOIN (SELECT index_, playlist_item_id AS temp FROM playback_order "
    "GROUP BY playlist_item_id) ON playlist_item_id = temp "
    "WHERE playlist_id = ?1 AND (index_ <= ?2 OR index_ IS NULL)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    NSMutableArray *playlistItems = [NSMutableArray array];
    for (NSArray *i in results) {
        [playlistItems addObject:[i objectAtIndex:0]];
    }
	return playlistItems;
}

// ========================================
// Update
// ========================================

- (BOOL)confirmPlaylistItemDelete:(NSError **)error
{
    [self clean];
    return TRUE;
}

@end
