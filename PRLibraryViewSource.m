#import "PRLibraryViewSource.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRRule.h"
#import "PRUserDefaults.h"

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
        
        prevLibraryStatement = [@"" retain];
        prevLibraryBindings = [[NSDictionary dictionary] retain];
        prevBrowser1Bindings = [@"" retain];
        prevBrowser1Bindings = [[NSDictionary dictionary] retain];
        prevBrowser2Bindings = [@"" retain];
        prevBrowser2Bindings = [[NSDictionary dictionary] retain];
        prevBrowser3Bindings = [@"" retain];
        prevBrowser3Bindings = [[NSDictionary dictionary] retain];
        prevSortStatement = [@"" retain];
        prevBrowser1Grouping = [@"" retain];
        prevBrowser2Grouping = [@"" retain];
        prevBrowser3Grouping = [@"" retain];
	}
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)create_error:(NSError **)error
{
    return TRUE;
}

- (BOOL)initialize_error:(NSError **)error
{	
	if (![db executeStatement:[NSString stringWithFormat:
                               @"CREATE TEMP TABLE %@ "
                               "(row INTEGER NOT NULL PRIMARY KEY, "
                               "file_id INTEGER NOT NULL)",
                               libraryViewSource]
                       _error:error]) {
		return FALSE;
	}
	if (![db executeStatement: [NSString stringWithFormat:
                                @"CREATE TEMP TABLE %@ "
                                "(row INTEGER NOT NULL PRIMARY KEY, "
                                "value TEXT NOT NULL)",
                                browser1ViewSource]
                       _error:error]) {
		return FALSE;
	}
	if (![db executeStatement:[NSString stringWithFormat:
                               @"CREATE TEMP TABLE %@ "
                               "(row INTEGER NOT NULL PRIMARY KEY, "
                               "value TEXT NOT NULL)",
                               browser2ViewSource]
                       _error:error]) {
		return FALSE;
	}
	if (![db executeStatement:[NSString stringWithFormat:
                               @"CREATE TEMP TABLE %@ "
                               "(row INTEGER NOT NULL PRIMARY KEY, "
                               "value TEXT NOT NULL)",
                               browser3ViewSource]
                       _error:error]) {
		return FALSE;
	}
    
    if (![db executeStatement:@"CREATE TEMP TABLE browser1Cache "
          "(row INTEGER NOT NULL PRIMARY KEY, "
          "value TEXT NOT NULL)"
                       _error:nil]) {
        return FALSE;
    }
    if (![db executeStatement:@"CREATE TEMP TABLE browser2Cache "
          "(row INTEGER NOT NULL PRIMARY KEY, "
          "value TEXT NOT NULL)"
                       _error:nil]) {
        return FALSE;
    }
    if (![db executeStatement:@"CREATE TEMP TABLE browser3Cache "
          "(row INTEGER NOT NULL PRIMARY KEY, "
          "value TEXT NOT NULL)"
                       _error:nil]) {
        return FALSE;
    }
	return TRUE;
}

- (BOOL)validate_error:(NSError **)error
{
    return TRUE;
}

// ========================================
// Update
// ========================================

- (BOOL)forceUpdateOnNextRefresh_error:(NSError **)error
{
    force = TRUE;
    return TRUE;
}

- (BOOL)refreshWithPlaylist:(PRPlaylist)playlist
             tablesToUpdate:(int *)tables
					 _error:(NSError **)error
{   
    cachedRow = 0;
    *tables = 0;
	
    BOOL didUpdate;
    [self updateSortIndexWithPlaylist:(PRPlaylist)playlist _error:nil];
    [self populateBrowser:1 withPlaylist:playlist didUpdate:&didUpdate _error:nil];
    if (didUpdate) {
        *tables = *tables | PRBrowser1View;
    }
    [self populateBrowser:2 withPlaylist:playlist didUpdate:&didUpdate _error:nil];
    if (didUpdate) {
        *tables = *tables | PRBrowser2View;
    }
    [self populateBrowser:3 withPlaylist:playlist didUpdate:&didUpdate _error:nil];
    if (didUpdate) {
        *tables = *tables | PRBrowser3View;
    }
    [self populateSourceWithPlaylist:playlist didUpdate:&didUpdate _error:nil];
    if (didUpdate) {
        *tables = *tables | PRLibraryView;
    }    
    force = FALSE;
	return TRUE;
}

