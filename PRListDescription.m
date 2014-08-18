#import "PRListDescription.h"
#import "PRDefaults.h"


@implementation PRListDescription {
    PRList *_list;
    NSArray *_items;
}

- (id)initWithList:(PRList *)list database:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _list = list;
    _items = [db executeCached:@"SELECT file_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index" bindings:@{@1:list} columns:@[PRColInteger]];
    return self;
}

@synthesize list = _list;

- (NSInteger)count {
    return [_items count];
}

- (PRItem *)itemAtIndex:(NSInteger)index {
    return _items[index][0];
}

@end


@implementation PRNowPlayingListDescription {
    NSArray *_albumCounts;
}

@synthesize albumCounts = _albumCounts;

- (id)initWithList:(PRList *)list database:(PRDb *)db {
    if (!(self = [super initWithList:list database:db])) {return nil;}
    
    NSString *string = [NSString stringWithFormat:@"SELECT library.album, library.%@, library.compilation "
                        "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                        "WHERE playlist_id = ?1 ORDER BY playlist_index",
                        ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist] ? @"artistAlbumArtist" : @"artist")];
    NSArray *results = [db execute:string bindings:@{@1:list} columns:@[PRColString, PRColString, PRColInteger]];
    if ([results count] != 0) {
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
            if (![[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]) {
                compilation = NO;
                compilation2 = NO;
            }
            if (compilation != compilation2 || (compilation && !albumSame) || (!compilation && (!albumSame || !artistSame))) {
                [array addObject:[NSNumber numberWithInt:count]];
                count = 0;
            }
            count++;
        }
        [array addObject:@(count)];
        _albumCounts = array;
    } else {
        _albumCounts = @[];
    }
    return self;
}

@end
