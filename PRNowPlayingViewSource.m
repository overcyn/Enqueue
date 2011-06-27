#import "PRNowPlayingViewSource.h"
#import "PRDb.h"
#import "PRUserDefaults.h"

@implementation PRNowPlayingViewSource

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

- (BOOL)create_error:(NSError **)error
{
    return TRUE;
}

- (BOOL)initialize_error:(NSError **)error
{	
    NSString *statement = @"CREATE TEMP TABLE now_playing_view_source ("
    "row INTEGER NOT NULL PRIMARY KEY, "
    "file_id INTEGER NOT NULL)";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)validate_error:(NSError **)error
{
    return TRUE;
}

// ========================================
// Update
// ========================================

- (BOOL)refreshWithPlaylist:(PRPlaylist)playlist 
					   sort:(PRFileAttribute)attribute 
				  ascending:(BOOL)asc 
					 _error:(NSError **)error
{
    if (![db executeStatement:@"DELETE FROM now_playing_view_source" _error:nil]) {
        return FALSE;
    }
    
    NSString *statement = @"INSERT INTO now_playing_view_source (file_id) "
    "SELECT file_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:playlist], [NSNumber numberWithInt:1], nil];
    if (![db executeStatement:statement withBindings:bindings _error:nil]) {
        return FALSE;
    }
    
    return TRUE;
}

// ========================================
// Accessors
// ========================================

- (BOOL)count:(int *)count _error:(NSError **)error
{
	if (![db count:count forTable:@"now_playing_view_source" _error:error]) {
        return FALSE;
    }    
    return TRUE;
}

- (BOOL)file:(PRFile *)file forRow:(int)row _error:(NSError **)error
{
    return [db intValue:(int *)file 
              forColumn:@"file_id" 
                    row:row 
                    key:@"row" 
                  table:@"now_playing_view_source" 
                 _error:nil];
}

- (BOOL)arrayOfAlbumCounts:(NSArray **)albumCounts _error:(NSError **)error
{
    NSArray *results;
    if ([[PRUserDefaults sharedUserDefaults] useAlbumArtist]) {
        if (![db executeStatement:@"SELECT library.album, library.artistAlbumArtist "
              "FROM now_playing_view_source "
              "JOIN library ON now_playing_view_source.file_id = library.file_id"
                     withBindings:nil 
                           result:&results 
                           _error:nil]) {
            return FALSE;
        }
	} else {
        if (![db executeStatement:@"SELECT library.album, library.artist "
              "FROM now_playing_view_source "
              "JOIN library ON now_playing_view_source.file_id = library.file_id"
                     withBindings:nil 
                           result:&results 
                           _error:nil]) {
            return FALSE;
        }
    }
    
    if ([results count] == 0) {
        *albumCounts = [NSArray array];
        return TRUE;
    } else if ([results count] == 1) {
        *albumCounts = [NSArray arrayWithObject:[NSNumber numberWithInt:1]];
        return TRUE;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    int count = 1;
    
    for (int i = 0; i < [results count] - 1; i++) {
        NSString *albumString = [[results objectAtIndex:i] objectAtIndex:0];
        NSString *artistString = [[results objectAtIndex:i] objectAtIndex:1];
        NSString *albumString2 = [[results objectAtIndex:i + 1] objectAtIndex:0];
        NSString *artistString2 = [[results objectAtIndex:i + 1] objectAtIndex:1];
        if (no_case(nil, [albumString lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [albumString cStringUsingEncoding:NSUTF16StringEncoding], 
                    [albumString2 lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [albumString2 cStringUsingEncoding:NSUTF16StringEncoding]) != 0 ||
            no_case(nil, [artistString lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [artistString cStringUsingEncoding:NSUTF16StringEncoding], 
                    [artistString2 lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [artistString2 cStringUsingEncoding:NSUTF16StringEncoding]) != 0) {
            [array addObject:[NSNumber numberWithInt:count]];
            count = 0;
        }
        count++;
    }
    
    [array addObject:[NSNumber numberWithInt:count]];
    *albumCounts = [NSArray arrayWithArray:array];
    return TRUE;
}

@end