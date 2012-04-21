#import "PRQueue.h"
#import "PRDb.h"


NSString * const PR_TBL_QUEUE_SQL = @"CREATE TABLE queue ("
"queue_index INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
"playlist_item_id INTEGER NOT NULL UNIQUE, "
"FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE CASCADE ON DELETE CASCADE)";


@implementation PRQueue

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _db = db;
    return self;
}

- (void)create {
    [_db execute:PR_TBL_QUEUE_SQL];
}

- (BOOL)initialize {
    NSArray *results = [_db execute:@"SELECT sql FROM sqlite_master WHERE name = 'queue'"
                           bindings:nil 
                            columns:[NSArray arrayWithObjects:PRColString, nil]];
    if ([results count] != 1 || ![[[results objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_QUEUE_SQL]) {
        return FALSE;
    }
    return TRUE;
}

#pragma mark - Accessors

- (NSArray *)queueArray {
    NSArray *results = [_db execute:@"SELECT playlist_item_id FROM queue ORDER BY queue_index"
                           bindings:nil 
                            columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    NSMutableArray *queue = [NSMutableArray array];
    for (int i = 0; i < [results count]; i++) {
        [queue addObject:[[results objectAtIndex:i] objectAtIndex:0]];
    }
    return queue;
}

- (void)removeListItem:(PRListItem *)listItem {
    [_db execute:@"DELETE FROM queue WHERE playlist_item_id = ?1"
       bindings:[NSDictionary dictionaryWithObjectsAndKeys:listItem, [NSNumber numberWithInt:1], nil]
        columns:nil];
}

- (void)appendListItem:(PRListItem *)listItem {
    [_db execute:@"INSERT INTO queue (playlist_item_id) VALUES (?1)"
       bindings:[NSDictionary dictionaryWithObjectsAndKeys:listItem, [NSNumber numberWithInt:1], nil]
        columns:nil];
}

- (void)clear {
    [_db execute:@"DELETE FROM queue"];
}

@end