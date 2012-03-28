#import "PRLibraryViewSource.h"
#import "PRDb.h"
#import "PRLibraryViewController.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRStatement.h"
#import "PRUserDefaults.h"


NSString * const libraryViewSource = @"libraryViewSource";
NSString * const browser1ViewSource = @"browser1ViewSource";
NSString * const browser2ViewSource = @"browser2ViewSource";
NSString * const browser3ViewSource = @"browser3ViewSource";
NSString * const compilationString = @"Compilations  ";


@interface PRLibraryViewSource ()
/* Update Priv */
- (BOOL)updateSortIndex;
- (BOOL)populateSource;
- (BOOL)populateBrowser:(int)browser;

/* Priv */
- (BOOL)compilationForBrowser:(int)browser;
- (NSString *)tableNameForBrowser:(int)browser;
- (NSString *)groupingStringForList:(PRList *)list browser:(int)browser;
@end


@implementation PRLibraryViewSource

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db {
	if (!(self = [super init])) {return nil;}
    _db = db;
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
	return self;
}

- (void)create {
    
}

- (BOOL)initialize {
    NSString *string;
    string = @"CREATE TEMP TABLE libraryViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "file_id INTEGER NOT NULL)";
    [_db execute:string];
    
    string = @"CREATE TEMP TABLE browser1ViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [_db execute:string];
    
    string = @"CREATE TEMP TABLE browser2ViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [_db execute:string];
    
    string = @"CREATE TEMP TABLE browser3ViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [_db execute:string];
    
    string = @"CREATE TEMP TABLE browserTempViewSource "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL,"
    "compilation INTEGER NOT NULL)";
    [_db execute:string];
    
    string = @"CREATE TEMP TABLE browser1Cache "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [_db execute:string];    
    
    string = @"CREATE TEMP TABLE browser2Cache "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [_db execute:string];
    
    string = @"CREATE TEMP TABLE browser3Cache "
    "(row INTEGER NOT NULL PRIMARY KEY, "
    "value TEXT NOT NULL)";
    [_db execute:string];
    return TRUE;
}

- (void)dealloc {
    [_list release];
    [_prevSourceString release];
    [_prevSourceBindings release];
    [prevBrowser1Statement release];
    [prevBrowser1Bindings release];
    [prevBrowser2Statement release];
    [prevBrowser2Bindings release];
    [prevBrowser3Statement release];
    [prevBrowser3Bindings release];
    [_cachedSortIndexStatement release];
    [_cachedBrowser1Statement release];
    [_cachedBrowser2Statement release];
    [_cachedBrowser3Statement release];
    [_cachedAttrs release];
    [_cachedAttrValues release];
    [_cachedStatement release];
    [super dealloc];
}

// ========================================
// Update