- (BOOL)updateSortIndexWithPlaylist:(PRPlaylist)playlist _error:(NSError **)error
{
    if (playlist != [[db playlists] libraryPlaylist] ) {
        return TRUE;
    }
    
    // Library view mode
	int libraryViewMode;
	[play intValue:&libraryViewMode 
	   forPlaylist:playlist 
		 attribute:PRLibraryViewModePlaylistAttribute 
			_error:nil];
	int sortColumnPlaylistAttribute;
	if (libraryViewMode == PRListMode) {
		sortColumnPlaylistAttribute = PRListViewSortColumnPlaylistAttribute;
	} else {
		sortColumnPlaylistAttribute = PRAlbumListViewSortColumnPlaylistAttribute;
	}
	
    // Sort column
    int sortColumn;
	[play intValue:&sortColumn forPlaylist:playlist attribute:sortColumnPlaylistAttribute _error:NULL];
    NSString *sortColumnName;
    if (sortColumn == PRPlaylistIndexSort) {
        sortColumnName = @"playlist_items.playlist_index";
    } else if ([[PRUserDefaults sharedUserDefaults] useAlbumArtist] && sortColumn == PRArtistFileAttribute) {
        sortColumnName = @"artistAlbumArtist";
    } else {
        if (sortColumn == PRArtistAlbumSort) {
            if ([[PRUserDefaults sharedUserDefaults] useAlbumArtist]) {
                sortColumn = PRArtistAlbumArtistFileAttribute;
            } else {
                sortColumn = PRArtistFileAttribute;
            }
        }
        sortColumnName = [PRLibrary columnNameForFileAttribute:sortColumn];
    }
    
    // Sort
    NSString *statement = [NSString stringWithFormat:@"CREATE INDEX index_librarySort ON library "
                           "(%@ COLLATE NOCASE2, album COLLATE NOCASE2, discNumber COLLATE NOCASE2, trackNumber COLLATE NOCASE2, path COLLATE NOCASE2)", 
                           sortColumnName];
    if (![statement isEqualToString:prevSortStatement]) {
        if (![db executeStatement:@"DROP INDEX IF EXISTS index_librarySort" _error:nil]) {
            return FALSE;
        }
        if (![db executeStatement:statement _error:nil]) {
            return FALSE;
        }
        if (![db executeStatement:@"ANALYZE" _error:nil]) {
            return FALSE;
        }
        [prevSortStatement release];
        prevSortStatement = [statement retain];
    }
    
    // Cache browser 1
    NSString *grouping = [self groupingStringForPlaylist:playlist browser:1];
    statement = [NSString stringWithFormat:@"INSERT INTO browser1Cache (value) "
                 "SELECT %@ FROM library WHERE "
                 "%@ != '' COLLATE NOCASE2 "
                 "GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", 
                 grouping, grouping, grouping, grouping];
    if ([grouping length] > 0 && (![statement isEqualToString:prevBrowser1Grouping] || force)) {
        if (![db executeStatement:@"DELETE FROM browser1Cache" _error:nil]) {
            return FALSE;
        }
        if (![db executeStatement:statement _error:nil]) {
            return FALSE;
        }
        [prevBrowser1Grouping release];
        prevBrowser1Grouping = [statement retain];
    }
    
    // Cache browser 2
    grouping = [self groupingStringForPlaylist:playlist browser:2];
    statement = [NSString stringWithFormat:@"INSERT INTO browser2Cache (value) "
                 "SELECT %@ FROM library WHERE "
                 "%@ != '' COLLATE NOCASE2 "
                 "GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", 
                 grouping, grouping, grouping, grouping];
    if ([grouping length] > 0 && (![statement isEqualToString:prevBrowser2Grouping] || force)) {
        if (![db executeStatement:@"DELETE FROM browser2Cache" _error:nil]) {
            return FALSE;
        }
        if (![db executeStatement:statement _error:nil]) {
            return FALSE;
        }
        [prevBrowser2Grouping release];
        prevBrowser2Grouping = [statement retain];
    }
    
    // Cache browser 3
    grouping = [self groupingStringForPlaylist:playlist browser:3];
    statement = [NSString stringWithFormat:@"INSERT INTO browser3Cache (value) "
                 "SELECT %@ FROM library WHERE "
                 "%@ != '' COLLATE NOCASE2 "
                 "GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", 
                 grouping, grouping, grouping, grouping];
    if ([grouping length] > 0 && (![statement isEqualToString:prevBrowser3Grouping] || force)) {
        if (![db executeStatement:@"DELETE FROM browser3Cache" _error:nil]) {
            return FALSE;
        }
        if (![db executeStatement:statement _error:nil]) {
            return FALSE;
        }
        [prevBrowser3Grouping release];
        prevBrowser3Grouping = [statement retain];
    }
    
//    if (![browser1Grouping isEqualToString:prevBrowser1Grouping] && 
//        ![browser1Grouping isEqualToString:@""]) {
//        [prevBrowser1Grouping release];
//        prevBrowser1Grouping = [browser1Grouping retain];
//        
//        if (![db executeStatement:@"DROP INDEX IF EXISTS index_browser1a" _error:nil]) {
//            return FALSE;
//        }
//        if (![db executeStatement:[NSString stringWithFormat:@"CREATE INDEX index_browser1a ON library ("
//                                   "%@ COLLATE NOCASE2 ASC, "
//                                   "%@ COLLATE NOCASE2 ASC, "
//                                   "%@ COLLATE NOCASE2 ASC)"
//                                   ,browser1Grouping, browser2Grouping, browser3Grouping] 
//                           _error:nil]) {
//            return FALSE;
//        }
//        
//        if (![db executeStatement:@"DROP INDEX IF EXISTS index_browser1b" _error:nil]) {
//            return FALSE;
//        }
//        if (![db executeStatement:[NSString stringWithFormat:@"CREATE INDEX index_browser1b ON library ("
//                                   "%@ COLLATE NOCASE2 ASC, "
//                                   "%@ COLLATE NOCASE2 ASC)"
//                                   ,browser1Grouping, browser3Grouping]
//                           _error:nil]) {
//            return FALSE;
//        }
//
//        if (![browser2Grouping isEqualToString:prevBrowser2Grouping] &&
//            ![browser2Grouping isEqualToString:@""]) {
//            [prevBrowser2Grouping release];
//            prevBrowser2Grouping = [browser2Grouping retain];
//            
//            if (![db executeStatement:@"DROP INDEX IF EXISTS index_browser2" _error:nil]) {
//                return FALSE;
//            }
//            if (![db executeStatement:[NSString stringWithFormat:@"CREATE INDEX index_browser2 ON library ("
//                                       "%@ COLLATE NOCASE2 ASC, "
//                                       "%@ COLLATE NOCASE2 ASC)"
//                                       ,browser2Grouping, browser3Grouping]
//                               _error:nil]) {
//                return FALSE;
//            }
//            
//            if (![browser3Grouping isEqualToString:prevBrowser3Grouping] &&
//                ![browser3Grouping isEqualToString:@""]) {
//                [prevBrowser3Grouping release];
//                prevBrowser3Grouping = [browser3Grouping retain];
//                
//                if (![db executeStatement:@"DROP INDEX IF EXISTS index_browser3" _error:nil]) {
//                    return FALSE;
//                }
//                if (![db executeStatement:[NSString stringWithFormat:@"CREATE INDEX index_browser3 ON library ("
//                                           "%@ COLLATE NOCASE2 ASC)"
//                                           , browser3Grouping]
//                                   _error:nil]) {
//                    return FALSE;
//                }
//            }            
//        }
//    }
    
    return TRUE;
}

