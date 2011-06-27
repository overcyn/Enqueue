#import "PRLibrary.h"
#import "PRDb.h"
#import "PRPlaylists.h"
#import "PRAlbumArtController.h"


@implementation PRLibrary

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
    // create library
    if (![db executeStatement:
          @"CREATE TABLE IF NOT EXISTS library ("
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
          ")" 
                       _error:nil]) {
        return FALSE;
    }
    if (![db executeStatement:@"CREATE INDEX IF NOT EXISTS index_path ON library (path COLLATE NOCASE)"
                       _error:nil]) {
        return FALSE;
    }
    if (![db executeStatement:@"CREATE INDEX IF NOT EXISTS index_album ON library (album COLLATE NOCASE2)"
                       _error:nil]) {
        return FALSE;
    }
    if (![db executeStatement:@"CREATE INDEX IF NOT EXISTS index_genre ON library (genre COLLATE NOCASE2)"
                       _error:nil]) {
        return FALSE;
    }
    if (![db executeStatement:@"CREATE INDEX IF NOT EXISTS index_artist ON library (artist COLLATE NOCASE2)"
                       _error:nil]) {
        return FALSE;
    }
    if (![db executeStatement:@"CREATE INDEX IF NOT EXISTS index_artistAlbumArtist ON library (artistAlbumArtist COLLATE NOCASE2)"
                       _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)initialize_error:(NSError **)error
{
    NSString *statement = @"CREATE TEMP TRIGGER trg_artistAlbumArtist "
    "AFTER UPDATE OF artist, albumArtist ON library FOR EACH ROW BEGIN "
    "UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
    "WHERE file_id = NEW.file_id; END ";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    statement = @"CREATE TEMP TRIGGER trg_artistAlbumArtist2 "
    "AFTER INSERT ON library FOR EACH ROW BEGIN "
    "UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
    "WHERE file_id = NEW.file_id; END ";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    statement = @"UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
    "WHERE artistAlbumArtist != coalesce(nullif(albumArtist, ''), artist)";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    [self performSelectorInBackground:@selector(initialize2_error:) withObject:nil];
	return TRUE;
}

- (BOOL)initialize2_error:(NSError **)error
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *statement = @"CREATE TEMP TRIGGER trg_artistAlbumArtist "
    "AFTER UPDATE OF artist, albumArtist ON library FOR EACH ROW BEGIN "
    "UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
    "WHERE file_id = NEW.file_id; END ";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    statement = @"CREATE TEMP TRIGGER trg_artistAlbumArtist2 "
    "AFTER INSERT ON library FOR EACH ROW BEGIN "
    "UPDATE library SET artistAlbumArtist = coalesce(nullif(albumArtist, ''), artist) "
    "WHERE file_id = NEW.file_id; END ";
    if (![db executeStatement:statement _error:nil]) {
        return FALSE;
    }
    [pool drain];
    return TRUE;
}

- (BOOL)validate_error:(NSError **)error
{
    return TRUE;
}

// ========================================
// Action
// ========================================

- (BOOL)validateAndClean_error:(NSError **)error
{
    return TRUE;
}

// ========================================
// Acccesors
// ========================================

