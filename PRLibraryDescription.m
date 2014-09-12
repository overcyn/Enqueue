#import "PRLibraryDescription.h"


@implementation PRLibraryDescription {
    NSArray *_items;
}

- (id)initWithList:(PRList *)list database:(PRDb *)db {
    if ((self = [super init])) {
        
    }
    return self;
}



- (NSInteger)count {
    return [_items count];
}

- (PRItem *)itemForRow:(NSInteger)row {
    
}

- (NSInteger)rowForItem:(PRItem *)item {
    return 0;
}

- (id)valueForRow:(NSInteger)row attribute:(PRItemAttr *)attribute andCacheAttributes:(NSArray *(^)(void))attributes {
    
}

- (NSInteger)firstRowWithValue:(id)value forAttr:(PRItemAttr *)attr {
    
}

- (NSDictionary *)info {
    
}

- (NSArray *)albumCounts {
    
}

/* Browser Accessor */
- (NSInteger)countForBrowser:(NSInteger)browser;
- (NSString *)valueForRow:(NSInteger)row browser:(NSInteger)browser;
- (NSIndexSet *)selectionForBrowser:(NSInteger)browser;
@end


@implementation PRBrowserDescription {
    NSArray *_items;
    BOOL _hasCompilation;
}

- (id)initWithList:(PRList *)list browser:(NSInteger)browser connection:(PRConnection *)conn {
    PRListDescription *listDescription = nil;
    BOOL success = [[conn playlists] zListDescriptionForList:list out:&listDescription];
    if (!success) {
        return nil;
    }

    // Do nothing if no grouping
    NSString *grouping = [listDescription derivedBrowserAttributes][browser-1];
    if ([grouping length] == 0) {
        _items = @[];
        return self;
    }
    
    // Populate browser
    int bindingIndex = 1;
    NSMutableString *stmt;
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    if ([_list isEqual:[[_db playlists] libraryList]]) {
        stmt = [NSMutableString stringWithFormat:@"SELECT library.%@, library.compilation FROM library WHERE ", grouping];
    } else {
        stmt = [NSMutableString stringWithFormat:@"SELECT library.%@, library.compilation "
            "FROM playlist_items JOIN library ON playlist_items.file_id = library.file_id "
            "WHERE playlist_items.playlist_id = ?%d AND ", grouping, bindingIndex];
        bindings[@(bindingIndex)] = _list;
        bindingIndex++;
    }
    
    // Filter for other browsers
    for (int i = 1; i < browser; i++) {
        NSString *grouping2 = [listDescription derivedBrowserAttributes][i-1];
        NSArray *selection = [listDescription browserSelections][i];
        
        if ([selection count] != 0 && [grouping2 length] != 0) {
            // copy rows from library_view_source into temp table that match selection
            [stmt appendFormat:@"(%@ COLLATE NOCASE2 IN (", grouping2];
            for (NSString *i in selection) {
                [stmt appendFormat:@"?%d, ", bindingIndex];
                bindings[@(bindingIndex)] = i;
                bindingIndex++;
            }
            [stmt deleteCharactersInRange:NSMakeRange([stmt length] - 2, 2)];
            [stmt appendString:@") "];
            
            if ([grouping2 isEqual:PRItemAttrArtist] && [[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]) {
                if ([selection containsObject:compilationString]) {
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
            [stmt appendString:[NSString stringWithFormat:@"AND (library.title LIKE ?%d "
                "OR library.album LIKE ?%d "
                "OR library.composer LIKE ?%d "
                "OR library.artist LIKE ?%d "
                "OR library.albumArtist LIKE ?%d "
                "OR library.comments LIKE ?%d "
                ") ", bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex, bindingIndex]];
            
            bindings[@(bindingIndex)] = [NSString stringWithFormat:@"%%%@%%",term];
            bindingIndex++;
        }
        [stmt appendString:@") AND "];
    }
    
    // Filter for empty
    [stmt appendFormat:@"%@ != '' COLLATE NOCASE2 ", grouping];
    
    // Group and Sort
    if ([self compilationForBrowser:browser]) {
        [stmt appendFormat:@"GROUP BY compilation, %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    } else {
        [stmt appendFormat:@"GROUP BY %@ COLLATE NOCASE2 ORDER BY %@ COLLATE NOCASE2 ASC ", grouping, grouping];
    }
    
    // Execute
    NSArray *rlt = nil;
    [_db zExecute:stmt bindings:bindings columns:@[PRColString, PRColInteger] out:&rlt];
    if ([self compilationForBrowser:browser]) {
        _items = [rlt PRMap:^(NSInteger idx, NSArray *obj){
            if ([obj[1] integerValue]) {
                _hasCompilation = YES;
            } else {
                return obj[0];
            }
        }];
    } else {
        _items = [rlt PRMap:^(NSInteger idx, NSArray *obj){
            return obj[0];
        }];
    }
    
    // // Reset if nothing selected
    // NSMutableArray *selection = [NSMutableArray arrayWithArray:[[_db playlists] selectionForBrowser:browser list:_list]];
    // NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    // for (int i = 0; i < [selection count]; i++) {
    //     if ([[selection objectAtIndex:i] isEqualToString:compilationString]) {
    //         if (![self compilationForBrowser:browser] || !_compilation) {
    //             [indexesToRemove addIndex:i];
    //         }
    //     } else {
    //         NSArray *results = [_db execute:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE value COLLATE NOCASE2 = ?1", destinationTableName]
    //                                bindings:@{@1:[selection objectAtIndex:i]}
    //                                 columns:@[PRColInteger]];
    //         if ([[[results objectAtIndex:0] objectAtIndex:0] intValue] == 0) {
    //             [indexesToRemove addIndex:i];
    //         }
    //     }
    // }
    // if ([indexesToRemove count] > 0) {
    //     [selection removeObjectsAtIndexes:indexesToRemove];
    //     [[_db playlists] setSelection:selection forBrowser:browser list:_list];
    // }
    return YES;
}

@end