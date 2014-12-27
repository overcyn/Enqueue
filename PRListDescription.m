#import "PRListDescription.h"
#import "NSArray+Extensions.h"
#import "PRConnection.h"
#import "PRDefaults.h"


@implementation PRListDescription {
    PRList *_list;
    NSMutableArray *_attributes;
    NSArray *_keys;
}

@synthesize list = _list;

- (id)initWithList:(PRList *)list connection:(PRConnection *)conn {
    if ((self = [super init])) {
        _list = list;
        _keys = @[PRListAttrTitle, PRListAttrType, PRListAttrRules, PRListAttrViewMode, PRListAttrListViewInfo, 
            PRListAttrListViewSortAttr, PRListAttrListViewAscending, PRListAttrAlbumListViewInfo, PRListAttrAlbumListViewSortAttr, 
            PRListAttrAlbumListViewAscending, PRListAttrSearch, PRListAttrBrowser1Attr, PRListAttrBrowser1Selection, 
            PRListAttrBrowser2Attr, PRListAttrBrowser2Selection, PRListAttrBrowser3Attr, PRListAttrBrowser3Selection, 
            PRListAttrBrowserInfo];
        
        NSArray *rlt = nil;
        NSMutableArray *cols = [NSMutableArray array];
        NSMutableString *stm = [NSMutableString stringWithString:@"SELECT "];
        for (PRListAttr *i in _keys) {
            [stm appendFormat:@"%@, ", [PRPlaylists columnNameForListAttr:i]];
            [cols addObject:[PRPlaylists columnTypeForListAttr:i]];
        }
        [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
        [stm appendString:@"FROM playlists WHERE playlist_id = ?1"];
        BOOL success = [conn zExecute:stm bindings:@{@1:list} columns:cols out:&rlt];
        if (!success || [rlt count] != 1) {
            return nil;
        }
        _attributes = [rlt[0] mutableCopy];
    }
    return self;
}

- (BOOL)writeToConnection:(PRConnection *)conn {
    NSMutableString *stm = [NSMutableString stringWithString:@"UPDATE playlists SET "];
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    NSInteger bindingIndex = 1;
    for (PRListAttr *i in _keys) {
        [stm appendFormat:@"%@ = ?%ld, ", [PRPlaylists columnNameForListAttr:i], (long)bindingIndex];
        bindings[@(bindingIndex)] = _attributes[[_keys indexOfObject:i]];
        bindingIndex += 1;
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
    [stm appendFormat:@"WHERE playlist_id = %@", _list];
    return [conn zExecute:stm bindings:bindings columns:nil out:nil];
}

- (void)setValue:(id)value forAttr:(PRListAttr *)attr {
    _attributes[[_keys indexOfObject:attr]] = value;
}

- (id)valueForAttr:(PRListAttr *)attr {
    return _attributes[[_keys indexOfObject:attr]];
}

- (NSMutableDictionary *)browserInfo {
    NSData *data = _attributes[[_keys indexOfObject:PRListAttrBrowserInfo]];
    NSDictionary *info = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:nil errorDescription:nil];
    if (!info || ![info isKindOfClass:[NSDictionary class]] ||
        (info[@"isVertical"] && ![info[@"isVertical"] isKindOfClass:[NSNumber class]]) ||
        (info[@"verticalBrowser3Width"] && ![info[@"verticalBrowser3Width"] isKindOfClass:[NSNumber class]]) ||
        (info[@"horizontalBrowserHeight"] && ![info[@"horizontalBrowserHeight"] isKindOfClass:[NSNumber class]])) {
        return [NSMutableDictionary dictionary];
    }
    return [NSMutableDictionary dictionaryWithDictionary:info];
}

- (void)setBrowserInfo:(NSDictionary *)value {
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:value format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    _attributes[[_keys indexOfObject:PRListAttrBrowserInfo]] = data;
}

- (PRBrowserPosition)vertical {
    NSNumber *value = [self browserInfo][@"isVertical"];
    if (value) {
        return [value integerValue];
    }
    return PRBrowserPositionHorizontal;
}

- (void)setVertical:(PRBrowserPosition)value {
    NSMutableDictionary *info = [self browserInfo];
    info[@"isVertical"] = @(value);
    [self setBrowserInfo:info];
}

- (CGFloat)verticalBrowserWidth {
    NSNumber *value = [self browserInfo][@"verticalBrowser3Width"];
    if (value) {
        return [value floatValue];
    } 
    return 200;
}

- (void)setVerticalBrowserWidth:(CGFloat)value {
    NSMutableDictionary *info = [self browserInfo];
    info[@"verticalBrowser3Width"] = @(value);
    [self setBrowserInfo:info];
}

- (CGFloat)horizontalBrowserHeight {
    NSNumber *value = [self browserInfo][@"horizontalBrowserHeight"];
    if (value) {
        return [value floatValue];
    } 
    return 250;
}

- (void)setHorizontalBrowserHeight:(CGFloat)value {
    NSMutableDictionary *info = [self browserInfo];
    info[@"horizontalBrowserHeight"] = @(value);
    [self setBrowserInfo:info];
}

- (BOOL)listViewAscending {
    return [_attributes[[_keys indexOfObject:PRListAttrListViewAscending]] boolValue];
}

- (void)setListViewAscending:(BOOL)value {
    _attributes[[_keys indexOfObject:PRListAttrListViewAscending]] = @(value);
}

- (BOOL)albumListViewAscending {
    return [_attributes[[_keys indexOfObject:PRListAttrAlbumListViewAscending]] boolValue];
}

- (void)setAlbumListViewAscending:(BOOL)value {
    _attributes[[_keys indexOfObject:PRListAttrAlbumListViewAscending]] = @(value);
}

- (PRItemAttr *)listViewSortAttr {
    NSNumber *value = _attributes[[_keys indexOfObject:PRListAttrListViewSortAttr]];
    return [PRPlaylists sortAttrForInternal:value];
}

- (void)setListViewSortAttr:(PRItemAttr *)value {
    _attributes[[_keys indexOfObject:PRListAttrListViewSortAttr]] = [PRPlaylists internalForSortAttr:value];
}

- (PRItemAttr *)albumListViewSortAttr {
    NSNumber *value = _attributes[[_keys indexOfObject:PRListAttrAlbumListViewSortAttr]];
    return [PRPlaylists sortAttrForInternal:value];
}

- (void)setAlbumListViewSortAttr:(PRItemAttr *)value {
    _attributes[[_keys indexOfObject:PRListAttrAlbumListViewSortAttr]] = [PRPlaylists internalForSortAttr:value];
}

- (NSArray *)browserSelections {
    NSArray *attrs = @[PRListAttrBrowser1Selection, PRListAttrBrowser2Selection, PRListAttrBrowser3Selection];
    return [attrs PRMap:^(NSInteger idx, PRListAttr *obj) {
        NSData *value = _attributes[[_keys indexOfObject:obj]];
        if ([value length] == 0) {
            return @[];
        }
        @try {
            NSArray *selection = [NSKeyedUnarchiver unarchiveObjectWithData:value];
            for (NSString *i in selection) {
                if (![i isKindOfClass:[NSString class]]) {
                    return @[];
                }
            }
            return selection;
        } @catch (NSException *exception) {
            return @[];
        }
    }];
}

- (void)setBrowserSelections:(NSArray *)value {
    if ([value count] != 3) {
        return;
    }
    for (NSInteger i = 0; i < 3; i++) {
        PRListAttr *attr;
        if (i == 0) {
            attr = PRListAttrBrowser1Selection;
        } else if (i == 1) {
            attr = PRListAttrBrowser2Selection;
        } else if (i == 2) {
            attr = PRListAttrBrowser3Selection;
        }
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value[i]];
        _attributes[[_keys indexOfObject:attr]] = data;
    }
}

