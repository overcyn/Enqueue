#import "PRQueue.h"
#import "PRDb.h"


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

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)create_error:(NSError **)error
{
    NSString *statement = @"CREATE TABLE IF NOT EXISTS queue ("
    "queue_index INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
    "playlist_item_id INTEGER NOT NULL UNIQUE, "
    "FOREIGN KEY(playlist_item_id) REFERENCES playlist_items(playlist_item_id) ON UPDATE CASCADE ON DELETE CASCADE)";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)initialize_error:(NSError **)error
{
    return TRUE;
}

- (BOOL)validate_error:(NSError **)error
{
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