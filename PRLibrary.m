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

// ========================================
// Initialization

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
    
    string = @"SELECT sql FROM sqlite_master WHERE name = 'index_path'";
    result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_PATH_SQL]) {
        return FALSE;
    }
    
    string = @"SELECT sql FROM sqlite_master WHERE name = 'index_album'";
    result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_ALBUM_SQL]) {
        return FALSE;
    }
    
    string = @"SELECT sql FROM sqlite_master WHERE name = 'index_artist'";
    result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_ARTIST_SQL]) {
        return FALSE;
    }
    
    string = @"SELECT sql FROM sqlite_master WHERE name = 'index_genre'";
    result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_GENRE_SQL]) {
        return FALSE;
    }
    
    string = @"SELECT sql FROM sqlite_master WHERE name = 'index_artistAlbumArtist'";
    result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1 || ![[[result objectAtIndex:0] objectAtIndex:0] isEqualToString:PR_IDX_ARTIST_ALBUM_ARTIST_SQL]) {
        return FALSE;
    }
    
    string = @"SELECT sql FROM sqlite_master WHERE name = 'index_compilation'";
    result = [db execute:string bindings:nil columns:columns];
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

// ========================================
// Misc

+ (NSArray *)attributes {
    static NSArray *_attributes;
    if (!_attributes) {
        _attributes =  [[NSArray arrayWithObjects:
                         [NSNumber numberWithInt:PRPathFileAttribute],
                         [NSNumber numberWithInt:PRTitleFileAttribute],
                         [NSNumber numberWithInt:PRArtistFileAttribute],
                         [NSNumber numberWithInt:PRAlbumFileAttribute],
                         [NSNumber numberWithInt:PRBPMFileAttribute],
                         [NSNumber numberWithInt:PRYearFileAttribute],
                         [NSNumber numberWithInt:PRTrackNumberFileAttribute],
                         [NSNumber numberWithInt:PRTrackCountFileAttribute],
                         [NSNumber numberWithInt:PRComposerFileAttribute],
                         [NSNumber numberWithInt:PRDiscNumberFileAttribute],
                         [NSNumber numberWithInt:PRDiscCountFileAttribute], 
                         [NSNumber numberWithInt:PRCommentsFileAttribute],
                         [NSNumber numberWithInt:PRAlbumArtistFileAttribute],
                         [NSNumber numberWithInt:PRGenreFileAttribute],
                         [NSNumber numberWithInt:PRDateAddedFileAttribute],
                         [NSNumber numberWithInt:PRLastPlayedFileAttribute],
                         [NSNumber numberWithInt:PRPlayCountFileAttribute],
                         [NSNumber numberWithInt:PRRatingFileAttribute],
                         [NSNumber numberWithInt:PRSizeFileAttribute],
                         [NSNumber numberWithInt:PRKindFileAttribute],
                         [NSNumber numberWithInt:PRTimeFileAttribute],
                         [NSNumber numberWithInt:PRBitrateFileAttribute],
                         [NSNumber numberWithInt:PRChannelsFileAttribute],
                         [NSNumber numberWithInt:PRSampleRateFileAttribute],
                         [NSNumber numberWithInt:PRAlbumArtFileAttribute],
                         [NSNumber numberWithInt:PRCheckSumFileAttribute],
                         [NSNumber numberWithInt:PRArtistAlbumArtistFileAttribute],
                         [NSNumber numberWithInt:PRLastModifiedFileAttribute],
                         [NSNumber numberWithInt:PRCompilationFileAttribute],
                         [NSNumber numberWithInt:PRLyricsFileAttribute],
                         nil] retain];
    } 
    return _attributes;
}

