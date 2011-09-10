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

@implementation PRLibraryViewSource

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_
{
    self = [super init];
	if (self) {
		db = db_;
		play = [db playlists];
        
        _prevSourceString = [@"" retain];
        _prevSourceBindings = [[NSDictionary dictionary] retain];
        prevBrowser1Bindings = [@"" retain];
        prevBrowser1Bindings = [[NSDictionary dictionary] retain];
        prevBrowser2Bindings = [@"" retain];
        prevBrowser2Bindings = [[NSDictionary dictionary] retain];
        prevBrowser3Bindings = [@"" retain];
        prevBrowser3Bindings = [[NSDictionary dictionary] retain];
        _prevSort = [@"" retain];
        _prevBrowser1Grouping = [@"" retain];
        _prevBrowser2Grouping = [@"" retain];
        _prevBrowser3Grouping = [@"" retain];
        _cachedValues = [[NSCache alloc] init];
        [_cachedValues setCountLimit:300];
	}
	return self;
}

- (void)create
{

}

- (BOOL)initialize
{	
    NSString *string = @"CREATE TEMP TABLE libraryViewSource "
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
        tables = tables | PRBrowser1View;
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
        [PRException raise:NSInternalInconsistencyException format:@"Invalid Sort Column"];
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
    if (![string isEqualToString:_prevSort]) {
        [db execute:@"DROP INDEX IF EXISTS index_librarySort"];
        [db execute:string];
        [db execute:@"ANALYZE"];
        [_prevSort release];
        _prevSort = [string retain];
    }
    
    // Cache browser 1
    NSString *grouping = [self groupingStringForPlaylist:_playlist browser:1];
    string = [NSString stringWithFormat:@"INSERT INTO browser1Cache (value) "
                 "SELECT %@ FROM library WHERE "
                 "%@ != '' COLLATE NOCASE2 "
                 "GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", 
                 grouping, grouping, grouping, grouping];
    if ([grouping length] > 0 && (![string isEqualToString:_prevBrowser1Grouping] || _force)) {
        [db execute:@"DELETE FROM browser1Cache"];
        [db execute:string];
        [_prevBrowser1Grouping release];
        _prevBrowser1Grouping = [string retain];
    }
    
    // Cache browser 2
    grouping = [self groupingStringForPlaylist:_playlist browser:2];
    string = [NSString stringWithFormat:@"INSERT INTO browser2Cache (value) "
                 "SELECT %@ FROM library WHERE "
                 "%@ != '' COLLATE NOCASE2 "
                 "GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", 
                 grouping, grouping, grouping, grouping];
    if ([grouping length] > 0 && (![string isEqualToString:_prevBrowser2Grouping] || _force)) {
        [db execute:@"DELETE FROM browser2Cache"];
        [db execute:string];
        [_prevBrowser2Grouping release];
        _prevBrowser2Grouping = [string retain];
    }
    
    // Cache browser 3
    grouping = [self groupingStringForPlaylist:_playlist browser:3];
    string = [NSString stringWithFormat:@"INSERT INTO browser3Cache (value) "
                 "SELECT %@ FROM library WHERE "
                 "%@ != '' COLLATE NOCASE2 "
                 "GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", 
                 grouping, grouping, grouping, grouping];
    if ([grouping length] > 0 && (![string isEqualToString:_prevBrowser3Grouping] || _force)) {
        [db execute:@"DELETE FROM browser3Cache"];
        [db execute:string];
        [_prevBrowser3Grouping release];
        _prevBrowser3Grouping = [string retain];
    }
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
            [string appendFormat:@"%@ COLLATE NOCASE2 IN (", grouping];
            for (NSString *i in selection) {
                [string appendFormat:@"?%d, ", bindingIndex];
                [bindings setObject:i forKey:[NSNumber numberWithInt:bindingIndex]];
                bindingIndex++;
            }
            [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
            [string appendString:@") AND "];
        }
    }
    
	// filter for search
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
                     @"INSERT INTO %@ (value) "
                     "SELECT %@ "
                     "FROM library "
                     "WHERE ",
                     destinationTableName, grouping];
	} else {
		statement = [NSMutableString stringWithFormat:
                     @"INSERT INTO %@ (value) "
                     "SELECT %@ "
                     "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                     "WHERE playlist_items.playlist_id = ?%d AND ",
                     destinationTableName,
                     grouping,
                     bindingIndex];
		[bindings setObject:[NSNumber numberWithInt:_playlist] forKey:[NSNumber numberWithInt:bindingIndex]];
		bindingIndex++;
	}
    
  	/*
     // Filter for rules
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
	
    // Filter for other browsers
    for (int i = 1; i < browser; i++) {
        NSString *grouping = [self groupingStringForPlaylist:_playlist browser:i];
        NSArray *selection = [[db playlists] selectionForBrowser:i playlist:_playlist];
        
        if ([selection count] != 0 && [grouping length] != 0) {
            // copy rows from library_view_source into temp table that match selection
            [statement appendFormat:@"%@ COLLATE NOCASE2 IN (", grouping];
            for (NSString *i in selection) {
                [statement appendFormat:@"?%d, ", bindingIndex];
                [bindings setObject:i forKey:[NSNumber numberWithInt:bindingIndex]];
                bindingIndex++;
            }
            [statement deleteCharactersInRange:NSMakeRange([statement length] - 2, 2)];
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
    [statement appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    
    if (!_force &&
        [statement isEqualToString:*prevBrowserStatement] &&
        [bindings isEqualToDictionary:*prevBrowserBindings]) {
        return FALSE;
    }
    [*prevBrowserStatement release];
    [*prevBrowserBindings release];
    *prevBrowserStatement = [statement retain];
    *prevBrowserBindings = [bindings retain];
    
    // Delete all items from browser
    NSString *string = [NSString stringWithFormat:@"DELETE FROM %@", destinationTableName];
    [db execute:string];
    
	// Execute
    if (useCache && _playlist == [play libraryPlaylist]) {
        statement = [NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM %@ ORDER BY row", destinationTableName, cacheTableName];
        bindings = nil;
    }
    [db execute:statement bindings:bindings columns:nil];
    
    NSMutableArray *selection = [NSMutableArray arrayWithArray:[[db playlists] selectionForBrowser:browser playlist:_playlist]];
    NSMutableIndexSet *indexesToRemove = [[[NSMutableIndexSet alloc] init] autorelease];
    for (int i = 0; i < [selection count]; i++) {
        string = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE value COLLATE NOCASE2 = ?1", destinationTableName];
        bindings = [NSDictionary dictionaryWithObject:[selection objectAtIndex:i] forKey:[NSNumber numberWithInt:1]];
        NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
        NSArray *results = [db execute:string bindings:bindings columns:columns];
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
// Accessors
// ========================================

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

- (int)count
{
    NSString *string = @"SELECT COUNT(*) FROM libraryViewSource";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *result = [db execute:string bindings:nil columns:columns];
    if ([result count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[result objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRFile)fileForRow:(int)row
{
    NSString *string = @"SELECT file_id FROM libraryViewSource WHERE row = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (id)valueForRow:(int)row attribute:(PRFileAttribute)attribute andCacheAttributes:(NSArray *)attributes;
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

- (int)rowForFile:(PRFile)file
{
    NSString *string = @"SELECT row FROM libraryViewSource WHERE file_id = ?1";
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    if ([results count] > 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    } else if ([results count] == 0) {
        return -1;
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (int)countForBrowser:(int)browser
{
    NSString *string = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", [self tableNameForBrowser:browser]];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[[results objectAtIndex:0] objectAtIndex:0] intValue];
}

- (NSString *)valueForRow:(int)row browser:(int)browser
{
    NSString *string = [NSString stringWithFormat:@"SELECT value FROM %@ WHERE row = ?1", [self tableNameForBrowser:browser]];
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    if ([results count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[results objectAtIndex:0] objectAtIndex:0];
}

- (NSIndexSet *)selectionForBrowser:(int)browser
{
    NSArray *selectionArray = [[db playlists] selectionForBrowser:browser playlist:_playlist];
    if ([selectionArray count] == 0) {
        return [NSIndexSet indexSetWithIndex:0];
	}
    
    NSString *browserTableName = [self tableNameForBrowser:browser];
	NSMutableString *string = [NSMutableString stringWithFormat:@"SELECT %@.row FROM %@ WHERE value IN (", 
                               browserTableName, browserTableName, browserTableName];
	for (NSString *i in selectionArray) {
		[string appendString:@"?, "];
	}
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
	[string appendString:@")"];
    
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    for (int i = 0; i < [selectionArray count]; i++) {
        [bindings setObject:[selectionArray objectAtIndex:i] forKey:[NSNumber numberWithInt:i + 1]];
    }
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSArray *i in results) {
        [indexSet addIndex:[[i objectAtIndex:0] intValue]];
    }
    if ([indexSet count] == 0) {
        [indexSet addIndex:0];
    }
    return indexSet;
}

- (NSDictionary *)info
{
    NSString *string = @"SELECT SUM(time), SUM(size), count(libraryViewSource.file_id) "
    "FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id";
    NSArray *columns = [NSArray arrayWithObjects:
                        [NSNumber numberWithInt:PRColumnInteger], 
                        [NSNumber numberWithInt:PRColumnInteger], 
                        [NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [[results objectAtIndex:0] objectAtIndex:0], @"time",
                          [[results objectAtIndex:0] objectAtIndex:1], @"size",
                          [[results objectAtIndex:0] objectAtIndex:2], @"count", nil];
    return info;
}

- (NSArray *)albumCounts
{
    NSString *string = @"SELECT library.album FROM libraryViewSource "
    "JOIN library ON libraryViewSource.file_id = library.file_id";
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    
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

@end