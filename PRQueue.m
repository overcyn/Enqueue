#import "PRQueue.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRConnection.h"
#import "NSArray+Extensions.h"


NSString * const PR_TBL_QUEUE_SQL = @"CREATE TABLE queue ("
"queue_index INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
"playlist_item_id INTEGER NOT NULL UNIQUE, "
"FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE CASCADE ON DELETE CASCADE)";


@implementation PRQueue {
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
    [(PRDb*)(_db?:(id)_conn) zExecute:PR_TBL_QUEUE_SQL];
}

- (BOOL)initialize {
    NSArray *rlt = nil;
    [(PRDb*)(_db?:(id)_conn) zExecute:@"SELECT sql FROM sqlite_master WHERE name = 'queue'" bindings:nil columns:@[PRColString] out:&rlt];
    if ([rlt count] != 1 || ![rlt[0][0] isEqualToString:PR_TBL_QUEUE_SQL]) {
        return NO;
    }
    return YES;
}

#pragma mark - Accessors

- (BOOL)zQueueArray:(NSArray **)out {
    NSString *stm = @"SELECT playlist_item_id FROM queue ORDER BY queue_index";
    NSArray *rlt = nil;
    BOOL success = [(PRDb*)(_db?:(id)_conn) zExecute:stm bindings:nil columns:@[PRColInteger] out:&rlt];
    if (!success) {
        return NO;
    }
    if (out) {
        *out = [rlt PRMap:^(NSInteger idx, id obj){
            return obj[0];
        }];
    }
    return YES;
}

- (NSArray *)queueArray {
    NSArray *rlt;
    [self zQueueArray:&rlt];
    return rlt;
}

- (BOOL)zRemoveListItem:(PRListItem *)listItem {
    return [(PRDb*)(_db?:(id)_conn) zExecute:@"DELETE FROM queue WHERE playlist_item_id = ?1" bindings:@{@1:listItem} columns:nil out:nil];
}

- (BOOL)zAppendListItem:(PRListItem *)listItem {
    return [(PRDb*)(_db?:(id)_conn) zExecute:@"INSERT INTO queue (playlist_item_id) VALUES (?1)" bindings:@{@1:listItem} columns:nil out:nil];
}

- (BOOL)zClear {
    return [(PRDb*)(_db?:(id)_conn) zExecute:@"DELETE FROM queue"];
}

- (void)removeListItem:(PRListItem *)listItem {
    [self zRemoveListItem:listItem];
}

- (void)appendListItem:(PRListItem *)listItem {
    [self zAppendListItem:listItem];
}

- (void)clear {
    [self zClear];
}

@end