+ (NSDictionary *)columnDict
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"path",				[NSNumber numberWithInt:PRPathFileAttribute],
			@"title",				[NSNumber numberWithInt:PRTitleFileAttribute],
			@"artist",				[NSNumber numberWithInt:PRArtistFileAttribute],
			@"album",				[NSNumber numberWithInt:PRAlbumFileAttribute],
			@"BPM",					[NSNumber numberWithInt:PRBPMFileAttribute],
			@"year",				[NSNumber numberWithInt:PRYearFileAttribute],
			@"trackNumber",			[NSNumber numberWithInt:PRTrackNumberFileAttribute],
			@"trackCount",			[NSNumber numberWithInt:PRTrackCountFileAttribute],
			@"composer",			[NSNumber numberWithInt:PRComposerFileAttribute],
			@"discNumber",			[NSNumber numberWithInt:PRDiscNumberFileAttribute],
			@"discCount",			[NSNumber numberWithInt:PRDiscCountFileAttribute], 
			@"comments",			[NSNumber numberWithInt:PRCommentsFileAttribute],
			@"albumArtist",			[NSNumber numberWithInt:PRAlbumArtistFileAttribute],
			@"genre",				[NSNumber numberWithInt:PRGenreFileAttribute],
			@"dateAdded",			[NSNumber numberWithInt:PRDateAddedFileAttribute],
			@"lastPlayed",			[NSNumber numberWithInt:PRLastPlayedFileAttribute],
			@"playCount",			[NSNumber numberWithInt:PRPlayCountFileAttribute],
			@"rating",				[NSNumber numberWithInt:PRRatingFileAttribute],
			@"size",				[NSNumber numberWithInt:PRSizeFileAttribute],
			@"kind",				[NSNumber numberWithInt:PRKindFileAttribute],
			@"time",				[NSNumber numberWithInt:PRTimeFileAttribute],
			@"bitrate",				[NSNumber numberWithInt:PRBitrateFileAttribute],
			@"channels",			[NSNumber numberWithInt:PRChannelsFileAttribute],
			@"sampleRate",			[NSNumber numberWithInt:PRSampleRateFileAttribute],
			@"albumArt",            [NSNumber numberWithInt:PRAlbumArtFileAttribute],
            @"checkSum",            [NSNumber numberWithInt:PRCheckSumFileAttribute],
            @"artistAlbumArtist",   [NSNumber numberWithInt:PRArtistAlbumArtistFileAttribute],
            @"lastModified",        [NSNumber numberWithInt:PRLastModifiedFileAttribute],
			nil];
}

+ (NSString *)columnNameForFileAttribute:(PRFileAttribute)attribute;
{
	NSString *columnName = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	if (!columnName) {
		columnName = @"";
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

- (BOOL)value:(id *)value forFile:(PRFile)file  attribute:(PRFileAttribute)attribute _error:(NSError **)error;
{    
	NSString *column = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	return [db value:value 
		   forColumn:column 
				 row:file 
				 key:@"file_id" 
			   table:@"library" 
			  _error:error];	
}

- (BOOL)setValue:(id)value forFile:(PRFile)file attribute:(PRFileAttribute)attr _error:(NSError **)error;
{
	NSString *column = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attr]];
	return [db setValue:value 
			  forColumn:column 
					row:file 
					key:@"file_id" 
				  table:@"library" 
				 _error:error];
}

- (BOOL)intValue:(int *)value forFile:(PRFile)file attribute:(PRFileAttribute)attribute _error:(NSError **)error
{
	NSString *column = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attribute]];
	return [db intValue:value 
			  forColumn:column 
					row:file 
					key:@"file_id" 
				  table:@"library" 
				 _error:error];
}

- (BOOL)setIntValue:(int)value forFile:(PRFile)file attribute:(PRFileAttribute)attr _error:(NSError **)error
{
	NSString *column = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attr]];
	return [db setIntValue:value 
                 forColumn:column 
                       row:file 
                       key:@"file_id" 
                     table:@"library" 
                    _error:error];
}

