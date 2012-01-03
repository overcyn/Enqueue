#import "PRLibraryViewSource.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRRule.h"
#import "PRUserDefaults.h"
#import "PRPlaylists+Extensions.h"

// ========================================
// Constants
// ========================================

NSString * const libraryViewSource = @"libraryViewSource";
NSString * const browser1ViewSource = @"browser1ViewSource";
NSString * const browser2ViewSource = @"browser2ViewSource";
NSString * const browser3ViewSource = @"browser3ViewSource";
NSString * const compilationString = @"Compilations  ";

@implementation PRLibraryViewSource

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_
{
	if (!(self = [super init])) {return nil;}
    db = db_;
    
    _compilation = TRUE;
    _prevSourceString = @"";
    _prevSourceBindings = [[NSDictionary alloc] init];
    prevBrowser1Bindings = [[NSDictionary alloc] init];
    prevBrowser2Bindings = [[NSDictionary alloc] init];
    prevBrowser3Bindings = [[NSDictionary alloc] init];
    _cachedSortIndexStatement = @"";
    _cachedBrowser1Statement = @"";
    _cachedBrowser2Statement = @"";
    _cachedBrowser3Statement = @"";
    _cachedValues = [[NSCache alloc] init];
    [_cachedValues setCountLimit:300];
	return self;
}

- (void)create
{
    
}

- (BOOL)initialize
{
    NSString *string;
    string = @"CREATE TEMP TABLE libraryViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "file_id INTEGER NOT NULL)";
    [db execute:string];
    
    string = @"CREATE TEMP TABLE browser1ViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [db execute:string];
    
    string = @"CREATE TEMP TABLE browser2ViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [db execute:string];
    
    string = @"CREATE TEMP TABLE browser3ViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [db execute:string];
    
    string = @"CREATE TEMP TABLE browserTempViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL,"
    "compilation INTEGER NOT NULL)";
    [db execute:string];
    
    string = @"CREATE TEMP TABLE browser1Cache "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [db execute:string];    
    
    string = @"CREATE TEMP TABLE browser2Cache "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [db execute:string];
    
    string = @"CREATE TEMP TABLE browser3Cache "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [db execute:string];
    return TRUE;
}

// ========================================
// Update
// ========================================

- (int)refreshWithPlaylist:(PRPlaylist)playlist force:(BOOL)force
{
    [_cachedValues removeAllObjects];
    _playlist = playlist;
    _force = force;
    
    int tables = 0;
    [self updateSortIndex];
    if ([self populateBrowser:1]) {
        tables = PRBrowser1View;
    }
    if ([self populateBrowser:2]) {
        tables = tables | PRBrowser2View;
    }
    if ([self populateBrowser:3]) {
        tables = tables | PRBrowser3View;
    }
    if ([self populateSource]) {
        tables = tables | PRLibraryView;
    }
	return tables;
}

