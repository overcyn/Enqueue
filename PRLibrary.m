#import "PRLibrary.h"
#import "PRDb.h"
#import "PRPlaylists.h"
#import "PRAlbumArtController.h"
#import "PRUserDefaults.h"
#import "PRTagger.h"
#import "PRFileInfo.h"

PRItemAttr * const PRItemAttrPath = @"PRItemAttrPath";
PRItemAttr * const PRItemAttrSize = @"PRItemAttrSize";
PRItemAttr * const PRItemAttrKind = @"PRItemAttrKind";
PRItemAttr * const PRItemAttrTime = @"PRItemAttrTime";
PRItemAttr * const PRItemAttrBitrate = @"PRItemAttrBitrate";
PRItemAttr * const PRItemAttrChannels = @"PRItemAttrChannels";
PRItemAttr * const PRItemAttrSampleRate = @"PRItemAttrSampleRate";
PRItemAttr * const PRItemAttrCheckSum = @"PRItemAttrCheckSum";
PRItemAttr * const PRItemAttrLastModified = @"PRItemAttrLastModified";
PRItemAttr * const PRItemAttrTitle = @"PRItemAttrTitle";
PRItemAttr * const PRItemAttrArtist = @"PRItemAttrArtist";
PRItemAttr * const PRItemAttrAlbum = @"PRItemAttrAlbum";
PRItemAttr * const PRItemAttrBPM = @"PRItemAttrBPM";
PRItemAttr * const PRItemAttrYear = @"PRItemAttrYear";
PRItemAttr * const PRItemAttrTrackNumber = @"PRItemAttrTrackNumber";
PRItemAttr * const PRItemAttrTrackCount = @"PRItemAttrTrackCount";
PRItemAttr * const PRItemAttrComposer = @"PRItemAttrComposer";
PRItemAttr * const PRItemAttrDiscNumber = @"PRItemAttrDiscNumber";
PRItemAttr * const PRItemAttrDiscCount = @"PRItemAttrDiscCount";
PRItemAttr * const PRItemAttrComments = @"PRItemAttrComments";
PRItemAttr * const PRItemAttrAlbumArtist = @"PRItemAttrAlbumArtist";
PRItemAttr * const PRItemAttrGenre = @"PRItemAttrGenre";
PRItemAttr * const PRItemAttrCompilation = @"PRItemAttrCompilation";
PRItemAttr * const PRItemAttrLyrics = @"PRItemAttrLyrics";
PRItemAttr * const PRItemAttrArtwork = @"PRItemAttrArtwork";
PRItemAttr * const PRItemAttrArtistAlbumArtist = @"PRItemAttrArtistAlbumArtist";
PRItemAttr * const PRItemAttrDateAdded = @"PRItemAttrDateAdded";
PRItemAttr * const PRItemAttrLastPlayed = @"PRItemAttrLastPlayed";
PRItemAttr * const PRItemAttrPlayCount = @"PRItemAttrPlayCount";
PRItemAttr * const PRItemAttrRating = @"PRItemAttrRating";