- (NSArray *)browserAttributes {
    NSArray *attrs = @[PRListAttrBrowser1Attr, PRListAttrBrowser2Attr, PRListAttrBrowser3Attr];
    return [attrs PRMap:^(NSInteger idx, PRListAttr *obj) {
        return [PRLibrary itemAttrForInternal:_attributes[[_keys indexOfObject:obj]]] ?: [NSNull null];
    }];
}

- (void)setBrowserAttributes:(NSArray *)value {
    if ([value count] != 3) {
        return;
    }
    for (NSInteger i = 0; i < 3; i++) {
        PRListAttr *attr;
        if (i == 0) {
            attr = PRListAttrBrowser1Attr;
        } else if (i == 1) {
            attr = PRListAttrBrowser2Attr;
        } else if (i == 2) {
            attr = PRListAttrBrowser3Attr;
        }
        if (value[i] != [NSNull null]) {
            _attributes[[_keys indexOfObject:attr]] = [PRLibrary internalForItemAttr:value[i]];
        } else {
            _attributes[[_keys indexOfObject:attr]] = @0;
        }
    }
}

- (NSArray *)listViewInfo {
    NSData *columnInfoData = _attributes[[_keys indexOfObject:PRListAttrListViewInfo]];
    if ([columnInfoData isEqualToData:[NSData data]]) {
        NSString *defaultData  = [[NSBundle mainBundle] pathForResource:@"PRListViewTableColumnsInfo" ofType:@"plist"];
        columnInfoData = [NSData dataWithContentsOfFile:defaultData];
    }
    return [NSPropertyListSerialization propertyListFromData:columnInfoData mutabilityOption:0 format:nil errorDescription:nil];
}