- (BOOL)updateSortIndex
{
    if (_playlist != [[db playlists] libraryPlaylist] ) {
        return TRUE;
    }
    
    // Library view mode
	int libraryViewMode = [[db playlists] libraryViewModeForPlaylist:_playlist];
    int sortColumn;
	if (libraryViewMode == PRListMode) {
		sortColumn = [[db playlists] listViewSortColumnForPlaylist:_playlist];
	} else {
        sortColumn = [[db playlists] albumListViewSortColumnForPlaylist:_playlist];
	}
	
    // Sort column
    NSString *sortColumnName;
    if (sortColumn == PRPlaylistIndexSort) {
        [PRException raise:NSInternalInconsistencyException format:@"Invalid Sort Column"];return FALSE;
    } else if ([[PRUserDefaults userDefaults] useAlbumArtist] && sortColumn == PRArtistFileAttribute) {
        sortColumnName = @"artistAlbumArtist";
    } else {
        if (sortColumn == PRArtistAlbumSort) {
            if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
                sortColumn = PRArtistAlbumArtistFileAttribute;
            } else {
                sortColumn = PRArtistFileAttribute;
            }
        }
        sortColumnName = [PRLibrary columnNameForFileAttribute:sortColumn];
    }
    
    // Sort
    NSString *string = [NSString stringWithFormat:@"CREATE INDEX index_librarySort ON library "
                        "(%@ COLLATE NOCASE2, album COLLATE NOCASE2, discNumber COLLATE NOCASE2, trackNumber COLLATE NOCASE2, path COLLATE NOCASE2)", 
                        sortColumnName];
    if (![string isEqualToString:_cachedSortIndexStatement]) {
        [db execute:@"DROP INDEX IF EXISTS index_librarySort"];
        [db execute:string];
//        [db execute:@"ANALYZE"];
        [_cachedSortIndexStatement release];
        _cachedSortIndexStatement = [string retain];
    }
    
    // Cache browser 1
    NSString *grouping = [self groupingStringForPlaylist:_playlist browser:1];
    NSMutableString *stm = [NSMutableString stringWithFormat:@"INSERT INTO browser1Cache (value) "
                            "SELECT %@ FROM library WHERE %@ != '' COLLATE NOCASE2 ", grouping, grouping];
    if ([self compilationForBrowser:1]) {
        [stm appendFormat:@"AND compilation = 0 "];
    }
    [stm appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    if ([grouping length] > 0 && (![stm isEqualToString:_cachedBrowser1Statement] || _force)) {
        [db execute:@"DELETE FROM browser1Cache"];
        [db execute:stm];
        [_cachedBrowser1Statement release];
        _cachedBrowser1Statement = [stm retain];
    }
    
    // Cache browser 2
    grouping = [self groupingStringForPlaylist:_playlist browser:2];
    stm = [NSMutableString stringWithFormat:@"INSERT INTO browser2Cache (value) "
           "SELECT %@ FROM library WHERE %@ != '' COLLATE NOCASE2 ", grouping, grouping];
    if ([self compilationForBrowser:2]) {
        [stm appendFormat:@"AND compilation = 0 "];
    }
    [stm appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    if ([grouping length] > 0 && (![stm isEqualToString:_cachedBrowser2Statement] || _force)) {
        [db execute:@"DELETE FROM browser2Cache"];
        [db execute:stm];
        [_cachedBrowser2Statement release];
        _cachedBrowser2Statement = [stm retain];
    }
    
    // Cache browser 3
    grouping = [self groupingStringForPlaylist:_playlist browser:3];
    stm = [NSMutableString stringWithFormat:@"INSERT INTO browser3Cache (value) "
           "SELECT %@ FROM library WHERE %@ != '' COLLATE NOCASE2 ", grouping, grouping];
    if ([self compilationForBrowser:3]) {
        [stm appendFormat:@"AND compilation = 0 "];
    }
    [stm appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    if ([grouping length] > 0 && (![stm isEqualToString:_cachedBrowser3Statement] || _force)) {
        [db execute:@"DELETE FROM browser3Cache"];
        [db execute:stm];
        [_cachedBrowser3Statement release];
        _cachedBrowser3Statement = [stm retain];
    }
    
    // Cache Compilation
    NSArray *rlt = [db execute:@"SELECT file_id FROM library WHERE compilation != 0 LIMIT 1" bindings:nil columns:[NSArray arrayWithObject:PRColInteger]];
    _cachedCompilation = ([rlt count] != 0);
    return TRUE;
}

- (BOOL)populateSource
{
    BOOL whereTerm = FALSE;
	int bindingIndex = 1;
	NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSMutableString *string;
	if (_playlist == [[db playlists] libraryPlaylist]) {
		string = [NSMutableString stringWithFormat:
                  @"INSERT INTO libraryViewSource (file_id) "
                  "SELECT file_id "
                  "FROM library "
                  "WHERE "];
	} else {
		string = [NSMutableString stringWithFormat:
                  @"INSERT INTO libraryViewSource (file_id) "
                  "SELECT playlist_items.file_id "
                  "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                  "WHERE playlist_items.playlist_id = ?%d AND ",
                  bindingIndex];
		[bindings setObject:[NSNumber numberWithInt:_playlist] forKey:[NSNumber numberWithInt:bindingIndex]];
		bindingIndex++;
        whereTerm = TRUE;
	}
    
	/*
     // filter for rules
     NSData *data;
     PRRule *rule = nil;
     NSString *columnTitle;
     
     [play value:&data forPlaylist:playlist attribute:PRRulesPlaylistAttribute _error:nil];
     if (data) {
     rule = [NSKeyedUnarchiver unarchiveObjectWithData:data];
     }
     
     if (rule != nil && [[rule subRules] count] != 0 && [rule match]) {
     [stmtString appendString:@"AND (0 = 1 "];
     
     // for each subrule
     for (PRRule *subRule in [rule subRules]) {
     [stmtString appendString:@"OR (0 = 1 "];
     columnTitle = [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:[subRule fileAttribute]]];
     
     // for each selected in subrule
     for (id selected in [subRule selectedObjects]) {
     [stmtString appendString:[NSString stringWithFormat:@"OR ifnull(library.%@, '') = ?%d ", columnTitle, idx]];
     [bindingDictionary setObject:selected forKey:[NSNumber numberWithInt:idx]];
     idx++;
     }
     [stmtString appendString:@") "];
     }
     [stmtString appendString:@") "];
     }
     */
	
    // Filter for Column Browser
    for (int i = 1; i <= 3; i++) {
        NSString *grouping = [self groupingStringForPlaylist:_playlist browser:i];
        NSArray *selection = [[db playlists] selectionForBrowser:i playlist:_playlist];
        
        if ([selection count] != 0 && [grouping length] != 0) {
            whereTerm = TRUE;
            // copy rows from library_view_source into temp table that match selection
            [string appendFormat:@"(%@ COLLATE NOCASE2 IN (", grouping];
            for (NSString *i in selection) {
                [string appendFormat:@"?%d, ", bindingIndex];
                [bindings setObject:i forKey:[NSNumber numberWithInt:bindingIndex]];
                bindingIndex++;
            }
            [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
            [string appendString:@") "];
            
            if (_compilation && [self compilationForBrowser:i]) {
                if ([selection containsObject:compilationString]) {
                    [string appendString:@"OR library.compilation != 0 "];
                } else {
                    [string appendString:@"AND library.compilation == 0 "];
                }
            }
            
            [string appendString:@") AND "];
        }
    }
    
	// Search
	NSString *search = [[db playlists] searchForPlaylist:_playlist];
	if (search && [search length] != 0) {
        whereTerm = TRUE;
		[string appendString:@"(1 = 1 "];
		NSArray *searchTerms = [search componentsSeparatedByString:@" "];
		
		for (NSString *term in searchTerms) {
			[string appendString:[NSString stringWithFormat:@"AND (library.title LIKE ?%d "
                                  "OR library.album LIKE ?%d "
                                  "OR library.composer LIKE ?%d "
                                  "OR library.artist LIKE ?%d "
                                  "OR library.albumArtist LIKE ?%d "
                                  "OR library.comments LIKE ?%d "
                                  ") ", bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex]];
			
			[bindings setObject:[NSString stringWithFormat:@"%%%@%%",term] forKey:[NSNumber numberWithInt:bindingIndex]];
			bindingIndex++;
		}
		[string appendString:@") AND "];
	}
    
    if (whereTerm) {
        [string deleteCharactersInRange:NSMakeRange([string length] - 4, 4)];
    } else {
        [string deleteCharactersInRange:NSMakeRange([string length] - 6, 6)];
    }
    
    // Library view mode
	int libraryViewMode = [[db playlists] libraryViewModeForPlaylist:_playlist];
    int sortColumn;
    int asc;
	if (libraryViewMode == PRListMode) {
        sortColumn = [[db playlists] listViewSortColumnForPlaylist:_playlist];
        asc = [[db playlists] listViewAscendingForPlaylist:_playlist];
	} else {
        sortColumn = [[db playlists] albumListViewSortColumnForPlaylist:_playlist];
        asc = [[db playlists] albumListViewAscendingForPlaylist:_playlist];
	}
	
    // Sort column
    NSString *sortColumnName;
    if (sortColumn == PRPlaylistIndexSort) {
        sortColumnName = @"playlist_items.playlist_index";
    } else if ([[PRUserDefaults userDefaults] useAlbumArtist] && sortColumn == PRArtistFileAttribute) {
        sortColumnName = @"artistAlbumArtist";
    } else {
        if (sortColumn == PRArtistAlbumSort) {
            if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
                sortColumn = PRArtistAlbumArtistFileAttribute;
            } else {
                sortColumn = PRArtistFileAttribute;
            }
        }
        sortColumnName = [PRLibrary columnNameForFileAttribute:sortColumn];
    }
    
    // Sort
    NSString *ascending;
	if (asc) {
		ascending = @"ASC";
	} else {
		ascending = @"DESC";
	}
    [string appendFormat:@"ORDER BY %@ COLLATE NOCASE2 %@, album COLLATE NOCASE2 %@, discNumber COLLATE NOCASE2 %@, trackNumber COLLATE NOCASE2 %@, path COLLATE NOCASE2 %@ ", 
     sortColumnName, ascending, ascending, ascending, ascending, ascending];
    
    if (!_force &&
        [string isEqualToString:_prevSourceString] &&
        [bindings isEqualToDictionary:_prevSourceBindings]) {
        return FALSE;
    }
    [_prevSourceString release];
    [_prevSourceBindings release];
    _prevSourceString = [string retain];
    _prevSourceBindings = [bindings retain];
    
    // Delete all items from library1ViewSource
    [db execute:@"DELETE FROM libraryViewSource"];
    
	// Execute
    [db execute:string bindings:bindings columns:nil];
    return TRUE;
}

- (BOOL)populateBrowser:(int)browser
{
    NSString *cacheTableName;
	NSString *destinationTableName;
    NSString **prevBrowserStatement;
    NSDictionary **prevBrowserBindings;
	if (browser == 1) {
        cacheTableName = @"browser1Cache";
        destinationTableName = browser1ViewSource;
        prevBrowserStatement = &prevBrowser1Statement;
        prevBrowserBindings = &prevBrowser1Bindings;
	} else if (browser == 2) {
        cacheTableName = @"browser2Cache";
        destinationTableName = browser2ViewSource;
        prevBrowserStatement = &prevBrowser2Statement;
        prevBrowserBindings = &prevBrowser2Bindings;
	} else if (browser == 3) {
        cacheTableName = @"browser3Cache";
        destinationTableName = browser3ViewSource;
        prevBrowserStatement = &prevBrowser3Statement;
        prevBrowserBindings = &prevBrowser3Bindings;
	} else {
        return FALSE;
    }
    
    // Do nothing if no grouping
    NSString *grouping = [self groupingStringForPlaylist:_playlist browser:browser];
	if ([grouping length] == 0) {
        [*prevBrowserStatement release];
        [*prevBrowserBindings release];
        *prevBrowserStatement = [@"" retain];
        *prevBrowserBindings = [[NSDictionary dictionary] retain];
		return TRUE;
	}
    
    // Populate browser
    BOOL useCache = TRUE;
    int bindingIndex = 1;
	NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSMutableString *statement;
	if (_playlist == [[db playlists] libraryPlaylist]) {
		statement = [NSMutableString stringWithFormat:
                     @"INSERT INTO browserTempViewSource (value, compilation) SELECT %@, compilation FROM library WHERE ",
                     grouping];
	} else {
		statement = [NSMutableString stringWithFormat:
                     @"INSERT INTO browserTempViewSource (value, compilation) SELECT library.%@, library.compilation "
                     "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                     "WHERE playlist_items.playlist_id = ?%d AND ",
                     grouping, bindingIndex];
		[bindings setObject:[NSNumber numberWithInt:_playlist] forKey:[NSNumber numberWithInt:bindingIndex]];
		bindingIndex++;
	}
    
    // Filter for other browsers
    for (int i = 1; i < browser; i++) {
        NSString *grouping = [self groupingStringForPlaylist:_playlist browser:i];
        NSArray *selection = [[db playlists] selectionForBrowser:i playlist:_playlist];
        
        if ([selection count] != 0 && [grouping length] != 0) {
            // copy rows from library_view_source into temp table that match selection
            [statement appendFormat:@"(%@ COLLATE NOCASE2 IN (", grouping];
            for (NSString *i in selection) {
                [statement appendFormat:@"?%d, ", bindingIndex];
                [bindings setObject:i forKey:[NSNumber numberWithInt:bindingIndex]];
                bindingIndex++;
            }
            [statement deleteCharactersInRange:NSMakeRange([statement length] - 2, 2)];
            [statement appendString:@") "];
            
            if (_compilation && [self compilationForBrowser:i]) {
                if ([selection containsObject:compilationString]) {
                    [statement appendString:@"OR library.compilation != 0 "];
                } else {
                    [statement appendString:@"AND library.compilation == 0 "];
                }
            }
            
            [statement appendString:@") AND "];
            useCache = FALSE;
        }
    }
    
	// Filter for search
	NSString *search = [[db playlists] searchForPlaylist:_playlist];
	if (search && [search length] != 0) {
		[statement appendString:@"(1 = 1 "];
		NSArray *searchTerms = [search componentsSeparatedByString:@" "];
		
		for (NSString *term in searchTerms) {
            [statement appendString:[NSString stringWithFormat:@"AND (library.title LIKE ?%d "
                                     "OR library.album LIKE ?%d "
                                     "OR library.composer LIKE ?%d "
                                     "OR library.artist LIKE ?%d "
                                     "OR library.albumArtist LIKE ?%d "
                                     "OR library.comments LIKE ?%d "
                                     ") ", bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex]];
			
			[bindings setObject:[NSString stringWithFormat:@"%%%@%%",term] forKey:[NSNumber numberWithInt:bindingIndex]];
			bindingIndex++;
		}
		[statement appendString:@") AND "];
        useCache = FALSE;
	}
    
    // Filter for empty
    [statement appendFormat:@"%@ != '' COLLATE NOCASE2 ", grouping];
    
    // Sort
    if ([self compilationForBrowser:browser]) {
        [statement appendFormat:@"GROUP BY compilation, %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    } else {
        [statement appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    }
    
    
    if (!_force &&
        [statement isEqualToString:*prevBrowserStatement] &&
        [bindings isEqualToDictionary:*prevBrowserBindings]) {
        return FALSE;
    }
    [*prevBrowserStatement release];
    [*prevBrowserBindings release];
    *prevBrowserStatement = [statement retain];
    *prevBrowserBindings = [bindings retain];
    
	// Execute
    if (useCache && _playlist == [[db playlists] libraryPlaylist]) {
        [db execute:[NSString stringWithFormat:@"DELETE FROM %@", destinationTableName]];
        [db execute:[NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM %@ ORDER BY row", destinationTableName, cacheTableName]];
        _compilation = _cachedCompilation;
    } else {
        [db execute:@"DELETE FROM browserTempViewSource"];
        [db execute:statement bindings:bindings columns:nil];
        [db execute:[NSString stringWithFormat:@"DELETE FROM %@", destinationTableName]];
        if ([self compilationForBrowser:browser]) {
            [db execute:[NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM browserTempViewSource WHERE compilation = 0 ORDER BY row", destinationTableName]];
        } else {
            [db execute:[NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM browserTempViewSource ORDER BY row", destinationTableName]];
        }
        
        if ([self compilationForBrowser:browser]) {
            NSArray *rlt = [db execute:@"SELECT compilation FROM browserTempViewSource WHERE compilation != 0 LIMIT 1" 
                              bindings:nil 
                               columns:[NSArray arrayWithObject:PRColInteger]];
            _compilation = ([rlt count] != 0);
        }
    }
    
    // Reset if nothing
    NSMutableArray *selection = [NSMutableArray arrayWithArray:[[db playlists] selectionForBrowser:browser playlist:_playlist]];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    for (int i = 0; i < [selection count]; i++) {
        NSArray *results = [db execute:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE value COLLATE NOCASE2 = ?1", destinationTableName]
                              bindings:[NSDictionary dictionaryWithObjectsAndKeys:[selection objectAtIndex:i], [NSNumber numberWithInt:1], nil]
                               columns:[NSArray arrayWithObject:PRColInteger]];
        if ([[[results objectAtIndex:0] objectAtIndex:0] intValue] == 0) {
            [indexesToRemove addIndex:i];
        }
    }
    if ([indexesToRemove count] > 0) {
        [selection removeObjectsAtIndexes:indexesToRemove];
        [[db playlists] setSelection:[NSArray arrayWithArray:selection] forBrowser:browser playlist:_playlist];
    }
	return TRUE;
}

// ========================================
// Library Accessors
// ========================================

- (int)count
{
    NSArray *rlt = [db execute:@"SELECT COUNT(*) FROM libraryViewSource"
                      bindings:nil 
                       columns:[NSArray arrayWithObject:PRColInteger]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@""];}
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRFile)fileForRow:(int)row
{
    NSArray *rlt = [db execute:@"SELECT file_id FROM libraryViewSource WHERE row = ?1"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil] 
                       columns:[NSArray arrayWithObject:PRColInteger]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@""];}
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (int)rowForFile:(PRFile)file
{
    NSArray *rlt = [db execute:@"SELECT row FROM libraryViewSource WHERE file_id = ?1"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil] 
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    if ([rlt count] > 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    } else if ([rlt count] == 0) {
        return -1;
    }
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (id)valueForRow:(int)row attribute:(PRFileAttribute)attribute andCacheAttributes:(NSArray *)attributes
{
    id cachedValue = [[_cachedValues objectForKey:[NSNumber numberWithInt:row]] objectForKey:[NSNumber numberWithInt:attribute]];
    if (cachedValue) {
        return cachedValue;
    }
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT "];
    for (NSNumber *i in attributes) {
        [string appendFormat:@"library.%@, ", [[PRLibrary class] columnNameForFileAttribute:[i intValue]]];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
    [string appendString:@" FROM libraryViewSource "
     "JOIN library ON libraryViewSource.file_id = library.file_id WHERE row = ?1"];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil];
    NSMutableArray *columns = [NSMutableArray array];
    for (NSNumber *i in attributes) {
        [columns addObject:[[PRLibrary columnForAttribute] objectForKey:i]];
    }
    NSArray *result = [db execute:string bindings:bindings columns:columns];
    
    NSMutableDictionary *valuesToCache = [NSMutableDictionary dictionary];
    for (int i = 0; i < [attributes count]; i++) {
        [valuesToCache setObject:[[result objectAtIndex:0] objectAtIndex:i] 
                          forKey:[attributes objectAtIndex:i]];
    }
    [_cachedValues setObject:valuesToCache forKey:[NSNumber numberWithInt:row]];
    return [valuesToCache objectForKey:[NSNumber numberWithInt:attribute]];
}

- (NSDictionary *)info
{
    NSArray *rlt = [db execute:@"SELECT SUM(time), SUM(size), count(libraryViewSource.file_id) "
                    "FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id"
                      bindings:nil
                       columns:[NSArray arrayWithObjects:PRColInteger, PRColInteger, PRColInteger, nil]];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [[rlt objectAtIndex:0] objectAtIndex:0], @"time",
                          [[rlt objectAtIndex:0] objectAtIndex:1], @"size",
                          [[rlt objectAtIndex:0] objectAtIndex:2], @"count", nil];
    return info;
}

- (NSArray *)albumCounts
{
    NSArray *results = [db execute:@"SELECT library.album FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id" 
                          bindings:nil 
                           columns:[NSArray arrayWithObject:PRColString]];
    
    if ([results count] == 0) {
        return [NSArray array];
    } else if ([results count] == 1) {
        return [NSArray arrayWithObject:[NSNumber numberWithInt:1]];
    }
    
    NSMutableArray *array = [NSMutableArray array];
    int count = 1;
    int i = 0;
    while (i < [results count] - 1) {
        NSString *string = [[results objectAtIndex:i] objectAtIndex:0];
        NSString *nextString = [[results objectAtIndex:i + 1] objectAtIndex:0];
        if ([string noCaseCompare:nextString]) {
            [array addObject:[NSNumber numberWithInt:count]];
            count = 0;
        }
        count++;
        i++;
    }
    [array addObject:[NSNumber numberWithInt:count]];
    return array;
}

// ========================================
// Browser Accessors
// ========================================

- (int)countForBrowser:(int)browser
{
    if ([[db playlists] attributeForBrowser:browser playlist:_playlist] == 0) {
        return 0;
    }
    
    NSArray *rlt = [db execute:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", [self tableNameForBrowser:browser]]
                      bindings:nil 
                       columns:[NSArray arrayWithObject:PRColInteger]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@""];}
    
    int count = [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
    if ([self compilationForBrowser:browser] && _compilation) {
        count += 1;
    }
    return count;
}

- (NSString *)valueForRow:(int)row browser:(int)browser
{
    if ([self compilationForBrowser:browser] && _compilation) {
        if (row == 1) {
            return compilationString;
        }
        row -= 1;
    }
    
    NSArray *rlt = [db execute:[NSString stringWithFormat:@"SELECT value FROM %@ WHERE row = ?1", [self tableNameForBrowser:browser]]
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObjects:PRColString, nil]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@"row:%d browser:%d",row, browser];}
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (NSIndexSet *)selectionForBrowser:(int)browser
{
    NSArray *selectionArray = [[db playlists] selectionForBrowser:browser playlist:_playlist];
    if ([selectionArray count] == 0) {
        return [NSIndexSet indexSetWithIndex:0];
	}
    
    NSString *browserTableName = [self tableNameForBrowser:browser];
	NSMutableString *string = [NSMutableString stringWithFormat:@"SELECT row FROM %@ WHERE value IN (", browserTableName];
	for (NSString *i in selectionArray) {
		[string appendString:@"?, "];
	}
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
	[string appendString:@")"];
    
    NSMutableDictionary *bnd = [NSMutableDictionary dictionary];
    for (int i = 0; i < [selectionArray count]; i++) {
        [bnd setObject:[selectionArray objectAtIndex:i] forKey:[NSNumber numberWithInt:i + 1]];
    }
    NSArray *rlt = [db execute:string 
                      bindings:bnd 
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSArray *i in rlt) {
        int index = [[i objectAtIndex:0] intValue];
        if ([self compilationForBrowser:browser] && _compilation) {
            index += 1;
        }
        [indexSet addIndex:index];
    }
    if ([indexSet count] == 0) {
        [indexSet addIndex:0];
    }
    return indexSet;
}

- (BOOL)compilation
{
    return _compilation;
}

// ========================================
// Misc
// ========================================

- (int)firstRowWithValue:(id)value forAttribute:(PRFileAttribute)attribute
{
    NSString *stm = [NSString stringWithFormat:@"SELECT row FROM libraryViewSource "
                     "JOIN library ON libraryViewSource.file_id = library.file_id WHERE %@ = ?1 COLLATE NOCASE2 "
                     "ORDER BY row LIMIT 1", 
                     [PRLibrary columnNameForFileAttribute:attribute]];
    NSDictionary *bnd = [NSDictionary dictionaryWithObjectsAndKeys:value, [NSNumber numberWithInt:1], nil];
    NSArray *col = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *rlt = [db execute:stm bindings:bnd columns:col];
    if ([rlt count] == 0) {
        return -1;
    }
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (BOOL)compilationForBrowser:(int)browser
{
    return ([[db playlists] attributeForBrowser:browser playlist:_playlist] == PRArtistFileAttribute && [[PRUserDefaults userDefaults] useCompilation]);
}

- (NSString *)tableNameForBrowser:(int)browser
{
	if (browser == 1) {
		return browser1ViewSource;
	} else if (browser == 2) {
		return browser2ViewSource;
	} else if (browser == 3) {
		return browser3ViewSource;
	} else {
		NSLog(@"PRLibraryViewSource refreshBrowser:withPlaylist:_error: Unknown Browser");
		return @"";
	}
}

- (NSString *)groupingStringForPlaylist:(PRPlaylist)playlist browser:(int)browser
{
    int grouping = [[db playlists] attributeForBrowser:browser playlist:playlist];
    if (grouping == 0) {
        return @"";
    }
    if ([[PRUserDefaults userDefaults] useAlbumArtist] && grouping == PRArtistFileAttribute) {
		return @"artistAlbumArtist";
	}
    return [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:grouping]];
}

@end