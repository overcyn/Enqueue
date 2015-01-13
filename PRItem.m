#import "PRItem.h"
#import "PRPlaylists.h"
#import "PRItem_Private.h"
#import "PRConnection.h"

@implementation PRItem {
    PRItemID *_item;
}

@synthesize item = _item;

- (id)initWithItemID:(PRItemID *)item connection:(PRConnection *)conn {
    if ((self = [super init])) {
        _item = item;
        NSArray *keys = [PRItem _keys];
        
        NSArray *rlt = nil;
        NSMutableArray *cols = [NSMutableArray array];
        NSMutableString *stm = [NSMutableString stringWithString:@"SELECT "];
        for (PRListAttr *i in keys) {
            [stm appendFormat:@"%@, ", [PRLibrary columnNameForItemAttr:i]];
            [cols addObject:[PRLibrary columnTypeForItemAttr:i]];
        }
        [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
        [stm appendString:@"FROM library WHERE file_id = ?1"];
        BOOL success = [conn zExecute:stm bindings:@{@1:_item} columns:cols out:&rlt];
        if (!success || [rlt count] != 1) {
            return nil;
        }
        NSArray *attributes = [rlt[0] mutableCopy];
        
        /* File Attributes */
        [self setPath:attributes[[keys indexOfObject:PRItemAttrPath]]];
        [self setSize:[attributes[[keys indexOfObject:PRItemAttrSize]] integerValue]];
        [self setCheckSum:attributes[[keys indexOfObject:PRItemAttrCheckSum]]];
        [self setLastModified:[NSDate dateWithString:attributes[[keys indexOfObject:PRItemAttrLastModified]]]];

        /* Song Attributes */
        [self setKind:[attributes[[keys indexOfObject:PRItemAttrKind]] integerValue]];
        [self setChannels:[attributes[[keys indexOfObject:PRItemAttrChannels]] integerValue]];
        [self setTime:[attributes[[keys indexOfObject:PRItemAttrTime]] integerValue]];
        [self setBitrate:[attributes[[keys indexOfObject:PRItemAttrBitrate]] integerValue]];
        [self setSampleRate:[attributes[[keys indexOfObject:PRItemAttrSampleRate]] integerValue]];

        /* String Tags */
        [self setTitle:attributes[[keys indexOfObject:PRItemAttrTitle]]];
        [self setArtist:attributes[[keys indexOfObject:PRItemAttrArtist]]];
        [self setAlbumArtist:attributes[[keys indexOfObject:PRItemAttrAlbumArtist]]];
        [self setAlbum:attributes[[keys indexOfObject:PRItemAttrAlbum]]];
        [self setComposer:attributes[[keys indexOfObject:PRItemAttrComposer]]];
        [self setGenre:attributes[[keys indexOfObject:PRItemAttrGenre]]];
        [self setComments:attributes[[keys indexOfObject:PRItemAttrComments]]];
        [self setLyrics:attributes[[keys indexOfObject:PRItemAttrLyrics]]];

        /* Number Tags */
        [self setBPM:[attributes[[keys indexOfObject:PRItemAttrBPM]] integerValue]];
        [self setYear:[attributes[[keys indexOfObject:PRItemAttrYear]] integerValue]];
        [self setTrackNumber:[attributes[[keys indexOfObject:PRItemAttrTrackNumber]] integerValue]];
        [self setTrackCount:[attributes[[keys indexOfObject:PRItemAttrTrackCount]] integerValue]];
        [self setDiscNumber:[attributes[[keys indexOfObject:PRItemAttrDiscNumber]] integerValue]];
        [self setDiscCount:[attributes[[keys indexOfObject:PRItemAttrDiscCount]] integerValue]];
        [self setCompilation:[attributes[[keys indexOfObject:PRItemAttrCompilation]] integerValue]];

        /* Artwork Tags */
        [self setArtwork:[attributes[[keys indexOfObject:PRItemAttrArtwork]] integerValue]];

        /* Custom Attributes */
        [self setArtistAlbumArtist:attributes[[keys indexOfObject:PRItemAttrArtistAlbumArtist]]];
        [self setDateAdded:[NSDate dateWithString:attributes[[keys indexOfObject:PRItemAttrDateAdded]]]];
        [self setLastPlayed:[NSDate dateWithString:attributes[[keys indexOfObject:PRItemAttrLastPlayed]]]];
        [self setPlayCount:[attributes[[keys indexOfObject:PRItemAttrPlayCount]] integerValue]];
        [self setRating:[attributes[[keys indexOfObject:PRItemAttrRating]] integerValue]];
    }
    return self;
}

- (BOOL)writeToConnection:(PRConnection *)conn {    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    /* File Attributes */
    [attributes setObject:[self path] ?: @"" forKey:PRItemAttrPath];
    [attributes setObject:@([self size]) forKey:PRItemAttrSize];
    [attributes setObject:[self checkSum] ?: [NSData data] forKey:PRItemAttrCheckSum];
    [attributes setObject:[[self lastModified] description] ?: @"" forKey:PRItemAttrLastModified];

    /* Song Attributes */
    [attributes setObject:@([self kind]) forKey:PRItemAttrKind];
    [attributes setObject:@([self channels]) forKey:PRItemAttrChannels];
    [attributes setObject:@([self time]) forKey:PRItemAttrTime];
    [attributes setObject:@([self bitrate]) forKey:PRItemAttrBitrate];
    [attributes setObject:@([self sampleRate]) forKey:PRItemAttrSampleRate];

    /* String Tags */
    [attributes setObject:[self title] ?: @"" forKey:PRItemAttrTitle];
    [attributes setObject:[self artist] ?: @"" forKey:PRItemAttrArtist];
    [attributes setObject:[self albumArtist] ?: @"" forKey:PRItemAttrAlbumArtist];
    [attributes setObject:[self album] ?: @"" forKey:PRItemAttrAlbum];
    [attributes setObject:[self composer] ?: @"" forKey:PRItemAttrComposer];
    [attributes setObject:[self genre] ?: @"" forKey:PRItemAttrGenre];
    [attributes setObject:[self comments] ?: @"" forKey:PRItemAttrComments];
    [attributes setObject:[self lyrics] ?: @"" forKey:PRItemAttrLyrics];

    /* Number Tags */
    [attributes setObject:@([self BPM]) forKey:PRItemAttrBPM];
    [attributes setObject:@([self year]) forKey:PRItemAttrYear];
    [attributes setObject:@([self trackNumber]) forKey:PRItemAttrTrackNumber];
    [attributes setObject:@([self trackCount]) forKey:PRItemAttrTrackCount];
    [attributes setObject:@([self discNumber]) forKey:PRItemAttrDiscNumber];
    [attributes setObject:@([self discCount]) forKey:PRItemAttrDiscCount];
    [attributes setObject:@([self compilation]) forKey:PRItemAttrCompilation];

    /* Artwork Tags */
    [attributes setObject:@([self artwork]) forKey:PRItemAttrArtwork];

    /* Custom Attributes */
    [attributes setObject:[self artistAlbumArtist] ?: @"" forKey:PRItemAttrArtistAlbumArtist];
    [attributes setObject:[[self dateAdded] description] ?: @"" forKey:PRItemAttrDateAdded];
    [attributes setObject:[[self lastPlayed] description] ?: @"" forKey:PRItemAttrLastPlayed];
    [attributes setObject:@([self playCount]) forKey:PRItemAttrPlayCount];
    [attributes setObject:@([self rating]) forKey:PRItemAttrRating];
    
    NSMutableString *stm = [NSMutableString stringWithString:@"UPDATE library SET "];
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSInteger bindingIndex = 1;
    for (PRListAttr *i in [attributes allKeys]) {
        [stm appendFormat:@"%@ = ?%ld, ", [PRLibrary columnNameForItemAttr:i], (long)bindingIndex];
        bindings[@(bindingIndex)] = attributes[i];
        bindingIndex += 1;
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
    [stm appendFormat:@"WHERE file_id = %@", _item];
    return [conn zExecute:stm bindings:bindings columns:nil out:nil];
}

#pragma mark - Internal

+ (NSArray *)_keys {
    static NSArray *sKeys = nil;
    static dispatch_once_t sOnce = 0;
    dispatch_once(&sOnce, ^{
        sKeys = @[PRItemAttrPath, PRItemAttrSize, PRItemAttrCheckSum, PRItemAttrLastModified, 
            PRItemAttrKind, PRItemAttrChannels, PRItemAttrTime, PRItemAttrBitrate, PRItemAttrSampleRate, 
            PRItemAttrTitle, PRItemAttrArtist, PRItemAttrAlbumArtist, PRItemAttrAlbum, PRItemAttrComposer, PRItemAttrGenre, PRItemAttrComments, PRItemAttrLyrics, 
            PRItemAttrBPM, PRItemAttrYear, PRItemAttrTrackNumber, PRItemAttrTrackCount, PRItemAttrDiscNumber, PRItemAttrDiscCount, PRItemAttrCompilation, 
            PRItemAttrArtwork, 
            PRItemAttrArtistAlbumArtist, PRItemAttrDateAdded, PRItemAttrLastPlayed, PRItemAttrPlayCount, PRItemAttrRating];
    });
    return sKeys;
}

@end
