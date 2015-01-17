#import "PRLibraryDescription.h"
#import "PRPlaylists.h"
#import "PRConnection.h"
#import "PRList.h"
#import "PRDefaults.h"
#import "NSArray+Extensions.h"
#import "PRStatement.h"
#import "PRLibraryViewController.h"
#import "NSString+Extensions.h"

extern NSString * const PRCompilationString;
NSString * const PRCompilationString = @"Compilations  ";

@implementation PRLibraryDescription {
    PRListID *_list;
    PRList *_listDescription;
    NSArray *_items;
    NSArray *_info;
    NSArray *_albumCounts;
    PRConnection *_conn;
    
    PRStatement *_cachedStatement;
    NSArray *_cachedAttrValues;
    NSInteger _cachedRow;
    NSArray *_cachedAttrs;
}

- (id)initWithListID:(PRListID *)list connection:(PRConnection *)conn {
    if (!(self = [super init])) {return nil;}
    _conn = conn;
    _list = list;
    
    PRList *listDescription;
    BOOL success = [[_conn playlists] zListForListID:list out:&listDescription];
    if (!success) {
        return nil;
    }
    _listDescription = listDescription;
    
    {
        NSInteger bindingIndex = 1;
        NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
        NSMutableString *stmt;
        NSString *albumColumn = @"";
        NSArray *columns = nil;
        if ([_listDescription viewMode] == PRLibraryViewModeAlbumList) {
            albumColumn = @", library.album";
        }
        if ([_list isEqual:[[_conn playlists] libraryList]]) {
            stmt = [NSMutableString stringWithFormat:@"SELECT library.file_id%@ FROM library WHERE 1=1 AND ", albumColumn];
            columns = @[PRColInteger];
        } else {
            stmt = [NSMutableString stringWithFormat:
                @"SELECT playlist_items.file_id, playlist_items.playlist_index%@ "
                "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                "WHERE playlist_items.playlist_id = ?%ld AND ",
                albumColumn, (long)bindingIndex];
            bindings[@(bindingIndex)] = _list;
            bindingIndex++;
            columns = @[PRColInteger, PRColInteger];
        }
        
        // Filter for Column Browser
        NSArray *browserAttributes = [_listDescription derivedBrowserAttributes];
        NSArray *browserSelections = [_listDescription browserSelections];
        for (NSInteger i = 0; i < [browserAttributes count]; i++) {
            NSString *grouping = browserAttributes[i];
            NSArray *selection = browserSelections[i];
            
            if ([selection count] != 0 && (id)grouping != [NSNull null]) {
                [stmt appendFormat:@"(library.%@ COLLATE NOCASE2 IN (", [PRLibrary columnNameForItemAttr:grouping]];
                for (NSString *i in selection) {
                    [stmt appendFormat:@"?%ld, ", (long)bindingIndex];
                    bindings[@(bindingIndex)] = i;
                    bindingIndex++;
                }
                [stmt deleteCharactersInRange:NSMakeRange([stmt length] - 2, 2)];
                [stmt appendString:@") "];
                
               if ([[_listDescription derivedBrowserAllowsCompilation][i] boolValue]) {
                   if ([selection containsObject:PRCompilationString]) {
                       [stmt appendString:@"OR library.compilation != 0 "];
                   } else {
                       [stmt appendString:@"AND library.compilation == 0 "];
                   }
               }
                
                [stmt appendString:@") AND "];
            }
        }
        
        // Filter for Search
        NSString *search = [_listDescription search];
        if ([search length] != 0) {
            [stmt appendString:@"(1 = 1 "];
            NSArray *searchTerms = [search componentsSeparatedByString:@" "];
            for (NSString *term in searchTerms) {
                [stmt appendString:[NSString stringWithFormat:@"AND (library.title LIKE ?%ld "
                    "OR library.album LIKE ?%ld "
                    "OR library.composer LIKE ?%ld "
                    "OR library.artist LIKE ?%ld "
                    "OR library.albumArtist LIKE ?%ld "
                    "OR library.comments LIKE ?%ld "
                    ") ", (long)bindingIndex, (long)bindingIndex, (long)bindingIndex, (long)bindingIndex, (long)bindingIndex, (long)bindingIndex]];
                
                bindings[@(bindingIndex)] = [NSString stringWithFormat:@"%%%@%%",term];
                bindingIndex++;
            }
            [stmt appendString:@") AND "];
        }
        
        // Delete 'AND '
        [stmt deleteCharactersInRange:NSMakeRange([stmt length] - 4, 4)];
        
        // Sort Clause
        {
            PRLibraryViewMode viewMode = [_listDescription viewMode];
            PRListSort *sort;
            NSInteger asc;
            if (viewMode == PRLibraryViewModeList) {
                sort = [_listDescription listViewSortAttr];
                asc = [_listDescription listViewAscending];
            } else {
                sort = [_listDescription albumListViewSortAttr];
                asc = [_listDescription albumListViewAscending];
            }
            
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
            NSString *ascending = asc ? @"ASC" : @"DESC";
            
            if (sort == PRItemAttrArtist || sort == PRItemAttrArtistAlbumArtist) {
                [stmt appendFormat:@"ORDER BY CASE WHEN compilation == 0 THEN %@ ELSE 'compilation' END COLLATE NOCASE2 %@, "
                 "album COLLATE NOCASE2 %@, discNumber %@, trackNumber %@",
                 sortColumnName, ascending, ascending, ascending, ascending];
            } else {
                [stmt appendFormat:@"ORDER BY %@ COLLATE NOCASE2 %@, album COLLATE NOCASE2 %@, discNumber %@, trackNumber %@",
                 sortColumnName, ascending, ascending, ascending, ascending];
            }
        }
        
        NSArray *rlt = nil;
        success = [_conn zExecute:stmt bindings:bindings columns:columns out:&rlt];
        if (!success) {
            return nil;
        }
        _items = rlt;
    }
    {
        // NSArray *rlt = nil;
        // NSString *stmt = @"SELECT SUM(time), SUM(size), count(libraryViewSource.file_id) "
        //     "FROM libraryViewSource JOIN library ON libraryViewSource.file_id = library.file_id";
        // BOOL success = [conn zExecute:stmt bindings:nil columns:@[PRColInteger, PRColInteger, PRColInteger] out:&rlt];
        // if (!success) {
        //     return nil;
        // }
        // _info = @[rlt[0][0], rlt[0][1], rlt[0][2]];
    }

    if ([_listDescription viewMode] == PRLibraryViewModeAlbumList) {
        if ([_items count] == 0) {
            _albumCounts = @[];
        } else if ([_items count] == 1) {
            _albumCounts = @[@1];
        } else {
            NSMutableArray *array = [NSMutableArray array];
            NSInteger count = 1;
            NSInteger i = 0;
            while (i < [_items count] - 1) {
                NSString *string = _items[i][1];
                NSString *nextString = _items[i + 1][1];
                if ([string noCaseCompare:nextString]) {
                    [array addObject:@(count)];
                    count = 0;
                }
                count++;
                i++;
            }
            [array addObject:@(count)];
            _albumCounts = array;
        }
    }
    return self;
}