+ (NSDictionary *)columnDict {
	static NSDictionary *_nameForAttribute;
    if (!_nameForAttribute) {
        _nameForAttribute =  [[NSDictionary dictionaryWithObjectsAndKeys:
                               @"path",				[NSNumber numberWithInt:PRPathFileAttribute],
                               @"title",			[NSNumber numberWithInt:PRTitleFileAttribute],
                               @"artist",			[NSNumber numberWithInt:PRArtistFileAttribute],
                               @"album",			[NSNumber numberWithInt:PRAlbumFileAttribute],
                               @"BPM",				[NSNumber numberWithInt:PRBPMFileAttribute],
                               @"year",				[NSNumber numberWithInt:PRYearFileAttribute],
                               @"trackNumber",		[NSNumber numberWithInt:PRTrackNumberFileAttribute],
                               @"trackCount",		[NSNumber numberWithInt:PRTrackCountFileAttribute],
                               @"composer",			[NSNumber numberWithInt:PRComposerFileAttribute],
                               @"discNumber",		[NSNumber numberWithInt:PRDiscNumberFileAttribute],
                               @"discCount",		[NSNumber numberWithInt:PRDiscCountFileAttribute], 
                               @"comments",			[NSNumber numberWithInt:PRCommentsFileAttribute],
                               @"albumArtist",		[NSNumber numberWithInt:PRAlbumArtistFileAttribute],
                               @"genre",			[NSNumber numberWithInt:PRGenreFileAttribute],
                               @"dateAdded",		[NSNumber numberWithInt:PRDateAddedFileAttribute],
                               @"lastPlayed",		[NSNumber numberWithInt:PRLastPlayedFileAttribute],
                               @"playCount",		[NSNumber numberWithInt:PRPlayCountFileAttribute],
                               @"rating",			[NSNumber numberWithInt:PRRatingFileAttribute],
                               @"size",				[NSNumber numberWithInt:PRSizeFileAttribute],
                               @"kind",				[NSNumber numberWithInt:PRKindFileAttribute],
                               @"time",				[NSNumber numberWithInt:PRTimeFileAttribute],
                               @"bitrate",			[NSNumber numberWithInt:PRBitrateFileAttribute],
                               @"channels",			[NSNumber numberWithInt:PRChannelsFileAttribute],
                               @"sampleRate",		[NSNumber numberWithInt:PRSampleRateFileAttribute],
                               @"albumArt",         [NSNumber numberWithInt:PRAlbumArtFileAttribute],
                               @"checkSum",         [NSNumber numberWithInt:PRCheckSumFileAttribute],
                               @"artistAlbumArtist",[NSNumber numberWithInt:PRArtistAlbumArtistFileAttribute],
                               @"lastModified",     [NSNumber numberWithInt:PRLastModifiedFileAttribute],
                               @"compilation",      [NSNumber numberWithInt:PRCompilationFileAttribute],
                               @"lyrics",           [NSNumber numberWithInt:PRLyricsFileAttribute],
                               nil] retain];
    } 
    return _nameForAttribute;
}

+ (NSDictionary *)columnForAttribute {
    static NSDictionary *_columnForAttribute;
    if (!_columnForAttribute) {
        _columnForAttribute = [[NSDictionary dictionaryWithObjectsAndKeys:
                                PRColString,    [NSNumber numberWithInt:PRPathFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRTitleFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRArtistFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRAlbumFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRBPMFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRYearFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRTrackNumberFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRTrackCountFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRComposerFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRDiscNumberFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRDiscCountFileAttribute], 
                                PRColString,    [NSNumber numberWithInt:PRCommentsFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRAlbumArtistFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRGenreFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRDateAddedFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRLastPlayedFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRPlayCountFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRRatingFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRSizeFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRKindFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRTimeFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRBitrateFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRChannelsFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRSampleRateFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRAlbumArtFileAttribute],
                                PRColData,      [NSNumber numberWithInt:PRCheckSumFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRArtistAlbumArtistFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRLastModifiedFileAttribute],
                                PRColInteger,   [NSNumber numberWithInt:PRCompilationFileAttribute],
                                PRColString,    [NSNumber numberWithInt:PRLyricsFileAttribute],
                                nil] retain];
    }
    return _columnForAttribute;
}

