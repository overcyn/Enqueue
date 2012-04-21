#import "PRNowPlayingViewSource.h"
#import "PRDb.h"
#import "PRUserDefaults.h"


@implementation PRNowPlayingViewSource

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db_ {
	if (!(self = [super init])) {return nil;}
    _db = db_;
	return self;
}

- (void)create {

}

- (BOOL)initialize {
    [_db execute:@"CREATE TEMP TABLE now_playing_view_source ("
     "row INTEGER NOT NULL PRIMARY KEY, file_id INTEGER NOT NULL)"];
    return TRUE;
}

#pragma mark - Update

- (void)refresh {
    [_db execute:@"DELETE FROM now_playing_view_source"];
    [_db execute:@"INSERT INTO now_playing_view_source (file_id) "
     "SELECT file_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index"
        bindings:@{@1:[[_db playlists] nowPlayingList]}
         columns:nil];
}

#pragma mark - Accessors

- (int)count {
    NSArray *result = [_db execute:@"SELECT COUNT(*) FROM now_playing_view_source"
                          bindings:nil
                           columns:@[PRColInteger]];
    if ([result count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[result objectAtIndex:0] intValue];
}

- (PRItem *)itemForRow:(int)row {
    NSArray *rlt = [_db execute:@"SELECT file_id FROM now_playing_view_source WHERE row = ?1"
                       bindings:@{@1:[NSNumber numberWithInt:row]}
                        columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (NSArray *)albumCounts {
    NSString *string;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        string = @"SELECT library.album, library.artistAlbumArtist, library.compilation "
        "FROM now_playing_view_source JOIN library ON now_playing_view_source.file_id = library.file_id";
	} else {
        string = @"SELECT library.album, library.artist, library.compilation "
        "FROM now_playing_view_source JOIN library ON now_playing_view_source.file_id = library.file_id";
    }
    NSArray *results = [_db execute:string bindings:nil columns:@[PRColString, PRColString, PRColInteger]];
    if ([results count] == 0) {
        return @[];
    }
    
    NSMutableArray *array = [NSMutableArray array];
    int count = 1;
    for (int i = 0; i < [results count] - 1; i++) {
        NSString *albumString = [[results objectAtIndex:i] objectAtIndex:0];
        NSString *artistString = [[results objectAtIndex:i] objectAtIndex:1];
        BOOL compilation = [[[results objectAtIndex:i] objectAtIndex:2] boolValue];
        NSString *albumString2 = [[results objectAtIndex:i + 1] objectAtIndex:0];
        NSString *artistString2 = [[results objectAtIndex:i + 1] objectAtIndex:1];
        BOOL compilation2 = [[[results objectAtIndex:i + 1] objectAtIndex:2] boolValue];
        
        BOOL albumSame = [albumString noCaseCompare:albumString2] == NSOrderedSame;
        BOOL artistSame = [artistString noCaseCompare:artistString2] == NSOrderedSame;
        if (compilation != compilation2 || (compilation && !albumSame) || (!compilation && (!albumSame || !artistSame))) {
            [array addObject:[NSNumber numberWithInt:count]];
            count = 0;
        }
        count++;
    }
    [array addObject:[NSNumber numberWithInt:count]];
    return array;
}

@end