NSString * const PR_TBL_LIBRARY_SQL = @"CREATE TABLE library ("
"file_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
"path TEXT NOT NULL UNIQUE, "
"title TEXT NOT NULL DEFAULT '', "
"artist TEXT NOT NULL DEFAULT '', "
"album TEXT NOT NULL DEFAULT '', "
"albumArtist TEXT NOT NULL DEFAULT '', "
"composer TEXT NOT NULL DEFAULT '', "
"comments TEXT NOT NULL DEFAULT '', "
"genre TEXT NOT NULL DEFAULT '', "
"year INT NOT NULL DEFAULT 0, "
"trackNumber INT NOT NULL DEFAULT 0, "
"trackCount INT NOT NULL DEFAULT 0, "
"discNumber INT NOT NULL DEFAULT 0, "
"discCount INT NOT NULL DEFAULT 0, "
"BPM INT NOT NULL DEFAULT 0, "
"checkSum BLOB NOT NULL DEFAULT x'', "
"size INT NOT NULL DEFAULT 0, "
"kind INT NOT NULL DEFAULT 0, "
"time INT NOT NULL DEFAULT 0, "
"bitrate INT NOT NULL DEFAULT 0, "
"channels INT NOT NULL DEFAULT 0, "
"sampleRate INT NOT NULL DEFAULT 0, "
"lastModified TEXT NOT NULL DEFAULT '', "
"albumArt INT NOT NULL DEFAULT 0, "
"dateAdded TEXT NOT NULL DEFAULT '', "
"lastPlayed TEXT NOT NULL DEFAULT '', "
"playCount INT NOT NULL DEFAULT 0, "
"rating INT NOT NULL DEFAULT 0 ,"
"artistAlbumArtist TEXT NOT NULL DEFAULT '' , "
"lyrics TEXT NOT NULL DEFAULT '', "
"compilation INT NOT NULL DEFAULT 0"
")";
NSString * const PR_TBL_LIBRARY_SQL2 = @"CREATE TABLE library ("
"file_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
"path TEXT NOT NULL UNIQUE, "
"title TEXT NOT NULL DEFAULT '', "
"artist TEXT NOT NULL DEFAULT '', "
"album TEXT NOT NULL DEFAULT '', "
"albumArtist TEXT NOT NULL DEFAULT '', "
"composer TEXT NOT NULL DEFAULT '', "
"comments TEXT NOT NULL DEFAULT '', "
"genre TEXT NOT NULL DEFAULT '', "
"year INT NOT NULL DEFAULT 0, "
"trackNumber INT NOT NULL DEFAULT 0, "
"trackCount INT NOT NULL DEFAULT 0, "
"discNumber INT NOT NULL DEFAULT 0, "
"discCount INT NOT NULL DEFAULT 0, "
"BPM INT NOT NULL DEFAULT 0, "
"checkSum BLOB NOT NULL DEFAULT x'', "
"size INT NOT NULL DEFAULT 0, "
"kind INT NOT NULL DEFAULT 0, "
"time INT NOT NULL DEFAULT 0, "
"bitrate INT NOT NULL DEFAULT 0, "
"channels INT NOT NULL DEFAULT 0, "
"sampleRate INT NOT NULL DEFAULT 0, "
"albumArt INT NOT NULL DEFAULT 0, "
"dateAdded TEXT NOT NULL DEFAULT '', "
"lastPlayed TEXT NOT NULL DEFAULT '', "
"playCount INT NOT NULL DEFAULT 0, "
"rating INT NOT NULL DEFAULT 0 ,"
"artistAlbumArtist TEXT NOT NULL DEFAULT '' , "
"lastModified TEXT NOT NULL DEFAULT '', "
"lyrics TEXT NOT NULL DEFAULT '', "
"compilation INT NOT NULL DEFAULT 0"
")";
NSString * const PR_IDX_PATH_SQL = @"CREATE INDEX index_path ON library (path COLLATE hfs_compare)";
NSString * const PR_IDX_ALBUM_SQL = @"CREATE INDEX index_album ON library (album COLLATE NOCASE2)";
NSString * const PR_IDX_ARTIST_SQL = @"CREATE INDEX index_artist ON library (artist COLLATE NOCASE2)";
NSString * const PR_IDX_GENRE_SQL = @"CREATE INDEX index_genre ON library (genre COLLATE NOCASE2)";
NSString * const PR_IDX_ARTIST_ALBUM_ARTIST_SQL = @"CREATE INDEX index_artistAlbumArtist ON library (artistAlbumArtist COLLATE NOCASE2)";
NSString * const PR_IDX_COMPILATION_SQL = @"CREATE INDEX index_compilation ON library (compilation)";
NSString * const PR_TRG_ARTIST_ALBUM_ARTIST_SQL = @"CREATE TEMP TRIGGER trg_artistAlbumArtist "
"AFTER UPDATE OF artist, albumArtist ON library FOR EACH ROW BEGIN "
"UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
"WHERE file_id = NEW.file_id; END ";
NSString * const PR_TRG_ARTIST_ALBUM_ARTIST_2_SQL = @"CREATE TEMP TRIGGER trg_artistAlbumArtist2 "
"AFTER INSERT ON library FOR EACH ROW BEGIN "
"UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
"WHERE file_id = NEW.file_id; END ";


@implementation PRLibrary

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db_ {
    if (!(self = [super init])) {return nil;}
    db = db_;
	return self;
}