#pragma mark - API

@synthesize list = _list;
@synthesize info = _info;
@synthesize albumCounts = _albumCounts;
@synthesize listDescription = _listDescription;

- (NSInteger)count {
    return [_items count];
}

- (PRItemID *)itemForRow:(NSInteger)row {
    return _items[row][0];
}

- (NSInteger)playlistIndexForRow:(NSInteger)row {
    return [_items[row][1] integerValue];
}

- (NSInteger)rowForItem:(PRItemID *)item {
    return [_items indexOfObject:@[item]];
}

- (id)valueForRow:(NSInteger)row attribute:(PRItemAttr *)attr andCacheAttributes:(NSArray *(^)(void))attributes {
    if (_cachedAttrValues && _cachedRow == row && _cachedAttrs && [_cachedAttrs indexOfObject:attr] != NSNotFound) {
        return _cachedAttrValues[[_cachedAttrs indexOfObject:attr]];
    }
    if (!_cachedStatement || ![_cachedAttrs containsObject:attr]) {
        NSArray *temp = attributes();
        if (![temp containsObject:attr]) {
            temp = [temp arrayByAddingObject:attr];
        }
        _cachedAttrs = temp;
        NSMutableString *stmt = [NSMutableString stringWithString:@"SELECT "];
        NSMutableArray *cols = [NSMutableArray array];
        for (PRItemAttr *i in _cachedAttrs) {
            [stmt appendFormat:@"%@, ", [[PRLibrary class] columnNameForItemAttr:i]];
            [cols addObject:[PRLibrary columnTypeForItemAttr:i]];
        }
        [stmt deleteCharactersInRange:NSMakeRange([stmt length] - 2, 2)];
        [stmt appendString:@" FROM library WHERE file_id = ?1"];
        _cachedStatement = [[PRStatement alloc] initWithString:stmt bindings:nil columns:cols connection:_conn];
    }
    [_cachedStatement setBindings:@{@1:_items[row][0]}];
    NSArray *rlt = nil;
    [_cachedStatement zExecute:&rlt];
    _cachedRow = row;
    _cachedAttrValues = rlt[0];
    return rlt[0][[_cachedAttrs indexOfObject:attr]];
}