+ (NSString *)columnNameForFileAttribute:(PRFileAttribute)attribute {
	NSString *columnName = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	if (!columnName) {
		return @"";
	}
	return columnName;
}

+ (PRFileAttribute)fileAttributeForName:(NSString *)name {
    NSArray *keys = [[PRLibrary columnDict] allKeysForObject:name];
    if ([keys count] > 0) {
        return [[keys objectAtIndex:0] intValue];
    }
    return 0;
}

+ (NSString *)nameForFileAttribute:(PRFileAttribute)attribute {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Path",				  [NSNumber numberWithInt:PRPathFileAttribute],
                           @"Title",			  [NSNumber numberWithInt:PRTitleFileAttribute],
                           @"Artist",			  [NSNumber numberWithInt:PRArtistFileAttribute],
                           @"Album",			  [NSNumber numberWithInt:PRAlbumFileAttribute],
                           @"BPM",				  [NSNumber numberWithInt:PRBPMFileAttribute],
                           @"Year",				  [NSNumber numberWithInt:PRYearFileAttribute],
                           @"Track Number",		  [NSNumber numberWithInt:PRTrackNumberFileAttribute],
                           @"Track Count",		  [NSNumber numberWithInt:PRTrackCountFileAttribute],
                           @"Composer",			  [NSNumber numberWithInt:PRComposerFileAttribute],
                           @"Disc Number",		  [NSNumber numberWithInt:PRDiscNumberFileAttribute],
                           @"Disc Count",		  [NSNumber numberWithInt:PRDiscCountFileAttribute], 
                           @"Comments",			  [NSNumber numberWithInt:PRCommentsFileAttribute],
                           @"Album Artist",		  [NSNumber numberWithInt:PRAlbumArtistFileAttribute],
                           @"Genre",			  [NSNumber numberWithInt:PRGenreFileAttribute],
                           @"Date Added",		  [NSNumber numberWithInt:PRDateAddedFileAttribute],
                           @"Last Played",		  [NSNumber numberWithInt:PRLastPlayedFileAttribute],
                           @"Play Count",		  [NSNumber numberWithInt:PRPlayCountFileAttribute],
                           @"Rating",			  [NSNumber numberWithInt:PRRatingFileAttribute],
                           @"Size",				  [NSNumber numberWithInt:PRSizeFileAttribute],
                           @"Kind",				  [NSNumber numberWithInt:PRKindFileAttribute],
                           @"Time",				  [NSNumber numberWithInt:PRTimeFileAttribute],
                           @"Bitrate",			  [NSNumber numberWithInt:PRBitrateFileAttribute],
                           @"Channels",			  [NSNumber numberWithInt:PRChannelsFileAttribute],
                           @"Sample Rate", 		  [NSNumber numberWithInt:PRSampleRateFileAttribute],
                           @"Album Art",          [NSNumber numberWithInt:PRAlbumArtFileAttribute],
                           @"Check Sum",          [NSNumber numberWithInt:PRCheckSumFileAttribute],
                           @"Artist/Album Artist",[NSNumber numberWithInt:PRArtistAlbumArtistFileAttribute],
                           @"Last Modified",      [NSNumber numberWithInt:PRLastModifiedFileAttribute],
                           @"Compilation",        [NSNumber numberWithInt:PRCompilationFileAttribute],
                           @"Lyrics",             [NSNumber numberWithInt:PRLyricsFileAttribute],
                           nil];
    return [dict objectForKey:[NSNumber numberWithInt:attribute]];
}

// ========================================
// Acccesors

- (BOOL)containsFile:(PRFile)file {
    NSString *stm = @"SELECT count(*) FROM library WHERE file_id = ?1";
    NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    NSArray *col = [NSArray arrayWithObject:PRColInteger];
    NSArray *rlt = [db execute:stm bindings:bnd columns:col];
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue] > 0;
}

