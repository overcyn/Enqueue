#import "PRPlaybackOrder.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "NSArray+Extensions.h"
#import "PRConnection.h"


NSString * const PR_TBL_PLAYBACK_ORDER_SQL = @"CREATE TABLE playback_order ("
"index_ INTEGER PRIMARY KEY, "
"playlist_item_id INTEGER NOT NULL, "
"CHECK (index_ > 0), "
"FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE RESTRICT ON DELETE CASCADE)";


@implementation PRPlaybackOrder {
    PRDb *_db;
    PRConnection *_conn;
}

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db_ {
    if (!(self = [super init])) {return nil;}
    _db = db_;
    return self;
}

- (instancetype)initWithConnection:(PRConnection *)connection {
    if ((self = [super init])) {
        _conn = connection;
    }
    return self;
}

- (void)create {
    [(PRDb*)(_db?:_conn) execute:PR_TBL_PLAYBACK_ORDER_SQL];
}

- (BOOL)initialize {   
    NSArray *result = nil;
    [(PRDb*)(_db?:_conn) zExecute:@"SELECT sql FROM sqlite_master WHERE name = 'playback_order'" bindings:nil columns:@[PRColString] out:&result];
    if ([result count] != 1 || ![result[0][0] isEqualToString:PR_TBL_PLAYBACK_ORDER_SQL]) {
        return NO;
    }    
    [(PRDb*)(_db?:_conn) zExecute:@"DELETE FROM playback_order"];
    return YES;
}

#pragma mark - Validation

- (BOOL)clean {
    [(PRDb*)(_db?:_conn) zExecute:@"DELETE FROM playback_order"];
    return YES;
}

#pragma mark - Accessors

- (BOOL)zCount:(NSInteger *)outValue {
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:_conn) zExecute:@"SELECT COUNT(*) FROM playback_order" bindings:nil columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = [rlt[0][0] integerValue];
    }
    return YES;
}

- (BOOL)zAppendListItem:(PRListItemID *)listItem {
    NSInteger count = 0;
    BOOL success = [self zCount:&count];
    if (!success) {
        return NO;
    }
    NSString *stm = @"INSERT INTO playback_order (index_, playlist_item_id) VALUES (?1, ?2)";
    return [(PRDb*)(_db?:_conn) zExecute:stm bindings:@{@1:@(count+1), @2:listItem} columns:nil out:nil];
}

- (BOOL)zListItemAtIndex:(NSInteger)index out:(PRListItemID **)outValue {
    NSArray *rlt = nil;
    NSString *stm = @"SELECT playlist_item_id FROM playback_order WHERE index_ = ?1";
    BOOL success = [(PRDb*)(_db?:_conn) zExecute:stm bindings:@{@1:@(index)} columns:@[PRColInteger] out:&rlt];
    if (!success || [rlt count] != 1) {
        return NO;
    }
    if (outValue) {
        *outValue = rlt[0][0];
    }
    return YES;
}

- (BOOL)zClear {
    return [(PRDb*)(_db?:_conn) zExecute:@"DELETE FROM playback_order"];
}

- (BOOL)zListItemsInList:(PRListID *)list notInPlaybackOrderAfterIndex:(int)index out:(NSArray **)outValue {
    NSString *stm = @"SELECT playlist_item_id FROM playlist_items "
        "LEFT OUTER JOIN (SELECT index_, playlist_item_id AS temp FROM playback_order "
        "GROUP BY playlist_item_id) ON playlist_item_id = temp "
        "WHERE playlist_id = ?1 AND (index_ <= ?2 OR index_ IS NULL)";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:_conn) zExecute:stm bindings:@{@1:list, @2:@(index)} columns:@[PRColInteger] out:&rlt];
    if (!success) {
        return NO;
    }
    if (outValue) {
        *outValue = [rlt PRMap:^(NSInteger idx, NSArray *obj){
            return obj[0];
        }];
    }
    return YES;
}

- (int)count {
    NSInteger rlt = 0;
    [self zCount:&rlt];
    return rlt;
}

- (void)appendListItem:(PRListItemID *)listItem {
    [self zAppendListItem:listItem];
}

- (PRListItemID *)listItemAtIndex:(int)index {
    PRListItemID *item = nil;
    [self zListItemAtIndex:index out:&item];
    return item;
}

- (void)clear {
    [self zClear];
}

- (NSArray *)listItemsInList:(PRListID *)list notInPlaybackOrderAfterIndex:(int)index {
    NSArray *rlt = nil;
    [self zListItemsInList:list notInPlaybackOrderAfterIndex:index out:&rlt];
    return rlt;
}

#pragma mark - Update

- (BOOL)confirmPlaylistItemDelete:(NSError **)error {
    [self clean];
    return YES;
}

@end