- (void)create {
    [db execute:PR_TBL_LIBRARY_SQL];
    [db execute:PR_IDX_PATH_SQL];
    [db execute:PR_IDX_ALBUM_SQL];
    [db execute:PR_IDX_ARTIST_SQL];
    [db execute:PR_IDX_GENRE_SQL];
    [db execute:PR_IDX_ARTIST_ALBUM_ARTIST_SQL];
    [db execute:PR_IDX_COMPILATION_SQL];
}

- (BOOL)initialize {
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'library'";
    NSArray *columns = [NSArray arrayWithObjects:PRColString, nil];
    NSArray *result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1 || !([[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_LIBRARY_SQL] || [[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_TBL_LIBRARY_SQL2])) {
        return FALSE;
    }
    
    result = [db execute:@"SELECT sql FROM sqlite_master WHERE name = 'index_path'"
				bindings:nil
				 columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_PATH_SQL]) {
        return FALSE;
    }
    
    result = [db execute:@"SELECT sql FROM sqlite_master WHERE name = 'index_album'"
				bindings:nil
				 columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_ALBUM_SQL]) {
        return FALSE;
    }
    
    result = [db execute:@"SELECT sql FROM sqlite_master WHERE name = 'index_artist'"
				bindings:nil
				 columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_ARTIST_SQL]) {
        return FALSE;
    }
    
    result = [db execute:@"SELECT sql FROM sqlite_master WHERE name = 'index_genre'"
				bindings:nil
				 columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_GENRE_SQL]) {
        return FALSE;
    }
    
    result = [db execute:@"SELECT sql FROM sqlite_master WHERE name = 'index_artistAlbumArtist'"
				bindings:nil
				 columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_ARTIST_ALBUM_ARTIST_SQL]) {
        return FALSE;
    }
    
    result = [db execute:@"SELECT sql FROM sqlite_master WHERE name = 'index_compilation'"
				bindings:nil
				 columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_COMPILATION_SQL]) {
        return FALSE;
    }

    [db execute:PR_TRG_ARTIST_ALBUM_ARTIST_SQL];
    [db execute:PR_TRG_ARTIST_ALBUM_ARTIST_2_SQL];
    string = @"UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
    "WHERE artistAlbumArtist != coalesce(nullif(albumArtist, ''), artist)";
    [db execute:string];
    return TRUE;
}

#pragma mark - Update

- (BOOL)propagateItemDelete {
    return [[db playlists] cleanPlaylistItems] && [[db playlists] propagateListItemDelete];
}

#pragma mark - Accessors

- (BOOL)containsItem:(PRItem *)item {
    NSArray *rlt = [db execute:@"SELECT count(*) FROM library WHERE file_id = ?1"
                      bindings:@{@1:item}
                       columns:@[PRColInteger]];
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue] > 0;
}

- (PRItem *)addItemWithAttrs:(NSDictionary *)attrs {
    NSMutableString *stm = [NSMutableString stringWithString:@"INSERT INTO library ("];
    NSMutableString *stm2 = [NSMutableString stringWithString:@"VALUES ("];
    NSMutableDictionary *bnd = [NSMutableDictionary dictionary];
    int bndIndex = 1;
    for (PRItemAttr *i in [attrs allKeys]) {
        [stm appendFormat:@"%@, ", [PRLibrary columnNameForItemAttr:i]];
        [stm2 appendFormat:@"?%d, ", bndIndex];
        [bnd setObject:[attrs objectForKey:i] forKey:[NSNumber numberWithInt:bndIndex]];
        bndIndex++;
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
    [stm appendFormat:@") "];
    [stm2 deleteCharactersInRange:NSMakeRange([stm2 length] - 2, 1)];
    [stm2 appendFormat:@") "];
    [stm appendString:stm2];
    [db execute:stm bindings:bnd columns:nil];
    return [PRItem numberWithUnsignedLongLong:[db lastInsertRowid]];
}

- (void)removeItems:(NSArray *)items {
    NSMutableString *stm = [NSMutableString stringWithString:@"DELETE FROM library WHERE file_id IN ("];
    for (PRItem *i in items) {
        [stm appendString:[NSString stringWithFormat:@"%llu, ", [i unsignedLongLongValue]]];
        [[db albumArtController] clearArtworkForItem:i];
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 2)];
    [stm appendString:@")"];
    [db execute:stm];
    [self propagateItemDelete];
}