- (PRFile)addFileWithAttributes:(NSDictionary *)attrs {
    NSMutableString *stm = [NSMutableString stringWithString:@"INSERT INTO library ("];
    NSMutableString *stm2 = [NSMutableString stringWithString:@"VALUES ("];
    NSMutableDictionary *bnd = [NSMutableDictionary dictionary];
    int bndIndex = 1;
    for (NSNumber *i in [attrs allKeys]) {
        [stm appendFormat:@"%@, ", [PRLibrary columnNameForFileAttribute:[i intValue]]];
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
    PRFile file = [db lastInsertRowid];
    return file;
}

- (id)valueForFile:(PRFile)file attribute:(PRFileAttribute)attribute {
    NSString *stm = [NSString stringWithFormat:@"SELECT %@ FROM library WHERE file_id = ?1", [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]]];
    NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    NSArray *col = [NSArray arrayWithObjects:[[PRLibrary columnForAttribute] objectForKey:[NSNumber numberWithInt:attribute]], nil];
    NSArray *rlt = [db execute:stm bindings:bnd columns:col];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@"valueForFile:%d attribute:%d",file, attribute];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (void)setValue:(id)value forFile:(PRFile)file attribute:(PRFileAttribute)attribute {
    NSString *string = [NSString stringWithFormat:@"UPDATE library SET %@ = ?1 WHERE file_id = ?2", [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]]];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              value, [NSNumber numberWithInt:1], 
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:2], nil];
    [db execute:string bindings:bindings columns:nil];
}

- (NSDictionary *)attributesForFile:(PRFile)file {
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT "];
    for (NSNumber *i in [PRLibrary attributes]) {
        [string appendFormat:@"%@, ",[[PRLibrary columnDict] objectForKey:i]];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@"FROM library WHERE file_id = ?1"];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    NSMutableArray *columns = [NSMutableArray array];
    for (NSNumber *i in [PRLibrary attributes]) {
        [columns addObject:[[PRLibrary columnForAttribute] objectForKey:i]];
    }
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    NSArray *row = [results objectAtIndex:0];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (int i = 0; i < [[PRLibrary attributes] count]; i++) {
        [dictionary setObject:[row objectAtIndex:i] forKey:[[PRLibrary attributes] objectAtIndex:i]];
    }
    return dictionary;
}

- (void)setAttributes:(NSDictionary *)attributes forFile:(PRFile)file {
    NSMutableString *string = [NSMutableString stringWithString:@"UPDATE library SET "];
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    int bindingIndex = 1;
    for (NSNumber *i in [attributes allKeys]) {
        [string appendFormat:@"%@ = ?%d, ", [PRLibrary columnNameForFileAttribute:[i intValue]], bindingIndex];
        [bindings setObject:[attributes objectForKey:i] forKey:[NSNumber numberWithInt:bindingIndex]];
        bindingIndex += 1;
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendFormat:@"WHERE file_id = ?%d", bindingIndex];
    [bindings setObject:[NSNumber numberWithInt:file] forKey:[NSNumber numberWithInt:bindingIndex]];
    [db execute:string bindings:bindings columns:nil];
}

