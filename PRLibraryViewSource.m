#import "PRLibraryViewSource.h"
#import "PRDb.h"
#import "PRLibraryViewController.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRStatement.h"
#import "PRDefaults.h"


NSString * const libraryViewSource = @"libraryViewSource";
NSString * const browser1ViewSource = @"browser1ViewSource";
NSString * const browser2ViewSource = @"browser2ViewSource";
NSString * const browser3ViewSource = @"browser3ViewSource";
NSString * const compilationString = @"Compilations  ";


@interface PRLibraryViewSource ()
/* Update Priv */
- (BOOL)populateCaches;
- (BOOL)populateLibrary;
- (BOOL)populateBrowser:(int)browser;
- (NSString *)searchStringForList:(PRList *)list;

/* Priv */
- (BOOL)compilationForBrowser:(int)browser;
- (NSString *)tableNameForBrowser:(int)browser;
- (NSString *)groupingStringForList:(PRList *)list browser:(int)browser;
@end


@implementation PRLibraryViewSource

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db {
	if (!(self = [super init])) {return nil;}
    _db = db;
    _compilation = TRUE;
    _prevSourceString = @"";
    _prevSourceBindings = [@{} retain];
    prevBrowser1Bindings = [@{} retain];
    prevBrowser2Bindings = [@{} retain];
    prevBrowser3Bindings = [@{} retain];
    _cachedLibraryStatement = @"";
    _cachedBrowser1Statement = @"";
    _cachedBrowser2Statement = @"";
    _cachedBrowser3Statement = @"";
	return self;
}

- (void)create {
    
}

- (BOOL)initialize {
    [_db execute:@"CREATE TEMP TABLE libraryViewSource "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "file_id INTEGER NOT NULL)"];
    
    [_db execute:@"CREATE TEMP TABLE browser1ViewSource "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "value TEXT NOT NULL)"];
    
    [_db execute:@"CREATE TEMP TABLE browser2ViewSource "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "value TEXT NOT NULL)"];
    
    [_db execute:@"CREATE TEMP TABLE browser3ViewSource "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "value TEXT NOT NULL)"];
    
    [_db execute:@"CREATE TEMP TABLE browserTempViewSource "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "value TEXT NOT NULL,"
     "compilation INTEGER NOT NULL)"];
    
    [_db execute:@"CREATE TEMP TABLE libraryCache "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "file_id INTEGER NOT NULL)"];
    
    [_db execute:@"CREATE TEMP TABLE browser1Cache "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "value TEXT NOT NULL)"];    
    
    [_db execute:@"CREATE TEMP TABLE browser2Cache "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "value TEXT NOT NULL)"];
    
    [_db execute:@"CREATE TEMP TABLE browser3Cache "
     "(row INTEGER NOT NULL PRIMARY KEY, "
     "value TEXT NOT NULL)"];
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
    [_cachedLibraryStatement release];
    [_cachedBrowser1Statement release];
    [_cachedBrowser2Statement release];
    [_cachedBrowser3Statement release];
    [_cachedAttrs release];
    [_cachedAttrValues release];
    [_cachedStatement release];
    [super dealloc];
}

#pragma mark - Update

- (int)refreshWithList:(PRList *)list force:(BOOL)force {
    [_cachedAttrValues release];
    _cachedAttrValues = nil;
    [_list release];
    _list = [list retain];
    _force = force;
    
    int tables = 0;
    [self populateCaches];
    if ([self populateBrowser:1]) {
        tables = PRBrowser1View;
    }
    if ([self populateBrowser:2]) {
        tables = tables | PRBrowser2View;
    }
    if ([self populateBrowser:3]) {
        tables = tables | PRBrowser3View;
    }
    if ([self populateLibrary]) {
        tables = tables | PRLibraryView;
    }
	return tables;
}

#pragma mark - Update Priv

