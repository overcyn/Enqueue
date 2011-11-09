#import "PRLibrary.h"
#import "PRDb.h"
#import "PRPlaylists.h"
#import "PRAlbumArtController.h"
#import "PRUserDefaults.h"
#import "PRTagEditor.h"

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
"artistAlbumArtist TEXT NOT NULL DEFAULT '' "
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
"lastModified TEXT NOT NULL DEFAULT '')";
NSString * const PR_IDX_PATH_SQL = @"CREATE INDEX index_path ON library (path COLLATE hfs_compare)";
NSString * const PR_IDX_ALBUM_SQL = @"CREATE INDEX index_album ON library (album COLLATE NOCASE2)";
NSString * const PR_IDX_ARTIST_SQL = @"CREATE INDEX index_artist ON library (artist COLLATE NOCASE2)";
NSString * const PR_IDX_GENRE_SQL = @"CREATE INDEX index_genre ON library (genre COLLATE NOCASE2)";
NSString * const PR_IDX_ARTIST_ALBUM_ARTIST_SQL = @"CREATE INDEX index_artistAlbumArtist ON library (artistAlbumArtist COLLATE NOCASE2)";
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
// ========================================

- (id)initWithDb:(PRDb *)db_
{
    if (!(self = [super init])) {return nil;}
    db = db_;
	return self;
}

- (void)create
{
    [db execute:PR_TBL_LIBRARY_SQL];
    [db execute:PR_IDX_PATH_SQL];
    [db execute:PR_IDX_ALBUM_SQL];
    [db execute:PR_IDX_ARTIST_SQL];
    [db execute:PR_IDX_GENRE_SQL];
    [db execute:PR_IDX_ARTIST_ALBUM_ARTIST_SQL];
}

- (BOOL)initialize
{
    NSString *string = @"SELECT sql FROM sqlite_master WHERE name = 'library'";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
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

    [db execute:PR_TRG_ARTIST_ALBUM_ARTIST_SQL];
    [db execute:PR_TRG_ARTIST_ALBUM_ARTIST_2_SQL];
    string = @"UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
    "WHERE artistAlbumArtist != coalesce(nullif(albumArtist, ''), artist)";
    [db execute:string];
    return TRUE;
}

// ========================================
// Misc
// ========================================

+ (NSArray *)attributes
{
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
                         nil] retain];
    } 
    return _attributes;
}

+ (NSDictionary *)columnDict
{
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
                               nil] retain];
    } 
    return _nameForAttribute;
}

+ (NSDictionary *)columnForAttribute
{
    static NSDictionary *_columnForAttribute;
    if (!_columnForAttribute) {
        _columnForAttribute = [[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRPathFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRTitleFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRArtistFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRAlbumFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRBPMFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRYearFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRTrackNumberFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRTrackCountFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRComposerFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRDiscNumberFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRDiscCountFileAttribute], 
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRCommentsFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRAlbumArtistFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRGenreFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRDateAddedFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRLastPlayedFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRPlayCountFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRRatingFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRSizeFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRKindFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRTimeFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRBitrateFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRChannelsFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRSampleRateFileAttribute],
                                [NSNumber numberWithInt:PRColumnInteger],   [NSNumber numberWithInt:PRAlbumArtFileAttribute],
                                [NSNumber numberWithInt:PRColumnData],      [NSNumber numberWithInt:PRCheckSumFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRArtistAlbumArtistFileAttribute],
                                [NSNumber numberWithInt:PRColumnString],    [NSNumber numberWithInt:PRLastModifiedFileAttribute],
                                nil] retain];
    }
    return _columnForAttribute;
}

+ (NSString *)columnNameForFileAttribute:(PRFileAttribute)attribute;
{
	NSString *columnName = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	if (!columnName) {
		return @"";
	}
	return columnName;
}

+ (PRFileAttribute)fileAttributeForName:(NSString *)name
{
    NSArray *keys = [[[self class] columnDict] allKeysForObject:name];
    if ([keys count] > 0) {
        return [[keys objectAtIndex:0] intValue];
    }
    return 0;
}

// ========================================
// Acccesors
// ========================================

- (BOOL)containsFile:(PRFile)file
{
    NSString *stm = @"SELECT count(*) FROM library WHERE file_id = ?1";
    NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    NSArray *col = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *rlt = [db execute:stm bindings:bnd columns:col];
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue] > 0;
}

