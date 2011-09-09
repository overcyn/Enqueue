#import "PRQueue.h"
#import "PRDb.h"

NSString * const PR_TBL_QUEUE_SQL = @"CREATE TABLE queue ("
"queue_index INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
"playlist_item_id INTEGER NOT NULL UNIQUE, "
"FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE CASCADE ON DELETE CASCADE)";

@implementation PRQueue

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
    NSString *string = PR_TBL_QUEUE_SQL;
    [db execute:string];
}

- (BOOL)initialize
{
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'queue'";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    if ([results count] != 1 || ![[[results objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_QUEUE_SQL]) {
        return FALSE;
    }
    return TRUE;
}

// ========================================
// Accessors
// ========================================

- (NSArray *)queueArray
{
    NSString *string = @"SELECT playlist_item_id FROM queue ORDER BY queue_index";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    NSMutableArray *queue = [NSMutableArray array];
    for (int i = 0; i < [results count]; i++) {
        [queue addObject:[[results objectAtIndex:i] objectAtIndex:0]];
    }
    return queue;
}

- (void)appendPlaylistItem:(PRPlaylistItem)playlistItem
{
    NSString *string = @"INSERT INTO queue (playlist_item_id) VALUES (?1)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlistItem], [NSNumber numberWithInt:1], nil];
    [db execute:string bindings:bindings columns:nil];
}

- (void)removePlaylistItem:(PRPlaylistItem)playlistItem
{
    NSString *string = @"DELETE FROM queue WHERE playlist_item_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlistItem], [NSNumber numberWithInt:1], nil];
    [db execute:string bindings:bindings columns:nil];
}

- (void)clear
{
    NSString *string = @"DELETE FROM queue";
    [db execute:string];
}

@end