- (BOOL)attributes:(NSDictionary **)attributes forFile:(PRFile)file _error:(NSError **)error
{
    NSString *statement = [NSString stringWithFormat:
                           @"SELECT path, "
                           "title, artist, album, BPM, year, trackNumber, trackCount, composer, discNumber, discCount, comments, albumArtist, genre, "
                           "albumArt, "
                           "size, kind, time, bitrate, channels, sampleRate, checkSum, lastModified, "
                           "dateAdded, lastPlayed, playCount, rating, "
                           "artistAlbumArtist "
                           "FROM library WHERE file_id = ?1"];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    NSArray *result;
    if (![db executeStatement:statement withBindings:bindings result:&result _error:nil]) {
        return FALSE;
    }
    if ([result count] == 0) {
        *attributes = nil;
        return TRUE;
    }
    result = [result objectAtIndex:0];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:[result objectAtIndex:0] forKey:[NSNumber numberWithInt:PRPathFileAttribute]];
    [dictionary setObject:[result objectAtIndex:1] forKey:[NSNumber numberWithInt:PRTitleFileAttribute]];
    [dictionary setObject:[result objectAtIndex:2] forKey:[NSNumber numberWithInt:PRArtistFileAttribute]];
    [dictionary setObject:[result objectAtIndex:3] forKey:[NSNumber numberWithInt:PRAlbumFileAttribute]];
    [dictionary setObject:[result objectAtIndex:4] forKey:[NSNumber numberWithInt:PRBPMFileAttribute]];
    [dictionary setObject:[result objectAtIndex:5] forKey:[NSNumber numberWithInt:PRYearFileAttribute]];
    [dictionary setObject:[result objectAtIndex:6] forKey:[NSNumber numberWithInt:PRTrackNumberFileAttribute]];
    [dictionary setObject:[result objectAtIndex:7] forKey:[NSNumber numberWithInt:PRTrackCountFileAttribute]];
    [dictionary setObject:[result objectAtIndex:8] forKey:[NSNumber numberWithInt:PRComposerFileAttribute]];
    [dictionary setObject:[result objectAtIndex:9] forKey:[NSNumber numberWithInt:PRDiscNumberFileAttribute]];
    [dictionary setObject:[result objectAtIndex:10] forKey:[NSNumber numberWithInt:PRDiscCountFileAttribute]];
    [dictionary setObject:[result objectAtIndex:11] forKey:[NSNumber numberWithInt:PRCommentsFileAttribute]];
    [dictionary setObject:[result objectAtIndex:12] forKey:[NSNumber numberWithInt:PRAlbumArtistFileAttribute]];
    [dictionary setObject:[result objectAtIndex:13] forKey:[NSNumber numberWithInt:PRGenreFileAttribute]];
    [dictionary setObject:[result objectAtIndex:14] forKey:[NSNumber numberWithInt:PRAlbumArtFileAttribute]];
    [dictionary setObject:[result objectAtIndex:15] forKey:[NSNumber numberWithInt:PRSizeFileAttribute]];
    [dictionary setObject:[result objectAtIndex:16] forKey:[NSNumber numberWithInt:PRKindFileAttribute]];
    [dictionary setObject:[result objectAtIndex:17] forKey:[NSNumber numberWithInt:PRTimeFileAttribute]];
    [dictionary setObject:[result objectAtIndex:18] forKey:[NSNumber numberWithInt:PRBitrateFileAttribute]];
    [dictionary setObject:[result objectAtIndex:19] forKey:[NSNumber numberWithInt:PRChannelsFileAttribute]];
    [dictionary setObject:[result objectAtIndex:20] forKey:[NSNumber numberWithInt:PRSampleRateFileAttribute]];
    [dictionary setObject:[result objectAtIndex:21] forKey:[NSNumber numberWithInt:PRCheckSumFileAttribute]];
    [dictionary setObject:[result objectAtIndex:22] forKey:[NSNumber numberWithInt:PRLastModifiedFileAttribute]];
    [dictionary setObject:[result objectAtIndex:23] forKey:[NSNumber numberWithInt:PRDateAddedFileAttribute]];
    [dictionary setObject:[result objectAtIndex:24] forKey:[NSNumber numberWithInt:PRLastPlayedFileAttribute]];
    [dictionary setObject:[result objectAtIndex:25] forKey:[NSNumber numberWithInt:PRPlayCountFileAttribute]];
    [dictionary setObject:[result objectAtIndex:26] forKey:[NSNumber numberWithInt:PRRatingFileAttribute]];
    [dictionary setObject:[result objectAtIndex:27] forKey:[NSNumber numberWithInt:PRArtistAlbumArtistFileAttribute]];

    
    *attributes = dictionary;
    return TRUE;
}

