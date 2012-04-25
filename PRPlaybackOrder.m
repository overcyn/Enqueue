#import "PRPlaybackOrder.h"
#import "PRDb.h"


NSString * const PR_TBL_PLAYBACK_ORDER_SQL = @"CREATE TABLE playback_order ("
"index_ INTEGER PRIMARY KEY, "
"playlist_item_id INTEGER NOT NULL, "
"CHECK (index_ > 0), "
"FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE RESTRICT ON DELETE CASCADE)";


@implementation PRPlaybackOrder

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db_ {
	if (!(self = [super init])) {return nil;}
	db = db_;
	return self;
}

- (void)create {
    [db execute:PR_TBL_PLAYBACK_ORDER_SQL];
}

- (BOOL)initialize {   
    NSArray *result = [db execute:@"SELECT sql FROM sqlite_master WHERE name = 'playback_order'"
						 bindings:nil 
						  columns:[NSArray arrayWithObjects:PRColString, nil]];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_PLAYBACK_ORDER_SQL]) {
        return FALSE;
    }
	
    [db execute:@"DELETE FROM playback_order"];
    return TRUE;
}

#pragma mark - Validation

- (BOOL)clean {
    [db execute:@"DELETE FROM playback_order"];
    return TRUE;
}

#pragma mark - Accessors

- (int)count {
    NSArray *results = [db execute:@"SELECT COUNT(*) FROM playback_order"
                          bindings:nil
                           columns:@[PRColInteger]];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (void)appendListItem:(PRListItem *)listItem {
    [db execute:@"INSERT INTO playback_order (index_, playlist_item_id) VALUES (?1, ?2)"
       bindings:@{@1:[NSNumber numberWithInt:[self count] + 1], @2:listItem}
        columns:nil];
}

- (PRListItem *)listItemAtIndex:(int)index {
    NSArray *rlt = [db execute:@"SELECT playlist_item_id FROM playback_order WHERE index_ = ?1"
                      bindings:@{@1:[NSNumber numberWithInt:index]}
                       columns:@[PRColInteger]];
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
                      bindings:@{@1:list, @2:[NSNumber numberWithInt:index]}
                       columns:@[PRColInteger]];
    NSMutableArray *playlistItems = [NSMutableArray array];
    for (NSArray *i in rlt) {
        [playlistItems addObject:[i objectAtIndex:0]];
    }
	return playlistItems;
}

#pragma mark - Update

- (BOOL)confirmPlaylistItemDelete:(NSError **)error {
    [self clean];
    return TRUE;
}

@end
