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
    [db executeString:string];
}

- (void)initialize
{
    
}

- (BOOL)validate
{
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'queue'";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *result = [db executeString:string withBindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_QUEUE_SQL]) {
        return FALSE;
    }
    return TRUE;
}

// ========================================
// Accessors
// ========================================

- (BOOL)queueArray:(NSArray **)array _error:(NSError **)error
{
    NSString *statement = @"SELECT playlist_item_id FROM queue ORDER BY queue_index";
    NSArray *results;
    if (![db executeStatement:statement withBindings:nil result:&results _error:nil]) {
        return FALSE;
    }
    *array = results;
    return TRUE;
}

- (BOOL)removePlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error
{
    NSString *statement = @"DELETE FROM queue WHERE playlist_item_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlistItem] 
                                                         forKey:[NSNumber numberWithInt:1]];
    if (![db executeStatement:statement withBindings:bindings _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)appendPlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error
{
    NSArray *queue;
    if (![self queueArray:&queue _error:nil]) {
        return FALSE;
    }
    if ([queue containsObject:[NSNumber numberWithInt:playlistItem]]) {
        return FALSE;
    }
    NSString *statement = @"INSERT INTO queue (playlist_item_id) VALUES (?1)";
    NSDictionary *bindings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:playlistItem] 
                                                         forKey:[NSNumber numberWithInt:1]];
    if (![db executeStatement:statement withBindings:bindings _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)clearQueue
{
    NSString *statement = @"DELETE FROM queue";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

@end