- (NSInteger)firstRowWithValue:(id)value forAttr:(PRItemAttr *)attr {
    return 0;
}

@end

@interface PRBrowserDescription ()
@property (nonatomic, readonly) NSArray *items;
@property (nonatomic, readonly) PRListID *list;
@end

@implementation PRBrowserDescription {
    NSArray *_items;
    BOOL _hasCompilation;
    NSIndexSet *_selection;
    PRListID *_list;
    PRItemAttr *_attribute;
    NSString *_title;
}

@synthesize items = _items;
@synthesize hasCompilation = _hasCompilation;
@synthesize selection = _selection;
@synthesize list = _list;
@synthesize attribute = _attribute;
@synthesize title = _title;

- (id)initWithList:(PRListID *)list browser:(NSInteger)browser connection:(PRConnection *)conn {
    if (!(self = [super init])) {return nil;}
    _list = list;
    PRList *listDescription = nil;
    BOOL success = [[conn playlists] zListForListID:list out:&listDescription];
    if (!success) {
        return nil;
    }
        
    {
        // Do nothing if no grouping
        NSString *grouping = [listDescription derivedBrowserAttributes][browser];
        NSString *groupingColumnName = [PRLibrary columnNameForItemAttr:grouping];
        if ((id)grouping == [NSNull null]) {
            _items = @[];
        } else {
            _attribute = [listDescription browserAttributes][browser];
            
            // Populate browser
            NSInteger bindingIndex = 1;
            NSMutableString *stmt;
            NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
            if ([_list isEqual:[[conn playlists] libraryList]]) {
                stmt = [NSMutableString stringWithFormat:@"SELECT library.%@, library.compilation FROM library WHERE ", groupingColumnName];
            } else {
                stmt = [NSMutableString stringWithFormat:@"SELECT library.%@, library.compilation "
                    "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
                    "WHERE playlist_items.playlist_id = ?%ld AND ", groupingColumnName, (long)bindingIndex];
                bindings[@(bindingIndex)] = _list;
                bindingIndex++;
            }
            
            // Filter for other browsers
            for (NSInteger i = 0; i < browser; i++) {
                NSString *grouping2 = [listDescription derivedBrowserAttributes][i];
                NSArray *selection = [listDescription browserSelections][i];
                
                if ([selection count] != 0 && (id)grouping2 != [NSNull null]) {
                    [stmt appendFormat:@"(%@ COLLATE NOCASE2 IN (", [PRLibrary columnNameForItemAttr:grouping2]];
                    for (NSString *i in selection) {
                        [stmt appendFormat:@"?%ld, ", (long)bindingIndex];
                        bindings[@(bindingIndex)] = i;
                        bindingIndex++;
                    }
                    [stmt deleteCharactersInRange:NSMakeRange([stmt length] - 2, 2)];
                    [stmt appendString:@") "];
                    
                    if ([[listDescription derivedBrowserAllowsCompilation][i] boolValue]) {
                        if ([selection containsObject:PRCompilationString]) {
                            [stmt appendString:@"OR library.compilation != 0 "];
                        } else {
                            [stmt appendString:@"AND library.compilation == 0 "];
                        }
                    }
                    
                    [stmt appendString:@") AND "];
                }
            }
            
            // Filter for search
            NSString *search = [listDescription search];
            if ([search length] != 0) {
                [stmt appendString:@"(1 = 1 "];
                NSArray *searchTerms = [search componentsSeparatedByString:@" "];
                for (NSString *term in searchTerms) {
                    [stmt appendString:[NSString stringWithFormat:@"AND (library.title LIKE ?%ld "
                        "OR library.album LIKE ?%ld "
                        "OR library.composer LIKE ?%ld "
                        "OR library.artist LIKE ?%ld "
                        "OR library.albumArtist LIKE ?%ld "
                        "OR library.comments LIKE ?%ld "
                        ") ", (long)bindingIndex, (long)bindingIndex, (long)bindingIndex, (long)bindingIndex, (long)bindingIndex, (long)bindingIndex]];
                    
                    bindings[@(bindingIndex)] = [NSString stringWithFormat:@"%%%@%%",term];
                    bindingIndex++;
                }
                [stmt appendString:@") AND "];
            }
            
            // Filter for empty
            [stmt appendFormat:@"%@ != '' COLLATE NOCASE2 ", groupingColumnName];
            
            // Group and Sort
            BOOL browserAllowsCompilation = [[listDescription derivedBrowserAllowsCompilation][browser] boolValue];
            if (browserAllowsCompilation) {
                [stmt appendFormat:@"GROUP BY compilation, %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", groupingColumnName, groupingColumnName];
            } else {
                [stmt appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", groupingColumnName, groupingColumnName];
            }
            
            // Execute
            NSArray *rlt = nil;
            BOOL success = [conn zExecute:stmt bindings:bindings columns:@[PRColString, PRColInteger] out:&rlt];
            if (!success) {
                return nil;
            }
            _items = [rlt PRMap:^(NSInteger idx, NSArray *obj){
                if (browserAllowsCompilation && [obj[1] integerValue]) {
                    _hasCompilation = YES;
                }
                return obj[0];
            }];
        }
    }
    
    {
        NSArray *selection = [listDescription browserSelections][browser];
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        for (NSInteger i = 0; i < [_items count]; i++) {
            NSString *browserString = _items[i];
            for (NSInteger j = 0; j < [selection count]; j++) {
                NSString *selectionString = selection[j];
                if ([browserString noCaseCompare:selectionString] == NSOrderedSame) {
                    [indexSet addIndex:_hasCompilation ? i + 2 : i + 1];
                }
            }
        }
        if (_hasCompilation && [selection containsObject:PRCompilationString]) {
            [indexSet addIndex:1];
        }
        if ([indexSet count] == 0) {
            [indexSet addIndex:0];
        }
        _selection = indexSet;
    }
    
    {
        _title = [PRLibrary titleForItemAttr:_attribute];
    }
    
    return self;
}

- (NSInteger)count {
    return [_items count] + 1;
}

- (NSIndexSet *)selection {
    return _selection;
}

- (NSString *)valueForRow:(NSInteger)row {
    if (row == 0) {
        return [NSString stringWithFormat:@"All (%ld %@s)", [self count], [PRLibrary titleForItemAttr:[self attribute]]];
    } else if (_hasCompilation && row == 1) {
        return @"Compilations  ";
    } else if (_hasCompilation && row > 1) {
        return _items[row-2];
    } else {
        return _items[row-1];
    }
}

- (BOOL)isEqualExceptSelection:(PRBrowserDescription *)object {
    return [object isKindOfClass:[PRBrowserDescription class]] &&
        [_items isEqual:[object items]] && 
        _hasCompilation == [object hasCompilation] && 
        [_list isEqual:[object list]] && 
        [_attribute isEqual:[object attribute]] && 
        [_title isEqual:[object title]];
}

@end