- (id)valueForItem:(PRItem *)item attr:(PRItemAttr *)attr {
    NSArray *rlt = [db execute:[NSString stringWithFormat:@"SELECT %@ FROM library WHERE file_id = ?1", [PRLibrary columnNameForItemAttr:attr]]
                      bindings:@{@1:item}
                       columns:@[[PRLibrary columnTypeForItemAttr:attr]]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@"valueForFile:%@ attribute:%@",item, attr];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (void)setValue:(id)value forItem:(PRItem *)item attr:(PRItemAttr *)attr {
    [db execute:[NSString stringWithFormat:@"UPDATE library SET %@ = ?1 WHERE file_id = ?2", [PRLibrary columnNameForItemAttr:attr]]
       bindings:@{@1:value, @2:item}
        columns:nil];
}

- (NSDictionary *)attrsForItem:(PRItem *)item {
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT "];
    NSMutableArray *columns = [NSMutableArray array];
    for (PRItemAttr *i in [PRLibrary itemAttrs]) {
        [string appendFormat:@"%@, ",[PRLibrary columnNameForItemAttr:i]];
        [columns addObject:[PRLibrary columnTypeForItemAttr:i]];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@"FROM library WHERE file_id = ?1"];
    NSArray *results = [db execute:string bindings:@{@1:item} columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    NSArray *row = [results objectAtIndex:0];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (int i = 0; i < [[PRLibrary itemAttrs] count]; i++) {
        [dictionary setObject:[row objectAtIndex:i] forKey:[[PRLibrary itemAttrs] objectAtIndex:i]];
    }
    return dictionary;
}

- (void)setAttrs:(NSDictionary *)attrs forItem:(PRItem *)item {
    NSMutableString *string = [NSMutableString stringWithString:@"UPDATE library SET "];
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    int bindingIndex = 1;
    for (NSString *i in [attrs allKeys]) {
        [string appendFormat:@"%@ = ?%d, ", [PRLibrary columnNameForItemAttr:i], bindingIndex];
        [bindings setObject:[attrs objectForKey:i] forKey:[NSNumber numberWithInt:bindingIndex]];
        bindingIndex += 1;
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendFormat:@"WHERE file_id = ?%d", bindingIndex];
    [bindings setObject:item forKey:[NSNumber numberWithInt:bindingIndex]];
    [db execute:string bindings:bindings columns:nil];
}

- (NSString *)artistValueForItem:(PRItem *)item {
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        return [self valueForItem:item attr:PRItemAttrArtistAlbumArtist];
    } else {
        return [self valueForItem:item attr:PRItemAttrArtist];
    }
}

- (NSURL *)URLForItem:(PRItem *)item {
    return [NSURL URLWithString:[self valueForItem:item attr:PRItemAttrPath]];
}

- (NSArray *)itemsWithSimilarURL:(NSURL *)URL {
    NSArray *rlt = [db execute:@"SELECT file_id FROM library WHERE path = ?1 COLLATE hfs_compare" 
                      bindings:@{@1:[URL absoluteString]}
                       columns:@[PRColInteger]];
    NSMutableArray *array = [NSMutableArray array];
    for (NSArray *i in rlt) {
        [array addObject:[i objectAtIndex:0]];
    }
    return array;
}

- (NSArray *)itemsWithValue:(id)value forAttr:(PRItemAttr *)attr {
    NSArray *result = [db execute:[NSString stringWithFormat:@"SELECT file_id FROM library WHERE %@ = ?1", [PRLibrary columnNameForItemAttr:attr]]
                         bindings:@{@1:value}
                          columns:@[[PRLibrary columnTypeForItemAttr:attr]]];
    NSMutableArray *items = [NSMutableArray array];
    for (NSArray *i in result) {
        [items addObject:[i objectAtIndex:0]];
    }
    return items;
}

#pragma mark - Misc

+ (NSArray *)itemAttrProperties {
    static NSMutableArray *array = nil;
    if (!array) {
        array = [[NSMutableArray alloc] init];
        
        typedef struct {
            PRItemAttr *itemAttr;
            PRCol *columnType;
            NSString *columnName;
            NSString *title;
            int internal;
        } properties;
        
        int count = 30;
        properties p[] = {
            {PRItemAttrPath, PRColString, @"path", @"Path", 25},
            {PRItemAttrSize, PRColInteger, @"size", @"Size", 18},
            {PRItemAttrKind, PRColInteger, @"kind", @"Kind", 19},
            {PRItemAttrTime, PRColInteger, @"time", @"Time", 20},
            {PRItemAttrBitrate, PRColInteger, @"bitrate", @"Bitrate", 21},
            {PRItemAttrChannels, PRColInteger, @"channels", @"Channels", 22},
            {PRItemAttrSampleRate, PRColInteger, @"sampleRate", @"Sample Rate", 23},
            {PRItemAttrCheckSum, PRColData, @"checkSum", @"Check Sum", 27},
            {PRItemAttrLastModified, PRColString, @"lastModified", @"Last Modified", 28},
            
            {PRItemAttrTitle, PRColString, @"title", @"Title", 1},
            {PRItemAttrArtist, PRColString, @"artist", @"Artist", 2},
            {PRItemAttrAlbum, PRColString, @"album", @"Album", 3},
            {PRItemAttrBPM, PRColInteger, @"BPM", @"BPM", 4},
            {PRItemAttrYear, PRColInteger, @"year", @"Year", 5},
            {PRItemAttrTrackNumber, PRColInteger, @"trackNumber", @"Track", 6},
            {PRItemAttrTrackCount, PRColInteger, @"trackCount", @"Track Count", 7},
            {PRItemAttrComposer, PRColString, @"composer", @"Composer", 8},
            {PRItemAttrDiscNumber, PRColInteger, @"discNumber", @"Disc", 9},
            {PRItemAttrDiscCount, PRColInteger, @"discCount", @"Disc Count", 10},
            {PRItemAttrComments, PRColString, @"comments", @"Comments", 11},
            {PRItemAttrAlbumArtist, PRColString, @"albumArtist", @"Album Artist", 12},
            {PRItemAttrGenre, PRColString, @"genre", @"Genre", 13},
            {PRItemAttrCompilation, PRColInteger, @"compilation", @"Compilation", 29},
            {PRItemAttrLyrics, PRColString, @"lyrics", @"Lyrics", 30},
            
            {PRItemAttrArtwork, PRColInteger, @"albumArt", @"Artwork", 24},
            {PRItemAttrArtistAlbumArtist, PRColString, @"artistAlbumArtist", @"Artist / Album Artist", 26},
            
            {PRItemAttrDateAdded, PRColString, @"dateAdded", @"Date Added", 14},
            {PRItemAttrLastPlayed, PRColString, @"lastPlayed", @"Last Played", 15},
            {PRItemAttrPlayCount, PRColInteger, @"playCount", @"Play Count", 16},
            {PRItemAttrRating, PRColInteger, @"rating", @"Rating", 17},
        };
        
        for (int i = 0; i < count; i++) {
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              p[i].itemAttr, @"itemAttr", 
                              p[i].columnName, @"columnName", 
                              p[i].columnType, @"columnType", 
                              p[i].title, @"title", 
                              [NSNumber numberWithInt:p[i].internal], @"internal", nil]];
        }
    }
    return array;
}

