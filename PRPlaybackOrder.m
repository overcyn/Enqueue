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
    [db executeString:string];
}

- (void)initialize
{
    NSString *string = @"DELETE FROM playback_order";
    [db executeString:string];
}

- (BOOL)validate
{
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'playback_order'";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_PLAYBACK_ORDER_SQL]) {
        return FALSE;
    }
    return TRUE;
}

// ========================================
// Validation
// ========================================

- (BOOL)clean_error:(NSError **)error
{
//    NSString *statement = @"DELETE FROM playback_order "
//    "WHERE playlist_item_id NOT IN (SELECT playlist_item_id FROM playlist_items)";
//    if ([db executeStatement:statement _error:nil]) {
//        return FALSE;
//    }
//    
    int count;
    if (![db count:&count forTable:@"playback_order" _error:nil]) {
        return FALSE;
    }
    
    NSArray *results;
    NSString *statement = @"SELECT MAX(index_) from playback_order";
    if ([db executeStatement:statement withBindings:nil result:&results _error:nil]) {
        return FALSE;
    }
    if ([[[results objectAtIndex:0] objectAtIndex:0] intValue] == count) {
        return TRUE;
    }
    
    // Begin clean
    statement = @"SELECT index_ FROM playback_order ORDER BY index_";
    if ([db executeStatement:statement withBindings:nil  result:&results _error:nil]) {
        return FALSE;
    }   
    for (int i = 0; i < [results count]; i++) {
        int oldIndex = [[[results objectAtIndex:i] objectAtIndex:0] intValue];
        statement = @"UPDATE playback_order SET index_ = ?1 WHERE index_ = ?2";
        NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:i + 1], [NSNumber numberWithInt:1],
                                  [NSNumber numberWithInt:oldIndex], [NSNumber numberWithInt:2], nil];
        if (![db executeStatement:statement withBindings:bindings _error:nil]) {
            return FALSE;
        }
    }
    
    return TRUE;
}

// ========================================
// Accessors
// ========================================

- (BOOL)cleanPlaybackOrder
{
    int count, min, max;
    [self count:&count _error:nil];
    if (count == 0) {
        return TRUE;
    }
    
    NSArray *result;
    if (![db executeStatement:@"SELECT max(index_) FROM playback_order"
                 withBindings:nil 
                       result:&result 
                       _error:nil]) {
        return FALSE;
    }
    max = [[result objectAtIndex:0] intValue];

    if (![db executeStatement:@"SELECT min(index_) FROM playback_order"
                 withBindings:nil 
                       result:&result 
                       _error:nil]) {
        return FALSE;
    }
    min = [[result objectAtIndex:0] intValue];

    if (min != 0 && max != count - 1) {
        // clean up playback order
        NSLog(@"PRPlaylistItems Inconsistency error!!!!!!!!!!!!!!!!!!!!");
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)count:(int *)count _error:(NSError **)error
{
	return [db count:count forTable:@"playback_order" _error:error];
}

- (BOOL)playlistItem:(PRPlaylistItem *)playlistItem atIndex:(int)index _error:(NSError **)error;
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:index],[NSNumber numberWithInt:1], nil];
    NSArray *results;
    if (![db executeStatement:@"SELECT playlist_item_id FROM playback_order WHERE index_ = ?1" 
                 withBindings:bindings 
                       result:&results 
                       _error:nil]) {
        return FALSE;
    }
    if ([results count] != 1 || ![[results objectAtIndex:0] isKindOfClass:[NSNumber class]]) {
        return FALSE;
    }
    if (playlistItem) {
        *playlistItem = [[results objectAtIndex:0] intValue];
    }
	return TRUE;
}

- (BOOL)appendPlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error;
{
    int count;
	[self count:&count _error:error];
    
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:count + 1], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:playlistItem], [NSNumber numberWithInt:2], nil];
    if (![db executeStatement:@"INSERT INTO playback_order (index_, playlist_item_id) "
          "VALUES (?1, ?2)" 
                 withBindings:bindings 
                       _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)clearPlaybackOrder_error:(NSError **)error
{
    if (![db executeStatement:@"DELETE FROM playback_order" _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)removePlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlistItem], [NSNumber numberWithInt:1],
                              nil];
    if (![db executeStatement:@"DELETE FROM playback_order WHERE playlist_item_id = ?1"
                 withBindings:bindings
                       _error:nil]) {
        return FALSE;
    }
    
    if ([self clean_error:(NSError **)error]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)         playlistItems:(NSArray **)playlistItems 
			        inPlaylist:(PRPlaylist)playlist 
  notInPlaybackOrderAfterIndex:(int)index
				        _error:(NSError **)error;
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1],
                              [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil];
    NSArray *results;
    if (![db executeStatement:@"SELECT playlist_item_id "
          "FROM playlist_items "
          "LEFT OUTER JOIN (SELECT index_, playlist_item_id AS temp "
          "FROM playback_order "
          "GROUP BY playlist_item_id) ON playlist_item_id = temp "
          "WHERE playlist_id = ?1 AND (index_ <= ?2 OR index_ IS NULL)" 
                 withBindings:bindings 
                       result:&results 
                       _error:nil]) {
        return FALSE;
    }
    
    if (playlistItems) {
        *playlistItems = results;
    }
	return TRUE;
}

// ========================================
// Update
// ========================================

- (BOOL)confirmPlaylistItemDelete:(NSError **)error
{
    if (![self clean_error:nil]) {
        return FALSE;
    }
    return TRUE;
}

@end