- (BOOL)populateSourceWithPlaylist:(PRPlaylist)playlist didUpdate:(BOOL *)didUpdate _error:(NSError **)error
{    
    BOOL whereTerm = FALSE;
	int bindingIndex = 1;
	NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSMutableString *statement;
	// populate library_view_source
	if (playlist == [[db playlists] libraryPlaylist]) {
		statement = [NSMutableString stringWithFormat:
                     @"INSERT INTO libraryViewSource (file_id) "
                     "SELECT file_id "
                     "FROM library "
                     "WHERE "];
	} else {
		statement = [NSMutableString stringWithFormat:
                     @"INSERT INTO libraryViewSource (file_id) "
                     "SELECT playlist_items.file_id "
                     "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                     "WHERE playlist_items.playlist_id = ?%d AND ",
                     bindingIndex];
		[bindings setObject:[NSNumber numberWithInt:playlist] forKey:[NSNumber numberWithInt:bindingIndex]];
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
	
    for (int i = 1; i <= 3; i++) {
        NSString *grouping = [self groupingStringForPlaylist:playlist browser:i];
        NSArray *selection = [self selectionForPlaylist:playlist browser:i];
        
        if ([selection count] != 0 && [grouping length] != 0) {
            whereTerm = TRUE;
            // copy rows from library_view_source into temp table that match selection
            [statement appendFormat:@"%@ COLLATE NOCASE2 IN (", grouping];
            for (NSString *i in selection) {
                [statement appendFormat:@"?%d, ", bindingIndex];
                [bindings setObject:i forKey:[NSNumber numberWithInt:bindingIndex]];
                bindingIndex++;
            }
            [statement deleteCharactersInRange:NSMakeRange([statement length] - 2, 2)];
            [statement appendString:@") AND "];
        }
    }
    
	// filter for search
	NSString *search;
	[play value:&search forPlaylist:playlist attribute:PRSearchPlaylistAttribute _error:nil];
	if (search && [search length] != 0) {
        whereTerm = TRUE;
		[statement appendString:@"(1 = 1 "];
		NSArray *searchTerms = [search componentsSeparatedByString:@" "];
		
		for (NSString *term in searchTerms) {
			[statement appendString:[NSString stringWithFormat:@"AND (library.title LIKE ?%d "
                                     "OR library.album LIKE ?%d "
                                     "OR library.composer LIKE ?%d "
                                     "OR library.artist LIKE ?%d "
                                     "OR library.albumArtist LIKE ?%d) ", bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex]];
			
			[bindings setObject:[NSString stringWithFormat:@"%%%@%%",term] forKey:[NSNumber numberWithInt:bindingIndex]];
			bindingIndex++;
		}
		[statement appendString:@") AND "];
	}
    
    if (whereTerm) {
        [statement deleteCharactersInRange:NSMakeRange([statement length] - 4, 4)];
    } else {
        [statement deleteCharactersInRange:NSMakeRange([statement length] - 6, 6)];
    }
    
    // Library view mode
	int libraryViewMode;
	[play intValue:&libraryViewMode 
	   forPlaylist:playlist 
		 attribute:PRLibraryViewModePlaylistAttribute 
			_error:error];
	int sortColumnPlaylistAttribute;
	int ascendingPlaylistAttribute;
	if (libraryViewMode == PRListMode) {
		sortColumnPlaylistAttribute = PRListViewSortColumnPlaylistAttribute;
		ascendingPlaylistAttribute = PRListViewAscendingPlaylistAttribute;
	} else {
		sortColumnPlaylistAttribute = PRAlbumListViewSortColumnPlaylistAttribute;
		ascendingPlaylistAttribute = PRAlbumListViewAscendingPlaylistAttribute;
	}
	
    // Sort column
    int sortColumn;
	[play intValue:&sortColumn forPlaylist:playlist attribute:sortColumnPlaylistAttribute _error:NULL];
    NSString *sortColumnName;
    if (sortColumn == PRPlaylistIndexSort) {
        sortColumnName = @"playlist_items.playlist_index";
    } else if ([[PRUserDefaults sharedUserDefaults] useAlbumArtist] && sortColumn == PRArtistFileAttribute) {
        sortColumnName = @"artistAlbumArtist";
    } else {
        if (sortColumn == PRArtistAlbumSort) {
            if ([[PRUserDefaults sharedUserDefaults] useAlbumArtist]) {
                sortColumn = PRArtistAlbumArtistFileAttribute;
            } else {
                sortColumn = PRArtistFileAttribute;
            }
        }
        sortColumnName = [PRLibrary columnNameForFileAttribute:sortColumn];
    }
    
    // Ascending
    int asc;
	[play intValue:&asc forPlaylist:playlist attribute:ascendingPlaylistAttribute _error:NULL];
    NSString *ascending;
	if (asc) {
		ascending = @"ASC";
	} else {
		ascending = @"DESC";
	}
    
    // Sort
    [statement appendFormat:@"ORDER BY %@ COLLATE NOCASE2 %@, album COLLATE NOCASE2 %@, discNumber COLLATE NOCASE2 %@, trackNumber COLLATE NOCASE2 %@, path COLLATE NOCASE2 %@ ", 
     sortColumnName, ascending, ascending, ascending, ascending, ascending];
    
    if (!force &&
        [statement isEqualToString:prevLibraryStatement] &&
        [bindings isEqualToDictionary:prevLibraryBindings]) {
        *didUpdate = FALSE;
        return TRUE;
    }
    [prevLibraryStatement release];
    [prevLibraryBindings release];
    prevLibraryStatement = [statement retain];
    prevLibraryBindings = [bindings retain];
    *didUpdate = TRUE;
    
    // Delete all items from library1ViewSource
	if (![db executeStatement:@"DELETE FROM libraryViewSource"
                       _error:nil]) {
		return FALSE;
	}
    
	// Execute
	if (![db executeStatement:statement withBindings:bindings _error:error]) {
		return FALSE;
	}
    return TRUE;
}

- (BOOL)populateBrowser:(int)browser withPlaylist:(PRPlaylist)playlist didUpdate:(BOOL *)didUpdate _error:(NSError **)error
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
    NSString *grouping = [self groupingStringForPlaylist:playlist browser:browser];
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
	if (playlist == [[db playlists] libraryPlaylist]) {
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
		[bindings setObject:[NSNumber numberWithInt:playlist] forKey:[NSNumber numberWithInt:bindingIndex]];
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
        NSString *grouping = [self groupingStringForPlaylist:playlist browser:i];
        NSArray *selection = [self selectionForPlaylist:playlist browser:i];
        
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
	NSString *search;
	[play value:&search forPlaylist:playlist attribute:PRSearchPlaylistAttribute _error:nil];
	if (search && [search length] != 0) {
		[statement appendString:@"(1 = 1 "];
		NSArray *searchTerms = [search componentsSeparatedByString:@" "];
		
		for (NSString *term in searchTerms) {
			[statement appendString:[NSString stringWithFormat:@"AND (library.title LIKE ?%d "
                                     "OR library.album LIKE ?%d "
                                     "OR library.composer LIKE ?%d "
                                     "OR library.artist LIKE ?%d "
                                     "OR library.albumArtist LIKE ?%d) ", bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex]];
			
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
    
    if (!force &&
        [statement isEqualToString:*prevBrowserStatement] &&
        [bindings isEqualToDictionary:*prevBrowserBindings]) {
        *didUpdate = FALSE;
        return TRUE;
    }
    [*prevBrowserStatement release];
    [*prevBrowserBindings release];
    *prevBrowserStatement = [statement retain];
    *prevBrowserBindings = [bindings retain];
    *didUpdate = TRUE;
    
    // Delete all items from browser
	if (![db executeStatement:[NSString stringWithFormat:@"DELETE FROM %@", destinationTableName]
                       _error:nil]) {
		return FALSE;
	}
    
	// Execute
    if (useCache && playlist == [play libraryPlaylist]) {
        statement = [NSString stringWithFormat:@"INSERT INTO %@ (value) SELECT value FROM %@ ORDER BY row", destinationTableName, cacheTableName];
        bindings = nil;
    }
    if (![db executeStatement:statement withBindings:bindings _error:nil]) {
        return FALSE;
    }
    
    NSMutableArray *selection = [NSMutableArray arrayWithArray:[self selectionForPlaylist:playlist browser:browser]];
    NSMutableIndexSet *indexesToRemove = [[[NSMutableIndexSet alloc] init] autorelease];
    for (int i = 0; i < [selection count]; i++) {
        NSArray *result;
        if (![db executeStatement:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE value COLLATE NOCASE2 = ?1", destinationTableName]
                     withBindings:[NSDictionary dictionaryWithObject:[selection objectAtIndex:i] forKey:[NSNumber numberWithInt:1]]
                           result:&result
                           _error:nil]) {
            return FALSE;
        }
        if ([[result objectAtIndex:0] intValue] == 0) {
            [indexesToRemove addIndex:i];
        }
    }
    if ([indexesToRemove count] > 0) {
        [selection removeObjectsAtIndexes:indexesToRemove];
        [play setValue:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:selection]] 
           forPlaylist:playlist 
             attribute:[PRLibraryViewSource selectionPlaylistAttributeForBrowser:browser]
                _error:nil];
    }
    
	return TRUE;
}

// ========================================
// Accessors
// ========================================

@synthesize cachedValues;

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

+ (PRPlaylistAttribute)groupingPlaylistAttributeForBrowser:(int)browser
{
	if (browser == 1) {
		return PRBrowser1AttributePlaylistAttribute;
	} else if (browser == 2) {
		return PRBrowser2AttributePlaylistAttribute;
	} else if (browser == 3) {
		return PRBrowser3AttributePlaylistAttribute;
	} else {
		NSLog(@"PRLibraryViewSource refreshBrowser:withPlaylist:_error: Unknown Browser");
		return -1;
	}
}

+ (PRPlaylistAttribute)selectionPlaylistAttributeForBrowser:(int)browser
{
	if (browser == 1) {
		return PRBrowser1SelectionPlaylistAttribute;
	} else if (browser == 2) {
		return PRBrowser2SelectionPlaylistAttribute;
	} else if (browser == 3) {
		return PRBrowser3SelectionPlaylistAttribute;
	} else {
		NSLog(@"PRLibraryViewSource refreshBrowser:withPlaylist:_error: Unknown Browser");
		return -1;
	}
}

- (NSString *)groupingStringForPlaylist:(PRPlaylist)playlist browser:(int)browser
{
    PRPlaylistAttribute groupingPlaylistAttribute;
    if (browser == 1) {
		groupingPlaylistAttribute = PRBrowser1AttributePlaylistAttribute;
	} else if (browser == 2) {
		groupingPlaylistAttribute = PRBrowser2AttributePlaylistAttribute;
	} else if (browser == 3) {
		groupingPlaylistAttribute = PRBrowser3AttributePlaylistAttribute;
	} else {
        return @"";
    }
    int grouping;
	[play intValue:&grouping forPlaylist:playlist attribute:groupingPlaylistAttribute _error:nil];
    if (grouping == 0) {
        return @"";
    }
    if ([[PRUserDefaults sharedUserDefaults] useAlbumArtist] && grouping == PRArtistFileAttribute) {
		return @"artistAlbumArtist";
	}
    return [[PRLibrary columnDict] objectForKey:[NSNumber numberWithInt:grouping]];
}

- (NSArray *)selectionForPlaylist:(PRPlaylist)playlist browser:(int)browser
{
    PRPlaylistAttribute selectionPlaylistAttribute;
    if (browser == 1) {
		selectionPlaylistAttribute = PRBrowser1SelectionPlaylistAttribute;
	} else if (browser == 2) {
		selectionPlaylistAttribute = PRBrowser2SelectionPlaylistAttribute;
	} else if (browser == 3) {
		selectionPlaylistAttribute = PRBrowser3SelectionPlaylistAttribute;
	} else {
        return [NSArray array];
    }
	NSData *selectionData;
	[play value:&selectionData 
	forPlaylist:playlist 
	  attribute:selectionPlaylistAttribute
		 _error:nil];
    NSArray *selection;
	if (!selectionData) {
		selection = [NSArray array];
	} else {
		selection = [NSKeyedUnarchiver unarchiveObjectWithData:selectionData];
	}
    return selection;
}

- (BOOL)count:(int *)count _error:(NSError **)error
{
	return [db count:count forTable:libraryViewSource _error:error];	
}

- (BOOL)file:(PRFile *)file forRow:(int)row _error:(NSError **)error
{
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil];
    NSArray *results;
    if (![db executeStatement:@"SELECT file_id FROM libraryViewSource WHERE row = ?1"
                 withBindings:bindings 
                       result:&results 
                       _error:nil]) {
        return FALSE;
    }
    
    if ([results count] != 1 && [[results objectAtIndex:0] isKindOfClass:[NSNumber class]]) {
        return FALSE;
    }
    
    *file = [[results objectAtIndex:0] intValue];
    return TRUE;
}

