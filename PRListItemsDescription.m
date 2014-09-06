#import "PRListItemsDescription.h"
#import "PRDefaults.h"
#import "NSIndexSet+Extensions.h"


@implementation PRListItemsDescription {
    PRList *_list;
    NSArray *_items;
}

- (id)initWithList:(PRList *)list database:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _list = list;
    NSString *stm = @"SELECT file_id, playlist_item_id FROM playlist_items WHERE playlist_id = ?1 ORDER BY playlist_index";
    NSArray *rlt = nil;
    [db zExecute:stm bindings:@{@1:list} columns:@[PRColInteger, PRColInteger] out:&rlt];
    _items = rlt;
    return self;
}

@synthesize list = _list;

- (NSInteger)count {
    return [_items count];
}

- (PRItem *)itemAtIndex:(NSInteger)index {
    return _items[index][0];
}

- (PRItem *)listItemAtIndex:(NSInteger)index {
    return _items[index][1];
}

@end


@implementation PRNowPlayingListItemsDescription {
    NSArray *_albumCounts;
    NSMutableIndexSet *_albumIndexes;
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
                [array addObject:@(count)];
                count = 0;
            }
            count++;
        }
        [array addObject:@(count)];
        _albumCounts = array;
    } else {
        _albumCounts = @[];
    }
    
    _albumIndexes = [NSMutableIndexSet indexSet];
    NSInteger row = 1;
    [_albumIndexes addIndex:row];
    for (NSNumber *i in _albumCounts) {
        row += [i integerValue];
        [_albumIndexes addIndex:row];
    }
    
    return self;
}

- (NSInteger)indexForIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath length] == 1) {
        return [_albumIndexes indexAtPosition:[indexPath indexAtPosition:0]];
    } else if ([indexPath length] == 2) {
        return [_albumIndexes indexAtPosition:[indexPath indexAtPosition:0]] + [indexPath indexAtPosition:1];
    }
    return 0;
}

- (NSIndexPath *)indexPathForIndex:(NSInteger)index {
    NSInteger i = [_albumIndexes firstIndex];
    NSInteger prevI = 0;
    int album = 0;
    while (i != NSNotFound) {
        if (i > index) {
            break;
        }
        album++;
        prevI = i;
        i = [_albumIndexes indexGreaterThanIndex:i];
    }
    
    NSUInteger indexes[] = {album-1, index - prevI};
    return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

- (NSRange)rangeForIndexPath:(NSIndexPath *)indexPath {
    NSInteger parentIndex = [indexPath indexAtPosition:0];
    return NSMakeRange([_albumIndexes indexAtPosition:parentIndex], _albumCounts[parentIndex]);
}

@end