- (BOOL)populateCaches {
    if (![_list isEqual:[[_db playlists] libraryList]]) {
        return TRUE;
    }
    
    // Cache library
    NSString *string = [NSString stringWithFormat:@"INSERT INTO libraryCache (file_id) SELECT file_id FROM library %@ ",
              [self searchStringForList:_list]];
    if (![string isEqualToString:_cachedLibraryStatement] || _force) {
        [_db execute:@"DELETE FROM libraryCache"];
        [_db execute:string];
        [_cachedLibraryStatement release];
        _cachedLibraryStatement = [string retain];
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
    NSArray *rlt = [_db execute:@"SELECT file_id FROM library WHERE compilation != 0 LIMIT 1"
					   bindings:nil
						columns:@[PRColInteger]];
    _cachedCompilation = ([rlt count] != 0);
    return TRUE;
}

- (BOOL)populateLibrary {
    BOOL useCache = TRUE;
	int bindingIndex = 1;
	NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSMutableString *string;
	if ([_list isEqual:[[_db playlists] libraryList]]) {
		string = [NSMutableString stringWithFormat:
                  @"INSERT INTO libraryViewSource (file_id) SELECT file_id FROM library WHERE 1=1 AND "];
	} else {
        useCache = FALSE;
		string = [NSMutableString stringWithFormat:
                  @"INSERT INTO libraryViewSource (file_id) SELECT playlist_items.file_id "
                  "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                  "WHERE playlist_items.playlist_id = ?%d AND ",
                  bindingIndex];
		[bindings setObject:_list forKey:[NSNumber numberWithInt:bindingIndex]];
		bindingIndex++;
	}
	
    // Filter for Column Browser
    for (int i = 1; i <= 3; i++) {
        NSString *grouping = [self groupingStringForList:_list browser:i];
        NSArray *selection = [[_db playlists] selectionForBrowser:i list:_list];
        if ([selection count] != 0 && [grouping length] != 0) {
            useCache = FALSE;
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
        useCache = FALSE;
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
    
    // Delete 'AND '
    [string deleteCharactersInRange:NSMakeRange([string length] - 4, 4)];
    
    // Add Sort
    [string appendString:[self searchStringForList:_list]];
    
    if (!_force && [string isEqualToString:_prevSourceString] && [bindings isEqualToDictionary:_prevSourceBindings]) {
        return FALSE;
    }
    [_prevSourceString release];
    [_prevSourceBindings release];
    _prevSourceString = [string retain];
    _prevSourceBindings = [bindings retain];

    // Repopulate libraryViewSource
    [_db execute:@"DELETE FROM libraryViewSource"];
    if (useCache) {
        [_db execute:@"INSERT INTO libraryViewSource (row, file_id) SELECT row, file_id FROM libraryCache"];
    } else {
        [_db execute:string bindings:bindings columns:nil];
    }
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
        *prevBrowserBindings = [@{} retain];
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
                                columns:@[PRColInteger]];
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
                                   bindings:@{@1:[selection objectAtIndex:i]}
                                    columns:@[PRColInteger]];
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

- (NSString *)searchStringForList:(PRList *)list {
    NSMutableString *string = [[[NSMutableString alloc] init] autorelease];
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
    } else if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist] && [sort isEqual:PRItemAttrArtist]) {
        sortColumnName = [PRLibrary columnNameForItemAttr:PRItemAttrArtistAlbumArtist];
    } else {
        if ([sort isEqual:PRListSortArtistAlbum]) {
            if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]) {
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
	if (sort == PRItemAttrArtist || sort == PRItemAttrArtistAlbumArtist) {
		[string appendFormat:@"ORDER BY CASE WHEN compilation == 0 THEN %@ ELSE 'compilation' END COLLATE NOCASE2 %@, "
		 "album COLLATE NOCASE2 %@, discNumber %@, trackNumber %@",
		 sortColumnName, ascending, ascending, ascending, ascending];
	} else {
		[string appendFormat:@"ORDER BY %@ COLLATE NOCASE2 %@, album COLLATE NOCASE2 %@, discNumber %@, trackNumber %@",
		 sortColumnName, ascending, ascending, ascending, ascending];
	}
    return string;
}