- (void)removeFiles:(NSIndexSet *)files {
    NSMutableString *string = [NSMutableString stringWithString:@"DELETE FROM library WHERE file_id IN ("];
    NSInteger file = [files firstIndex];
    while (file != NSNotFound) {
        [string appendString:[NSString stringWithFormat:@"%d, ", file]];
        file = [files indexGreaterThanIndex:file];
        // delete album art
        [[db albumArtController] clearAlbumArtForFile:file];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
    [string appendString:@")"];
    [db execute:string];
    [self propagateItemDelete];
}

// ========================================
// Accessors Tag

- (BOOL)updateTagsForFile:(PRFile)file {
    NSURL *URL = [NSURL URLWithString:[self valueForFile:file attribute:PRPathFileAttribute]];
    PRFileInfo *info = [PRTagger infoForURL:URL];
    if (!info) {
        return FALSE;
    }
    
    BOOL change = FALSE;
    NSDictionary *attr = [info attributes];
    for (NSNumber *i in [attr allKeys]) {
        id value = [self valueForFile:file attribute:[i intValue]];
        if (![[attr objectForKey:i] isEqual:value]) {
            change = TRUE;
        }
    }
    [self setAttributes:attr forFile:file];
    if ([info art]) {
        [[db albumArtController] setCachedAlbumArt:[info art] forFile:file];
    } else {
        [[db albumArtController] clearAlbumArtForFile:file];
    }
    return change;
}

// ========================================
// Accessors Misc

- (NSURL *)URLforFile:(PRFile)file {
    return [NSURL URLWithString:[self valueForFile:file attribute:PRPathFileAttribute]];
}

- (NSString *)comparisonArtistForFile:(PRFile)file {
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        return [self valueForFile:file attribute:PRArtistAlbumArtistFileAttribute];
    } else {
        return [self valueForFile:file attribute:PRArtistFileAttribute];
    }
}