- (void)setListViewInfo:(NSArray *)value {
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:value format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    _attributes[[_keys indexOfObject:PRListAttrListViewInfo]] = data;
}

- (NSArray *)albumListViewInfo {
    NSData *columnInfoData = _attributes[[_keys indexOfObject:PRListAttrAlbumListViewInfo]];
    if ([columnInfoData isEqualToData:[NSData data]]) {
        NSString *defaultData  = [[NSBundle mainBundle] pathForResource:@"PRAlbumListViewTableColumnsInfo" ofType:@"plist"];
        columnInfoData = [NSData dataWithContentsOfFile:defaultData];
    }
    return [NSPropertyListSerialization propertyListFromData:columnInfoData mutabilityOption:0 format:nil errorDescription:nil];
}

- (void)setAlbumListViewInfo:(NSArray *)value {
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:value format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    _attributes[[_keys indexOfObject:PRListAttrAlbumListViewInfo]] = data;
}

- (PRListType *)type {
    return [PRPlaylists listTypeForInternal:_attributes[[_keys indexOfObject:PRListAttrType]]];
}

- (void)setType:(PRListType *)value {
    _attributes[[_keys indexOfObject:PRListAttrType]] = [PRPlaylists internalForListType:value];
}

- (NSString *)title {
    return _attributes[[_keys indexOfObject:PRListAttrTitle]];
}

- (void)setTitle:(NSString *)value {
    _attributes[[_keys indexOfObject:PRListAttrTitle]] = value;
}

- (NSString *)search {
    return _attributes[[_keys indexOfObject:PRListAttrSearch]];
}

- (void)setSearch:(NSString *)value {
    _attributes[[_keys indexOfObject:PRListAttrSearch]] = value;
}

- (PRLibraryViewMode)viewMode {
    return [_attributes[[_keys indexOfObject:PRListAttrViewMode]] integerValue];
}

- (void)setViewMode:(PRLibraryViewMode)value {
    _attributes[[_keys indexOfObject:PRListAttrViewMode]] = @(value);
}

- (NSDictionary *)rules {
    return nil;
}

- (void)setRules:(NSDictionary *)value {
}

- (NSArray *)derivedBrowserAttributes {
    return [[self browserAttributes] PRMap:^(NSInteger idx, PRListAttr *obj) {
        if (obj == (id)[NSNull null]) {
            return obj;
        } else if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist] && [obj isEqual:PRItemAttrArtist]) {
            return PRItemAttrArtistAlbumArtist;
        } 
        return obj;
    }];
}

- (NSArray *)derivedBrowserAllowsCompilation {
    return [[self browserAttributes] PRMap:^(NSInteger idx, PRItemAttr *obj){
        return @([obj isEqual:PRItemAttrArtist] && [[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]);
    }];
}

@end