- (BOOL)setAttributes:(NSDictionary *)dictionary forFile:(PRFile)file _error:(NSError **)error
{
    NSMutableString *statement = [NSMutableString stringWithString:@"UPDATE library SET "];
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    int bindingIndex = 1;
    for (NSNumber *i in [dictionary allKeys]) {
        [statement appendFormat:@"%@ = ?%d, ", [[self class] columnNameForFileAttribute:[i intValue]], bindingIndex];
        [bindings setObject:[dictionary objectForKey:i] 
                     forKey:[NSNumber numberWithInt:bindingIndex]];
        
        bindingIndex += 1;
    }
    [statement deleteCharactersInRange:NSMakeRange([statement length] - 2, 1)];
    
    [statement appendFormat:@"WHERE file_id = ?%d", bindingIndex];
    [bindings setObject:[NSNumber numberWithInt:file] 
                 forKey:[NSNumber numberWithInt:bindingIndex]];
    
    if (![db executeStatement:statement 
                 withBindings:bindings 
                       _error:nil]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)addFile:(PRFile *)file withAttributes:(NSDictionary *)attributes _error:(NSError **)error
{
    NSMutableString *statement = [NSMutableString stringWithString:@"INSERT INTO library ("];
    NSMutableString *statement2 = [NSMutableString stringWithString:@"VALUES ("];
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    int bindingIndex = 1;
    for (NSNumber *i in [attributes allKeys]) {
        [statement appendFormat:@"%@, ", [[self class] columnNameForFileAttribute:[i intValue]]];
        [statement2 appendFormat:@"?%d, ", bindingIndex];
        [bindings setObject:[attributes objectForKey:i] forKey:[NSNumber numberWithInt:bindingIndex]];
        bindingIndex += 1;
    }
    [statement deleteCharactersInRange:NSMakeRange([statement length] - 2, 1)];
    [statement2 deleteCharactersInRange:NSMakeRange([statement2 length] - 2, 1)];
    [statement appendString:@") "];
    [statement2 appendString:@") "];
    [statement appendString:statement2];
    if (![db executeStatement:statement withBindings:bindings _error:nil]) {
        return FALSE;
    }
        
    NSString *statement3 = @"SELECT file_id FROM library WHERE path = ?1";
    NSDictionary *bindings2 = [NSDictionary dictionaryWithObject:[attributes objectForKey:[NSNumber numberWithInt:PRPathFileAttribute]] 
                                                          forKey:[NSNumber numberWithInt:1]];
    NSArray *result;
    if (![db executeStatement:statement3 withBindings:bindings2 result:&result _error:nil]) {
        return FALSE;
    }
    
    if  ([result count] == 1) {
        *file = [[result objectAtIndex:0] intValue];
    } else {
        return FALSE;
    }
    return TRUE;

}

- (BOOL)addFile:(PRFile *)file withPath:(NSString *)path _error:(NSError **)error
{
    NSArray *result;
    if (![db executeStatement:@"SELECT * FROM library WHERE path = ?1" 
                 withBindings:[NSDictionary dictionaryWithObject:path forKey:[NSNumber numberWithInt:1]]
                       result:&result
                       _error:nil]) {
        return FALSE;
    }
    if ([result count] > 0) {
        return FALSE;
    }
    if (![db executeStatement:@"INSERT INTO library (path) VALUES (?1)" 
                 withBindings:[NSDictionary dictionaryWithObject:path forKey:[NSNumber numberWithInt:1]] 
                       _error:nil]) {
        return FALSE;
    }
    NSArray *array;
    if (![db executeStatement:@"SELECT file_id FROM library WHERE path = :path" 
                 withBindings:[NSDictionary dictionaryWithObject:path forKey:[NSNumber numberWithInt:1]]  
                       result:&array
                       _error:nil]) {
        return FALSE;
    }
    
    if  ([array count] == 1) {
        *file = [[array objectAtIndex:0] intValue];
    } else {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)removeFiles:(NSIndexSet *)fileIndexes _error:(NSError **)error
{
    NSMutableString *stmtString = 
    [NSMutableString stringWithString:@"DELETE FROM library WHERE file_id IN ("];
    NSInteger file = [fileIndexes firstIndex];
    while (file != NSNotFound) {
        [stmtString appendString:[NSString stringWithFormat:@"%d, ", file]];
        file = [fileIndexes indexGreaterThanIndex:file];
        // delete album art
        [[db albumArtController] clearAlbumArtForFile:file];
    }
    [stmtString deleteCharactersInRange:NSMakeRange([stmtString length] - 2, 2)];
    [stmtString appendString:@")"];
    
    if (![db executeStatement:stmtString _error:error]) {
        return FALSE;
    }
    if (![self propagateFileDelete_error:error]) {
        return FALSE;
    }
    return TRUE;
}

- (BOOL)files:(NSIndexSet **)files withPath:(NSString *)path caseSensitive:(BOOL)caseSensitive _error:(NSError **)error
{
    if (caseSensitive) {
        return [self files:files withValue:path forAttribute:PRPathFileAttribute _error:nil];
    }
    NSString *statement = @"SELECT file_id FROM library WHERE path = ?1 COLLATE NOCASE";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              path, [NSNumber numberWithInt:1], nil];
    NSArray *result;
    if (![db executeStatement:statement
                 withBindings:bindings 
                       result:&result 
                       _error:nil]) {
        return FALSE;
    }
    
    NSMutableIndexSet *mutableFiles = [NSMutableIndexSet indexSet];
    if (result) {
        for (NSNumber *i in result) {
            [mutableFiles addIndex:[i intValue]];
        }
    }
    *files = [[[NSIndexSet alloc] initWithIndexSet:mutableFiles] autorelease];
    return TRUE;
}

- (BOOL)files:(NSIndexSet **)files withValue:(id)value forAttribute:(PRFileAttribute)attribute _error:(NSError **)error
{
    NSString *statement = [NSString stringWithFormat:@"SELECT file_id FROM library WHERE %@ = ?1", [[self class] columnNameForFileAttribute:attribute]];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              value, [NSNumber numberWithInt:1], nil];
    NSArray *result;
    if (![db executeStatement:statement
                 withBindings:bindings 
                       result:&result 
                       _error:nil]) {
        return FALSE;
    }
    
    NSMutableIndexSet *mutableFiles = [NSMutableIndexSet indexSet];
    if (result) {
        for (NSNumber *i in result) {
            [mutableFiles addIndex:[i intValue]];
        }
    }
    *files = [[[NSIndexSet alloc] initWithIndexSet:mutableFiles] autorelease];
    return TRUE;
}