- (NSArray *)filesWithSimilarURL:(NSURL *)URL {
    NSArray *rlt = [db execute:@"SELECT file_id FROM library WHERE path = ?1 COLLATE hfs_compare" 
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:[URL absoluteString], [NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    NSMutableArray *array = [NSMutableArray array];
    for (NSArray *i in rlt) {
        [array addObject:[i objectAtIndex:0]];
    }
    return array;
}

- (NSIndexSet *)filesWithValue:(id)value forAttribute:(PRFileAttribute)attribute {
    NSArray *result = [db execute:[NSString stringWithFormat:@"SELECT file_id FROM library WHERE %@ = ?1", [PRLibrary columnNameForFileAttribute:attribute]]
                         bindings:[NSDictionary dictionaryWithObject:value forKey:[NSNumber numberWithInt:1]] 
                          columns:[NSArray arrayWithObjects:[[PRLibrary columnForAttribute] objectForKey:[NSNumber numberWithInt:attribute]], nil]];
    NSMutableIndexSet *files = [NSMutableIndexSet indexSet];
    for (NSArray *i in result) {
        [files addIndex:[[i objectAtIndex:0] intValue]];
    }
    return files;
}

// ========================================
// Update

- (BOOL)propagateItemDelete {
    return [[db playlists] cleanPlaylistItems] && [[db playlists] propagateListItemDelete];
}

// ========================================
// ========================================

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

+ (NSDictionary *)itemAttrToColumnNameDictionary {
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"columnName"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return dict;
}

+ (NSDictionary *)itemAttrToColumnTypeDictionary {
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"columnType"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return dict;
}

+ (NSDictionary *)itemAttrToTitleDictionary {
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"title"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return dict;
}

+ (NSDictionary *)itemAttrToInternalDictionary {
    static NSMutableDictionary *dict = nil;
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        NSArray *array = [self itemAttrProperties];
        for (NSDictionary *i in array) {
            [dict setObject:[i objectForKey:@"internal"] forKey:[i objectForKey:@"itemAttr"]];
        }
    }
    return dict;
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

- (BOOL)containsItem:(PRItem *)item {
    NSArray *rlt = [db execute:@"SELECT count(*) FROM library WHERE file_id = ?1"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:item, [NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObject:PRColInteger]];
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue] > 0;
}

- (PRItem *)addItemWithAttrs:(NSDictionary *)attrs {
    NSMutableString *stm = [NSMutableString stringWithString:@"INSERT INTO library ("];
    NSMutableString *stm2 = [NSMutableString stringWithString:@"VALUES ("];
    NSMutableDictionary *bnd = [NSMutableDictionary dictionary];
    int bndIndex = 1;
    for (PRItemAttr *i in [attrs allKeys]) {
        [stm appendFormat:@"%@, ", [[PRLibrary itemAttrToColumnNameDictionary] objectForKey:i]];
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
    NSArray *rlt = [db execute:[NSString stringWithFormat:@"SELECT %@ FROM library WHERE file_id = ?1", [[PRLibrary itemAttrToColumnNameDictionary] objectForKey:attr]]
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:item, [NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObject:[[PRLibrary itemAttrToColumnTypeDictionary] objectForKey:attr]]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@"valueForFile:%@ attribute:%@",item, attr];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (void)setValue:(id)value forItem:(PRItem *)item attr:(PRItemAttr *)attr {
    [db execute:[NSString stringWithFormat:@"UPDATE library SET %@ = ?1 WHERE file_id = ?2", [[PRLibrary itemAttrToColumnNameDictionary] objectForKey:attr]]
       bindings:[NSDictionary dictionaryWithObjectsAndKeys:value, [NSNumber numberWithInt:1], item, [NSNumber numberWithInt:2], nil]
        columns:nil];
}

- (NSDictionary *)attrsForItem:(PRItem *)item {
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT "];
    NSMutableArray *columns = [NSMutableArray array];
    for (NSNumber *i in [PRLibrary itemAttrs]) {
        [string appendFormat:@"%@, ",[[PRLibrary itemAttrToColumnNameDictionary] objectForKey:i]];
        [columns addObject:[[PRLibrary columnForAttribute] objectForKey:i]];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@"FROM library WHERE file_id = ?1"];
    NSArray *results = [db execute:string 
                          bindings:[NSDictionary dictionaryWithObjectsAndKeys:item, [NSNumber numberWithInt:1], nil] 
                           columns:columns];
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
    for (NSNumber *i in [attrs allKeys]) {
        [string appendFormat:@"%@ = ?%d, ", [[PRLibrary itemAttrToColumnNameDictionary] objectForKey:i], bindingIndex];
        [bindings setObject:[attrs objectForKey:i] forKey:[NSNumber numberWithInt:bindingIndex]];
        bindingIndex += 1;
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendFormat:@"WHERE file_id = ?%d", bindingIndex];
    [bindings setObject:item forKey:[NSNumber numberWithInt:bindingIndex]];
    [db execute:string bindings:bindings columns:nil];
}

- (BOOL)updateTagsForItem:(PRItem *)item {
    return TRUE;
}

- (NSArray *)itemsWithSimilarURL:(NSURL *)URL {
    NSArray *rlt = [db execute:@"SELECT file_id FROM library WHERE path = ?1 COLLATE hfs_compare" 
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:[URL absoluteString], [NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    NSMutableArray *array = [NSMutableArray array];
    for (NSArray *i in rlt) {
        [array addObject:[i objectAtIndex:0]];
    }
    return array;
}

- (NSArray *)itemsWithValue:(id)value forAttr:(PRItemAttr *)attr {
    NSArray *result = [db execute:[NSString stringWithFormat:@"SELECT file_id FROM library WHERE %@ = ?1", [[PRLibrary itemAttrToColumnNameDictionary] objectForKey:attr]]
                         bindings:[NSDictionary dictionaryWithObject:value forKey:[NSNumber numberWithInt:1]] 
                          columns:[NSArray arrayWithObjects:[[PRLibrary itemAttrToColumnTypeDictionary] objectForKey:attr], nil]];
    NSMutableArray *items = [NSMutableArray array];
    for (NSArray *i in result) {
        [items addObject:[i objectAtIndex:0]];
    }
    return items;
}


// Misc Accessors
- (NSString *)artistValueForItem:(PRItem *)item {
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        return [self valueForItem:item attr:PRItemAttrArtist];
    } else {
        return [self valueForItem:item attr:PRItemAttrArtistAlbumArtist];
    }
}

- (NSURL *)URLForItem:(PRItem *)item {
    return [NSURL URLWithString:[self valueForItem:item attr:PRItemAttrPath]];
}

@end