- (BOOL)     value:(id *)value 
            forRow:(int)row 
         attribute:(PRFileAttribute)attribute 
  cachedAttributes:(NSArray *)cachedAttributes 
            _error:(NSError **)error
{
    if (row == cachedRow && cachedValues && [cachedValues objectForKey:[NSNumber numberWithInt:attribute]]) {
        *value = [cachedValues objectForKey:[NSNumber numberWithInt:attribute]];
    } else {
        NSMutableString *columns = [NSMutableString string];
        for (NSNumber *i in cachedAttributes) {
            [columns appendFormat:@"library.%@, ", [[PRLibrary class] columnNameForFileAttribute:[i intValue]]];
        }
        [columns deleteCharactersInRange:NSMakeRange([columns length] - 2, 2)];
        [columns appendString:@" "];
        
        NSString *statement = [NSString stringWithFormat:@"SELECT %@ FROM libraryViewSource "
                               "JOIN library ON libraryViewSource.file_id = library.file_id "
                               "WHERE row = ?1", columns];
        NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:row], [NSNumber numberWithInt:1], nil];
        NSArray *result;
        if (![db executeStatement:statement
                     withBindings:bindings
                           result:&result 
                           _error:nil]) {
            return FALSE;
        }
        if ([cachedAttributes count] == 1) {
            cachedRow = row;
            [self setCachedValues:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [result objectAtIndex:0], [cachedAttributes objectAtIndex:0], nil]];
        } else if ([cachedAttributes count] > 1) {
            NSMutableDictionary *mutableCachedValues = [NSMutableDictionary dictionary];
            for (int i = 0; i < [cachedAttributes count]; i++) {
                [mutableCachedValues setObject:[[result objectAtIndex:0] objectAtIndex:i] 
                                        forKey:[cachedAttributes objectAtIndex:i]];
            }
            cachedRow = row;
            [self setCachedValues:[NSDictionary dictionaryWithDictionary:mutableCachedValues]];
        }
        *value = [cachedValues objectForKey:[NSNumber numberWithInt:attribute]];
    }
    return TRUE;
}