+ (NSArray *)itemAttrs {
    static NSMutableArray *itemAttrs = nil;
    if (!itemAttrs) {
        NSArray *array = [self itemAttrProperties];
        itemAttrs = [[NSMutableArray alloc] init];
        for (NSDictionary *i in array) {
            [itemAttrs addObject:[i objectForKey:@"itemAttr"]];
        }
    }
    return itemAttrs;
}

+ (NSString *)columnNameForItemAttr:(PRItemAttr *)attr {
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"columnName"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return [dict objectForKey:attr];
}

+ (PRCol *)columnTypeForItemAttr:(PRItemAttr *)attr {
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"columnType"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return [dict objectForKey:attr];
}

+ (NSString *)titleForItemAttr:(PRItemAttr *)attr {
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"title"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return [dict objectForKey:attr];
}

+ (NSNumber *)internalForItemAttr:(PRItemAttr *)attr {
    if (attr == nil) {
        return [NSNumber numberWithInt:0];
    }
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"internal"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return [dict objectForKey:attr];
}

+ (PRItemAttr *)itemAttrForInternal:(NSNumber *)internal {
    if ([internal intValue] == 0) {
        return nil;
    }
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"itemAttr"] forKey:[i objectForKey:@"internal"]];
        }
    }
    return [dict objectForKey:internal];
}

@end