- (int)refreshWithList:(PRList *)list force:(BOOL)force {
    [_cachedAttrValues release];
    _cachedAttrValues = nil;
    [_list release];
    _list = [list retain];
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

// ========================================
// Update Priv

- (BOOL)updateSortIndex {
    if (![_list isEqual:[[_db playlists] libraryList]]) {
        return TRUE;
    }
    
    // Library view mode
	int libraryViewMode = [[_db playlists] viewModeForList:_list];
    PRListSort *listSort;
	if (libraryViewMode == PRListMode) {
		listSort = [[_db playlists] listViewSortAttrForList:_list];
	} else {
        listSort = [[_db playlists] albumListViewSortAttrForList:_list];
	}
	if ([listSort isEqual:PRListSortIndex]) {
        listSort = PRListSortArtistAlbum;
    }
    
    // Sort column
    NSString *sortColumnName;
    if ([listSort isEqual:PRListSortIndex]) {
        @throw NSInvalidArgumentException;
    } else if ([[PRUserDefaults userDefaults] useAlbumArtist] && [listSort isEqual:PRItemAttrArtist]) {
        sortColumnName = @"artistAlbumArtist";
    } else {
        if ([listSort isEqual:PRListSortArtistAlbum]) {
            if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
                listSort = PRItemAttrArtistAlbumArtist;
            } else {
                listSort = PRItemAttrArtist;
            }
        }
        sortColumnName = [PRPlaylists columnNameForSortAttr:listSort];
    }
    
    // Sort
    NSString *string = [NSString stringWithFormat:@"CREATE INDEX index_librarySort ON library "
                        "(%@ COLLATE NOCASE2, album COLLATE NOCASE2, discNumber COLLATE NOCASE2, trackNumber COLLATE NOCASE2, path COLLATE NOCASE2)", 
                        sortColumnName];
    if (![string isEqualToString:_cachedSortIndexStatement]) {
        [_db execute:@"DROP INDEX IF EXISTS index_librarySort"];
        [_db execute:string];
        [_cachedSortIndexStatement release];
        _cachedSortIndexStatement = [string retain];
    }
    
    // Cache browser 1
    NSString *grouping = [self groupingStringForList:_list browser:1];
    NSMutableString *stm = [NSMutableString stringWithFormat:@"INSERT INTO browser1Cache (value) "
                            "SELECT %@ FROM library WHERE %@ != '' COLLATE NOCASE2 ", grouping, grouping];
    if ([self compilationForBrowser:1]) {
        [stm appendFormat:@"AND compilation = 0 "];
    }
    [stm appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    if ([grouping length] > 0 && (![stm isEqualToString:_cachedBrowser1Statement] || _force)) {
        [_db execute:@"DELETE FROM browser1Cache"];
        [_db execute:stm];
        [_cachedBrowser1Statement release];
        _cachedBrowser1Statement = [stm retain];
    }
    
    // Cache browser 2
    grouping = [self groupingStringForList:_list browser:2];
    stm = [NSMutableString stringWithFormat:@"INSERT INTO browser2Cache (value) "
           "SELECT %@ FROM library WHERE %@ != '' COLLATE NOCASE2 ", grouping, grouping];
    if ([self compilationForBrowser:2]) {
        [stm appendFormat:@"AND compilation = 0 "];
    }
    [stm appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    if ([grouping length] > 0 && (![stm isEqualToString:_cachedBrowser2Statement] || _force)) {
        [_db execute:@"DELETE FROM browser2Cache"];
        [_db execute:stm];
        [_cachedBrowser2Statement release];
        _cachedBrowser2Statement = [stm retain];
    }
    
    // Cache browser 3
    grouping = [self groupingStringForList:_list browser:3];
    stm = [NSMutableString stringWithFormat:@"INSERT INTO browser3Cache (value) "
           "SELECT %@ FROM library WHERE %@ != '' COLLATE NOCASE2 ", grouping, grouping];
    if ([self compilationForBrowser:3]) {
        [stm appendFormat:@"AND compilation = 0 "];
    }
    [stm appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    if ([grouping length] > 0 && (![stm isEqualToString:_cachedBrowser3Statement] || _force)) {
        [_db execute:@"DELETE FROM browser3Cache"];
        [_db execute:stm];
        [_cachedBrowser3Statement release];
        _cachedBrowser3Statement = [stm retain];
    }
    
    // Cache Compilation
    NSArray *rlt = [_db execute:@"SELECT file_id FROM library WHERE compilation != 0 LIMIT 1" bindings:nil columns:[NSArray arrayWithObject:PRColInteger]];
    _cachedCompilation = ([rlt count] != 0);
    return TRUE;
}

- (BOOL)populateSource {
    BOOL whereTerm = FALSE;
	int bindingIndex = 1;
	NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSMutableString *string;
	if ([_list isEqual:[[_db playlists] libraryList]]) {
		string = [NSMutableString stringWithFormat:
                  @"INSERT INTO libraryViewSource (file_id) "
                  "SELECT file_id FROM library WHERE "];
	} else {
		string = [NSMutableString stringWithFormat:
                  @"INSERT INTO libraryViewSource (file_id) "
                  "SELECT playlist_items.file_id "
                  "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                  "WHERE playlist_items.playlist_id = ?%d AND ",
                  bindingIndex];
		[bindings setObject:_list forKey:[NSNumber numberWithInt:bindingIndex]];
		bindingIndex++;
        whereTerm = TRUE;
	}
	
    // Filter for Column Browser
    for (int i = 1; i <= 3; i++) {
        NSString *grouping = [self groupingStringForList:_list browser:i];
        NSArray *selection = [[_db playlists] selectionForBrowser:i list:_list];
        
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
	NSString *search = [[_db playlists] searchForList:_list];
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
	int libraryViewMode = [[_db playlists] viewModeForList:_list];
    PRListSort *sort;
    int asc;
	if (libraryViewMode == PRListMode) {
        sort = [[_db playlists] listViewSortAttrForList:_list];
        asc = [[_db playlists] listViewAscendingForList:_list];
	} else {
        sort = [[_db playlists] albumListViewSortAttrForList:_list];
        asc = [[_db playlists] albumListViewAscendingForList:_list];
	}
	
    // Sort column
    NSString *sortColumnName;
    if ([sort isEqual:PRListSortIndex]) {
        sortColumnName = @"playlist_items.playlist_index";
    } else if ([[PRUserDefaults userDefaults] useAlbumArtist] && [sort isEqual:PRItemAttrArtist]) {
        sortColumnName = @"artistAlbumArtist";
    } else {
        if ([sort isEqual:PRListSortArtistAlbum]) {
            if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
                sort = PRItemAttrArtistAlbumArtist;
            } else {
                sort = PRItemAttrArtist;
            }
        }
        sortColumnName = [PRLibrary columnNameForItemAttr:sort];
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
    [_db execute:@"DELETE FROM libraryViewSource"];
    
	// Execute
    [_db execute:string bindings:bindings columns:nil];
    return TRUE;
}

- (BOOL)populateBrowser:(int)browser {
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
        @throw NSInvalidArgumentException;
    }
    
    // Do nothing if no grouping
    NSString *grouping = [self groupingStringForList:_list browser:browser];
	if ([grouping length] == 0) {
        [*prevBrowserStatement release];
        [*prevBrowserBindings release];
        *prevBrowserStatement = [@"" retain];
        *prevBrowserBindings = [[NSDictionary alloc] init];
		return TRUE;
	}
    
    // Populate browser
    BOOL useCache = TRUE;
    int bindingIndex = 1;
	NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSMutableString *statement;
	if ([_list isEqual:[[_db playlists] libraryList]]) {
		statement = [NSMutableString stringWithFormat:
                     @"INSERT INTO browserTempViewSource (value, compilation) SELECT %@, compilation FROM library WHERE ",
                     grouping];
	} else {
		statement = [NSMutableString stringWithFormat:
                     @"INSERT INTO browserTempViewSource (value, compilation) SELECT library.%@, library.compilation "
                     "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                     "WHERE playlist_items.playlist_id = ?%d AND ",
                     grouping, bindingIndex];
		[bindings setObject:_list forKey:[NSNumber numberWithInt:bindingIndex]];
		bindingIndex++;
	}
    
    // Filter for other browsers
    for (int i = 1; i < browser; i++) {
        NSString *grouping = [self groupingStringForList:_list browser:i];
        NSArray *selection = [[_db playlists] selectionForBrowser:i list:_list];
        
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
	NSString *search = [[_db playlists] searchForList:_list];
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
    
    // Group and Sort
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
    if (useCache && [_list isEqual:[[_db playlists] libraryList]]) {
        [_db execute:[NSString stringWithFormat:@"DELETE FROM %@", destinationTableName]];
        [_db execute:[NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM %@ ORDER BY row", destinationTableName, cacheTableName]];
        _compilation = _cachedCompilation;
    } else {
        [_db execute:@"DELETE FROM browserTempViewSource"];
        [_db execute:statement bindings:bindings columns:nil];
        [_db execute:[NSString stringWithFormat:@"DELETE FROM %@", destinationTableName]];
        if ([self compilationForBrowser:browser]) {
            [_db execute:[NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM browserTempViewSource WHERE compilation = 0 ORDER BY row", destinationTableName]];
            NSArray *rlt = [_db execute:@"SELECT compilation FROM browserTempViewSource WHERE compilation != 0 LIMIT 1" 
                              bindings:nil 
                               columns:[NSArray arrayWithObject:PRColInteger]];
            _compilation = ([rlt count] != 0);
        } else {
            [_db execute:[NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM browserTempViewSource ORDER BY row", destinationTableName]];
        }
    }
    
    // Reset if nothing
    NSMutableArray *selection = [NSMutableArray arrayWithArray:[[_db playlists] selectionForBrowser:browser list:_list]];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    for (int i = 0; i < [selection count]; i++) {
        if ([[selection objectAtIndex:i] isEqualToString:compilationString]) {
            if (![self compilationForBrowser:browser] || !_compilation) {
                [indexesToRemove addIndex:i];
            }
        } else {
            NSArray *results = [_db execute:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE value COLLATE NOCASE2 = ?1", destinationTableName]
                                  bindings:[NSDictionary dictionaryWithObjectsAndKeys:[selection objectAtIndex:i], [NSNumber numberWithInt:1], nil]
                                   columns:[NSArray arrayWithObject:PRColInteger]];
            if ([[[results objectAtIndex:0] objectAtIndex:0] intValue] == 0) {
                [indexesToRemove addIndex:i];
            }
        }
    }
    if ([indexesToRemove count] > 0) {
        [selection removeObjectsAtIndexes:indexesToRemove];
        [[_db playlists] setSelection:[NSArray arrayWithArray:selection] forBrowser:browser list:_list];
    }
	return TRUE;
}

// ========================================
// Library Accessors

- (int)count {
    NSArray *rlt = [_db execute:@"SELECT COUNT(*) FROM libraryViewSource"
                      bindings:nil 
                       columns:[NSArray arrayWithObject:PRColInteger]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@""];}
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRItem *)itemForRow:(int)row {
    NSArray *rlt = [_db execute:@"SELECT file_id FROM libraryViewSource WHERE row = ?1"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil] 
                       columns:[NSArray arrayWithObject:PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (int)rowForItem:(PRItem *)item {
    NSArray *rlt = [_db execute:@"SELECT row FROM libraryViewSource WHERE file_id = ?1"
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:item, [NSNumber numberWithInt:1], nil] 
                       columns:[NSArray arrayWithObjects:PRColInteger, nil]];
    if ([rlt count] > 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    } else if ([rlt count] == 0) {
        return -1;
    }
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (id)valueForRow:(int)row attribute:(PRItemAttr *)attr andCacheAttributes:(NSArray *(^)(void))attributes {
    if (_cachedAttrValues && _cachedRow == row && _cachedAttrs && [_cachedAttrs indexOfObject:attr] != NSNotFound) {
        return [_cachedAttrValues objectAtIndex:[_cachedAttrs indexOfObject:attr]];
    }
    if (!_cachedStatement || ![_cachedAttrs containsObject:attr]) {
        NSArray *temp = attributes();
        if (![temp containsObject:attr]) {
            temp = [temp arrayByAddingObject:attr];
        }
        [_cachedAttrs release];
        _cachedAttrs = [temp retain];
        NSMutableString *string = [NSMutableString stringWithString:@"SELECT "];
        NSMutableArray *columns = [NSMutableArray array];
        for (PRItemAttr *i in _cachedAttrs) {
            [string appendFormat:@"library.%@, ", [[PRLibrary class] columnNameForItemAttr:i]];
            [columns addObject:[PRLibrary columnTypeForItemAttr:i]];
        }
        [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
        [string appendString:@" FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id WHERE row = ?1"];
        [_cachedStatement release];
        _cachedStatement = [[PRStatement alloc] initWithString:string bindings:nil columns:columns db:_db];
    }
    [_cachedStatement setBindings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil]];
    NSArray *result = [[_cachedStatement execute] objectAtIndex:0];
    _cachedRow = row;
    [_cachedAttrValues release];
    _cachedAttrValues = [result retain];
    return [result objectAtIndex:[_cachedAttrs indexOfObject:attr]];
}

- (int)firstRowWithValue:(id)value forAttr:(PRItemAttr *)attr {
    NSString *stm = [NSString stringWithFormat:@"SELECT row FROM libraryViewSource "
                     "JOIN library ON libraryViewSource.file_id = library.file_id WHERE %@ = ?1 COLLATE NOCASE2 "
                     "ORDER BY row LIMIT 1", 
                     [PRLibrary columnNameForItemAttr:attr]];
    NSArray *rlt = [_db execute:stm 
                       bindings:[NSDictionary dictionaryWithObjectsAndKeys:value, [NSNumber numberWithInt:1], nil]
                        columns:[NSArray arrayWithObject:PRColInteger]];
    if ([rlt count] == 0) {
        return -1;
    }
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (NSDictionary *)info {
    NSArray *rlt = [_db execute:@"SELECT SUM(time), SUM(size), count(libraryViewSource.file_id) "
                    "FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id"
                      bindings:nil
                       columns:[NSArray arrayWithObjects:PRColInteger, PRColInteger, PRColInteger, nil]];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [[rlt objectAtIndex:0] objectAtIndex:0], @"time",
                          [[rlt objectAtIndex:0] objectAtIndex:1], @"size",
                          [[rlt objectAtIndex:0] objectAtIndex:2], @"count", nil];
    return info;
}

- (NSArray *)albumCounts {
    NSArray *results = [_db execute:@"SELECT library.album FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id" 
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

- (int)countForBrowser:(int)browser {
    if (![[_db playlists] attrForBrowser:browser list:_list]) {
        return 0;
    }
    NSArray *rlt = [_db execute:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", [self tableNameForBrowser:browser]]
                      bindings:nil 
                       columns:[NSArray arrayWithObject:PRColInteger]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@""];}
    
    int count = [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
    if ([self compilationForBrowser:browser] && _compilation) {
        count += 1;
    }
    return count;
}

- (NSString *)valueForRow:(int)row browser:(int)browser {
    if ([self compilationForBrowser:browser] && _compilation) {
        if (row == 1) {
            return compilationString;
        }
        row -= 1;
    }
    NSArray *rlt = [_db execute:[NSString stringWithFormat:@"SELECT value FROM %@ WHERE row = ?1", [self tableNameForBrowser:browser]]
                      bindings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil]
                       columns:[NSArray arrayWithObjects:PRColString, nil]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@"row:%d browser:%d",row, browser];}
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (NSIndexSet *)selectionForBrowser:(int)browser {
    NSArray *selectionArray = [[_db playlists] selectionForBrowser:browser list:_list];
    if ([selectionArray count] == 0) {
        return [NSIndexSet indexSetWithIndex:0];
	}
    NSString *browserTableName = [self tableNameForBrowser:browser];
	NSMutableString *string = [NSMutableString stringWithFormat:@"SELECT row FROM %@ WHERE value COLLATE NOCASE2 IN (", browserTableName];
	for (NSString *i in selectionArray) {
		[string appendString:@"?, "];
	}
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 2)];
	[string appendString:@")"];
    
    NSMutableDictionary *bnd = [NSMutableDictionary dictionary];
    for (int i = 0; i < [selectionArray count]; i++) {
        [bnd setObject:[selectionArray objectAtIndex:i] forKey:[NSNumber numberWithInt:i + 1]];
    }
    NSArray *rlt = [_db execute:string bindings:bnd columns:[NSArray arrayWithObject:PRColInteger]];
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSArray *i in rlt) {
        int index = [[i objectAtIndex:0] intValue];
        if ([self compilationForBrowser:browser] && _compilation) {
            index += 1;
        }
        [indexSet addIndex:index];
    }
    if ([self compilationForBrowser:browser] && _compilation && [selectionArray containsObject:compilationString]) {
        [indexSet addIndex:1];
    }
    if ([indexSet count] == 0) {
        [indexSet addIndex:0];
    }
    return indexSet;
}

// ========================================
// Priv

- (BOOL)compilationForBrowser:(int)browser {
    return ([[[_db playlists] attrForBrowser:browser list:_list] isEqual:PRItemAttrArtist] && [[PRUserDefaults userDefaults] useCompilation]);
}

- (NSString *)tableNameForBrowser:(int)browser {
	if (browser == 1) {
		return browser1ViewSource;
	} else if (browser == 2) {
		return browser2ViewSource;
	} else if (browser == 3) {
		return browser3ViewSource;
	} 
    @throw NSInvalidArgumentException;
}

- (NSString *)groupingStringForList:(PRList *)list browser:(int)browser {
    if (browser != 1 && browser != 2 && browser != 3) {
        @throw NSInvalidArgumentException;
    }
    PRItemAttr *attr = [[_db playlists] attrForBrowser:browser list:list];
    if (!attr) {
       return @"";
    }
    if ([[PRUserDefaults userDefaults] useAlbumArtist] && [attr isEqual:PRItemAttrArtist]) {
        return @"artistAlbumArtist";
    }
    return [PRLibrary columnNameForItemAttr:attr];
}

@end