- (BOOL)row:(int *)row forFile:(PRFile)file _error:(NSError **)error
{
    NSArray *results;
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:file], [NSNumber numberWithInt:1], nil];
    if (![db executeStatement:@"SELECT row FROM libraryViewSource WHERE file_id = ?1"
                 withBindings:bindings
                       result:&results 
                       _error:nil]) {
        return FALSE;
    }
    
    if ([results count] > 1 || ([results count] == 1 && ![[results objectAtIndex:0] isKindOfClass:[NSNumber class]])) {
        return FALSE;
    }
    
    if ([results count] == 0) {
        *row = -1;
    } else {
        *row = [[results objectAtIndex:0] intValue];
    }
    return TRUE;
}

- (BOOL)count:(int *)count forBrowser:(int)browser _error:(NSError **)error
{
	return [db count:count forTable:[self tableNameForBrowser:browser] _error:error];
}

- (BOOL)value:(NSString **)value_ forRow:(int)row browser:(int)browser _error:(NSError **)error
{
	return [db value:value_ 
		   forColumn:@"value" 
				 row:row 
				 key:@"row" 
			   table:[self tableNameForBrowser:browser] 
			  _error:error];
}

- (BOOL)selectionIndexSet:(NSIndexSet **)selection 
			   forBrowser:(int)browser 
			 withPlaylist:(int)playlist 
				   _error:(NSError **)error_
{
	// get array of selected indexes
    NSData *selectionData;
    int selectionPlaylistAttribute = [PRLibraryViewSource selectionPlaylistAttributeForBrowser:browser];
	[play value:&selectionData forPlaylist:playlist attribute:selectionPlaylistAttribute _error:nil];
	if (!selectionData) {
        *selection = [NSIndexSet indexSetWithIndex:0];
		return TRUE;
	}
	NSArray *selectionArray = [NSKeyedUnarchiver unarchiveObjectWithData:selectionData];
    if ([selectionArray count] == 0) {
        *selection = [NSIndexSet indexSetWithIndex:0];
		return TRUE;
	}
	
    // bindings
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    for (int i = 0; i < [selectionArray count]; i++) {
        [bindings setObject:[selectionArray objectAtIndex:i] forKey:[NSNumber numberWithInt:i + 1]];
    }
    
    // statement
    NSString *browserTableName = [self tableNameForBrowser:browser];
	NSMutableString *statement = [NSMutableString stringWithFormat:@"SELECT %@.row FROM %@ WHERE value IN (", 
                                  browserTableName, browserTableName, browserTableName];
	for (NSString *i in selectionArray) {
		[statement appendString:@"?, "];
	}
    [statement deleteCharactersInRange:NSMakeRange([statement length] - 2, 2)];
	[statement appendString:@")"];
    
    // execute
    NSArray *results;
    if (![db executeStatement:statement 
                 withBindings:bindings 
                       result:&results 
                       _error:nil]) {
        return FALSE;
    }
        
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSNumber *i in results) {
        [indexSet addIndex:[i intValue]];
    }
    if ([indexSet count] == 0) {
        [indexSet addIndex:0];
    }

    *selection = [[[NSIndexSet alloc] initWithIndexSet:indexSet] autorelease];
	return TRUE;
}