#pragma mark - Library Accessors

- (int)count {
    NSArray *rlt = [_db execute:@"SELECT COUNT(*) FROM libraryViewSource"
                       bindings:nil 
                        columns:@[PRColInteger]];
    if ([rlt count] != 1) {[PRException raise:PRDbInconsistencyException format:@""];}
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (PRItem *)itemForRow:(int)row {
    NSArray *rlt = [_db execute:@"SELECT file_id FROM libraryViewSource WHERE row = ?1"
                       bindings:@{@1:[NSNumber numberWithInt:row]}
                        columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
    return [[rlt objectAtIndex:0] objectAtIndex:0];
}

- (int)rowForItem:(PRItem *)item {
    NSArray *rlt = [_db execute:@"SELECT row FROM libraryViewSource WHERE file_id = ?1"
                       bindings:@{@1:item}
                        columns:@[PRColInteger]];
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
    [_cachedStatement setBindings:@{@1:[NSNumber numberWithInt:row]}];
    NSArray *result = [[_cachedStatement execute] objectAtIndex:0];
    _cachedRow = row;
    [_cachedAttrValues release];
    _cachedAttrValues = [result retain];
    return [result objectAtIndex:[_cachedAttrs indexOfObject:attr]];
}

- (int)firstRowWithValue:(id)value forAttr:(PRItemAttr *)attr {
    NSArray *rlt = [_db execute:[NSString stringWithFormat:@"SELECT row FROM libraryViewSource "
                                 "JOIN library ON libraryViewSource.file_id = library.file_id WHERE %@ = ?1 COLLATE NOCASE2 "
                                 "ORDER BY row LIMIT 1", [PRLibrary columnNameForItemAttr:attr]]
                       bindings:@{@1:value}
                        columns:@[PRColInteger]];
    if ([rlt count] == 0) {
        return -1;
    }
    return [[[rlt objectAtIndex:0] objectAtIndex:0] intValue];
}

- (NSDictionary *)info {
    NSArray *rlt = [_db execute:@"SELECT SUM(time), SUM(size), count(libraryViewSource.file_id) "
                    "FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id"
                      bindings:nil
                       columns:@[PRColInteger, PRColInteger, PRColInteger]];
    if ([rlt count] != 1) {
        @throw PRDbInconsistencyException;
    }
    return @{@"time":[[rlt objectAtIndex:0] objectAtIndex:0],
    @"size":[[rlt objectAtIndex:0] objectAtIndex:1],
    @"count":[[rlt objectAtIndex:0] objectAtIndex:2]};
}

- (NSArray *)albumCounts {
    NSArray *results = [_db execute:@"SELECT library.album FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id" 
                          bindings:nil 
                           columns:@[PRColString]];
    if ([results count] == 0) {
        return @[];
    } else if ([results count] == 1) {
        return @[@1];
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

#pragma mark - Browser Accessors

- (int)countForBrowser:(int)browser {
    if (![[_db playlists] attrForBrowser:browser list:_list]) {
        return 0;
    }
    NSArray *rlt = [_db execute:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", [self tableNameForBrowser:browser]]
                       bindings:nil 
                        columns:@[PRColInteger]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@""];
    }
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
                       bindings:@{@1:[NSNumber numberWithInt:row]}
                        columns:@[PRColString]];
    if ([rlt count] != 1) {
        [PRException raise:PRDbInconsistencyException format:@"row:%d browser:%d",row, browser];
    }
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
    NSArray *rlt = [_db execute:string bindings:bnd columns:@[PRColInteger]];
    
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

#pragma mark - Priv

- (BOOL)compilationForBrowser:(int)browser {
    return ([[[_db playlists] attrForBrowser:browser list:_list] isEqual:PRItemAttrArtist] &&
            [[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]);
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
    } else if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist] && [attr isEqual:PRItemAttrArtist]) {
        return @"artistAlbumArtist";
    }
    return [PRLibrary columnNameForItemAttr:attr];
}

@end