- (BOOL)arrayOfUniqueValues:(NSArray **)array forAttribute:(PRFileAttribute)attr _error:(NSError **)error
{
    // array of files
    NSArray *result;
    NSString *attrString = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:attr]];
    NSString *statement = [NSString stringWithFormat:@"SELECT file_id FROM library GROUP BY %@ COLLATE NOCASE2", attrString];
    if ([db executeStatement:statement
                withBindings:nil 
                      result:&result 
                      _error:nil]) {
        return FALSE;
    }
    
    // array of values
    NSMutableArray *uniqueValues = [NSMutableArray array];
    for (NSNumber *file in result) {
        id arrayObject;
        [self value:&arrayObject forFile:[file intValue] attribute:attr _error:nil];
        if (arrayObject) {
			[uniqueValues addObject:arrayObject];
		}
    }
    
    *array  = [NSArray arrayWithArray:uniqueValues];
    return TRUE;	
}

- (BOOL)arrayOfFileIDsSortedByAlbumAndArtist:(NSArray **)array 
									  _error:(NSError **)error
{
    if ([db executeStatement:@"SELECT file_id FROM library "
         "ORDER BY artist COLLATE NOCASE2, album COLLATE NOCASE2"
                withBindings:nil
                      result:array 
                      _error:nil]) {
        return FALSE;
    }
    return TRUE;
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