- (PRFile)addFileWithAttributes:(NSDictionary *)attrs
{
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

- (id)valueForFile:(PRFile)file attribute:(PRFileAttribute)attribute
{
    NSString *stm = [NSString stringWithFormat:@"SELECT %@ FROM library WHERE file_id = ?1", 
                        [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]]];
    NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    NSArray *col = [NSArray arrayWithObjects:[[PRLibrary columnForAttribute] objectForKey:[NSNumber numberWithInt:attribute]], nil];
    NSArray *rlt = [db execute:stm bindings:bnd columns:col];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@"valueForFile:%d attribute:%d",file, attribute];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (void)setValue:(id)value forFile:(PRFile)file attribute:(PRFileAttribute)attribute
{
    NSString *string = [NSString stringWithFormat:@"UPDATE library SET %@ = ?1 WHERE file_id = ?2", 
                        [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]]];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              value, [NSNumber numberWithInt:1], 
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:2], nil];
    [db execute:string bindings:bindings columns:nil];
}

- (NSDictionary *)attributesForFile:(PRFile)file
{
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

- (void)setAttributes:(NSDictionary *)attributes forFile:(PRFile)file
{
    NSMutableString *string = [NSMutableString stringWithString:@"UPDATE library SET "];
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    int bindingIndex = 1;
    for (NSNumber *i in [attributes allKeys]) {
        [string appendFormat:@"%@ = ?%d, ", [[self class] columnNameForFileAttribute:[i intValue]], bindingIndex];
        [bindings setObject:[attributes objectForKey:i] forKey:[NSNumber numberWithInt:bindingIndex]];
        bindingIndex += 1;
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendFormat:@"WHERE file_id = ?%d", bindingIndex];
    [bindings setObject:[NSNumber numberWithInt:file] forKey:[NSNumber numberWithInt:bindingIndex]];
    [db execute:string bindings:bindings columns:nil];
}

- (void)removeFiles:(NSIndexSet *)files
{
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
    [self propagateFileDelete_error:nil];
}

// ========================================
// Accessors Tag
// ========================================

- (BOOL)updateTagsForFile:(PRFile)file
{
    NSURL *URL = [NSURL URLWithString:[self valueForFile:file attribute:PRPathFileAttribute]];
    PRTagEditor *te = [PRTagEditor tagEditorForURL:URL];
    if (!te) {
        return FALSE;
    }
    NSDictionary *info = [te info];
    
    BOOL change = FALSE;
    NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithDictionary:[PRTagEditor defaultTags]];
    [attr addEntriesFromDictionary:[info objectForKey:@"attr"]];
    for (NSNumber *i in [attr allKeys]) {
        id value = [self valueForFile:file attribute:[i intValue]];
        if (![[attr objectForKey:i] isEqual:value]) {
            change = TRUE;
        }
    }
    [self setAttributes:attr forFile:file];
    if ([info objectForKey:@"art"]) {
        [[db albumArtController] setCachedAlbumArt:[info objectForKey:@"art"] forFile:file];
    } else {
        [[db albumArtController] clearAlbumArtForFile:file];
    }
    return change;
}

// ========================================
// Accessors Misc
// ========================================

- (NSURL *)URLforFile:(PRFile)file
{
    return [NSURL URLWithString:[self valueForFile:file attribute:PRPathFileAttribute]];
}

- (NSString *)comparisonArtistForFile:(PRFile)file
{
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        return [self valueForFile:file attribute:PRArtistAlbumArtistFileAttribute];
    } else {
        return [self valueForFile:file attribute:PRArtistFileAttribute];
    }
}

- (NSArray *)filesWithSimilarURL:(NSURL *)URL
{
    NSString *stm = @"SELECT file_id FROM library WHERE path = ?1 COLLATE hfs_compare";
    NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:
                         [URL absoluteString], [NSNumber numberWithInt:1], nil];
    NSArray *col = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *rlt = [db execute:stm bindings:bnd columns:col];
    NSMutableArray *array = [NSMutableArray array];
    for (NSArray *i in rlt) {
        [array addObject:[i objectAtIndex:0]];
    }
    return array;
}

- (NSIndexSet *)filesWithValue:(id)value forAttribute:(PRFileAttribute)attribute
{
    NSString *string = [NSString stringWithFormat:@"SELECT file_id FROM library WHERE %@ = ?1", [PRLibrary columnNameForFileAttribute:attribute]];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              value, [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[[PRLibrary columnForAttribute] objectForKey:[NSNumber numberWithInt:attribute]], nil];
    NSArray *result = [db execute:string bindings:bindings columns:columns];
    NSMutableIndexSet *files = [NSMutableIndexSet indexSet];
    for (NSArray *i in result) {
        [files addIndex:[[i objectAtIndex:0] intValue]];
    }
    return files;
}

// ========================================
// Update
// ========================================

- (BOOL)propagateFileDelete_error:(NSError **)error
{
    if (![[db playlists] confirmFileDelete_error:nil]) {
        return FALSE;
    }
    return TRUE;
}

@end