- (NSDictionary *)info
{
    NSString *statementString = @"SELECT SUM(time), SUM(size), count(libraryViewSource.file_id) "
    "FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id";
    NSArray *columnTypes = [NSArray arrayWithObjects:
                            [NSNumber numberWithInt:PRColumnInteger], 
                            [NSNumber numberWithInt:PRColumnInteger], 
                            [NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [PRStatement executeString:statementString withDb:db bindings:nil columnTypes:columnTypes];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          [[results objectAtIndex:0] objectAtIndex:0], @"time",
                          [[results objectAtIndex:0] objectAtIndex:1], @"size",
                          [[results objectAtIndex:0] objectAtIndex:2], @"count", nil];
    return info;
}

- (BOOL)arrayOfAlbumCounts:(NSArray **)albumCounts _error:(NSError **)error
{
    NSArray *results;
    if (![db executeStatement:@"SELECT library.album FROM libraryViewSource "
          "JOIN library ON libraryViewSource.file_id = library.file_id"
                 withBindings:nil 
                       result:&results 
                       _error:nil]) {
        return FALSE;
    }
    
    if ([results count] == 0) {
        *albumCounts = [NSArray array];
        return TRUE;
    } else if ([results count] == 1) {
        *albumCounts = [NSArray arrayWithObject:[NSNumber numberWithInt:1]];
        return TRUE;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    int count = 1;
    int i = 0;
    while (i < [results count] - 1) {
        NSString *string = [results objectAtIndex:i];
        NSString *nextString = [results objectAtIndex:i + 1];
        if (no_case(nil, [string lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [string cStringUsingEncoding:NSUTF16StringEncoding], 
                    [nextString lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [nextString cStringUsingEncoding:NSUTF16StringEncoding]) != 0) {
            [array addObject:[NSNumber numberWithInt:count]];
            count = 0;
        }
        count++;
        i++;
    }
    [array addObject:[NSNumber numberWithInt:count]];
    *albumCounts = [NSArray arrayWithArray:array];
    
    return TRUE;
}

@end