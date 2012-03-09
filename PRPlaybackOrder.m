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

- (id)initWithDb:(PRDb *)db_ {
    self = [super init];
	if (self) {
		db = db_;
	}
	return self;
}

- (void)create {
    NSString *string = PR_TBL_PLAYBACK_ORDER_SQL;
    [db execute:string];
}

- (BOOL)initialize {   
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'playback_order'";
    NSArray *columns = [NSArray arrayWithObjects:PRColString, nil];
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

- (BOOL)clean {
    NSString *string = @"DELETE FROM playback_order";
    [db execute:string];
//    int count = [self count];
//    NSString *string = @"SELECT MAX(index_) from playback_order";
//    NSArray *columns = [NSArray arrayWithObjects:PRColInteger, nil];
//    NSArray *results = [db execute:string bindings:nil columns:columns];
//    if ([results count] != 1) {
//        [PRException raise:PRDbInconsistencyException format:@""];
//    }
//    int max = [[[results objectAtIndex:0] objectAtIndex:0] intValue];
//    
//    string = @"SELECT MIN(index_) from playback_order";
//    columns = [NSArray arrayWithObjects:PRColInteger, nil];
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
//    columns = [NSArray arrayWithObjects:PRColInteger, nil];
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
    return TRUE;
}

// ========================================
// Accessors

- (int)count {
    NSString *string = @"SELECT COUNT(*) FROM playback_order";
    NSArray *columns = [NSArray arrayWithObjects:PRColInteger, nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (void)appendListItem:(PRListItem *)listItem {
    [db execute:@"INSERT INTO playback_order (index_, playlist_item_id) VALUES (?1, ?2)"
       bindings:[NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithInt:[self count] + 1], [NSNumber numberWithInt:1],
                 listItem, [NSNumber numberWithInt:2], nil]
        columns:nil];
}

- (PRListItem *)listItemAtIndex:(int)index {
    NSArray *rlt = [db execute:@"SELECT playlist_item_id FROM playback_order WHERE index_ = ?1"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:index],[NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (void)clear {
    [db execute:@"DELETE FROM playback_order"];
}

- (NSArray *)listItemsInList:(PRList *)list notInPlaybackOrderAfterIndex:(int)index {
    NSArray *rlt = [db execute:@"SELECT playlist_item_id FROM playlist_items "
                    "LEFT OUTER JOIN (SELECT index_, playlist_item_id AS temp FROM playback_order "
                    "GROUP BY playlist_item_id) ON playlist_item_id = temp "
                    "WHERE playlist_id = ?1 AND (index_ <= ?2 OR index_ IS NULL)"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:
                                list, [NSNumber numberWithInt:1],
                                [NSNumber numberWithInt:index], [NSNumber numberWithInt:2], nil]
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    NSMutableArray *playlistItems = [NSMutableArray array];
    for (NSArray *i in rlt) {
        [playlistItems addObject:[i objectAtIndex:0]];
    }
	return playlistItems;
}

// ========================================
// Update

- (BOOL)confirmPlaylistItemDelete:(NSError **)error {
    [self clean];
    return TRUE;
}

@end
