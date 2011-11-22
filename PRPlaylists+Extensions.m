#import "PRPlaylists+Extensions.h"


@implementation PRPlaylists (PRPlaylists_Extensions)

- (NSMutableDictionary *)browserInfoForPlaylist:(PRPlaylist)playlist
{
    NSData *browserInfoData = [self valueForPlaylist:playlist attribute:PRBrowserInfoPlaylistAttribute];
	NSDictionary *browserInfo = [NSPropertyListSerialization propertyListFromData:browserInfoData 
                                                                 mutabilityOption:0 
                                                                           format:nil 
                                                                 errorDescription:nil];
    if (!browserInfo || ![browserInfo isKindOfClass:[NSDictionary class]] ||
        ([browserInfo objectForKey:@"isVertical"] && ![[browserInfo objectForKey:@"isVertical"] isKindOfClass:[NSNumber class]]) ||
        ([browserInfo objectForKey:@"verticalBrowser3Width"] && ![[browserInfo objectForKey:@"verticalBrowser3Width"] isKindOfClass:[NSNumber class]]) ||
        ([browserInfo objectForKey:@"horizontalBrowserHeight"] && ![[browserInfo objectForKey:@"horizontalBrowserHeight"] isKindOfClass:[NSNumber class]])) {
        return [NSMutableDictionary dictionary];
    }
    return [NSMutableDictionary dictionaryWithDictionary:browserInfo];
}

- (void)setBrowserInfo:(NSMutableDictionary *)browserInfo forPlaylist:(PRPlaylist)playlist
{
    NSData *browserInfoData = [NSPropertyListSerialization dataFromPropertyList:browserInfo 
                                                                         format:NSPropertyListXMLFormat_v1_0 
                                                               errorDescription:nil];
    [self setValue:browserInfoData forPlaylist:playlist attribute:PRBrowserInfoPlaylistAttribute];

}

- (int)isVerticalForPlaylist:(PRPlaylist)playlist
{
    NSNumber *isVertical = [[self browserInfoForPlaylist:playlist] objectForKey:@"isVertical"];
    if (isVertical) {
        return [isVertical intValue];
    } else {
        if (playlist == [self libraryPlaylist]) {
            return PRBrowserPositionVertical;
        } else {
            return PRBrowserPositionHidden;
        }
    }
}

- (void)setVertical:(int)vertical forPlaylist:(PRPlaylist)playlist
{
    NSMutableDictionary *browserInfo = [self browserInfoForPlaylist:playlist];
    [browserInfo setObject:[NSNumber numberWithInt:vertical] forKey:@"isVertical"];
    [self setBrowserInfo:browserInfo forPlaylist:playlist];
}

- (float)verticalBrowser3WidthForPlaylist:(PRPlaylist)playlist
{
    NSNumber *browserWidth = [[self browserInfoForPlaylist:playlist] objectForKey:@"verticalBrowser3Width"];
    if (browserWidth) {
        return [browserWidth floatValue];
    } else {
        return 200;
    }
}

- (void)setVerticalBrowser3Width:(float)width forPlaylist:(PRPlaylist)playlist 
{
    NSMutableDictionary *browserInfo = [self browserInfoForPlaylist:playlist];
    [browserInfo setObject:[NSNumber numberWithFloat:width] forKey:@"verticalBrowser3Width"];
    [self setBrowserInfo:browserInfo forPlaylist:playlist];
}

- (float)horizontalBrowserHeightForPlaylist:(PRPlaylist)playlist
{
    NSNumber *browserHeight = [[self browserInfoForPlaylist:playlist] objectForKey:@"horizontalBrowserHeight"];
    if (browserHeight) {
        return [browserHeight floatValue];
    } else {
        return 250;
    }
}

- (void)setHorizontalBrowserHeight:(float)height forPlaylist:(PRPlaylist)playlist
{
    NSMutableDictionary *browserInfo = [self browserInfoForPlaylist:playlist];
    [browserInfo setObject:[NSNumber numberWithFloat:height] forKey:@"horizontalBrowserHeight"];
    [self setBrowserInfo:browserInfo forPlaylist:playlist];
}

- (BOOL)listViewAscendingForPlaylist:(PRPlaylist)playlist
{
    return [[self valueForPlaylist:playlist 
                         attribute:PRListViewAscendingPlaylistAttribute] boolValue];
}

- (void)setListViewAscending:(BOOL)ascending forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithBool:ascending] 
       forPlaylist:playlist 
         attribute:PRListViewAscendingPlaylistAttribute];
}

- (BOOL)albumListViewAscendingForPlaylist:(PRPlaylist)playlist
{
    return [[self valueForPlaylist:playlist 
                         attribute:PRAlbumListViewAscendingPlaylistAttribute] boolValue];
}

- (void)setAlbumListViewAscending:(BOOL)ascending forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithBool:ascending] 
       forPlaylist:playlist 
         attribute:PRAlbumListViewAscendingPlaylistAttribute];
}

- (PRFileAttribute)listViewSortColumnForPlaylist:(PRPlaylist)playlist
{
    return [[self valueForPlaylist:playlist attribute:PRListViewSortColumnPlaylistAttribute] intValue];
}

- (void)setListViewSortColumn:(PRFileAttribute)sortColumn forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithInt:sortColumn] forPlaylist:playlist attribute:PRListViewSortColumnPlaylistAttribute];
}

- (PRFileAttribute)albumListViewSortColumnForPlaylist:(PRPlaylist)playlist
{
    return [[self valueForPlaylist:playlist attribute:PRAlbumListViewSortColumnPlaylistAttribute] intValue];
}

- (void)setAlbumListViewSortColumn:(PRFileAttribute)sortColumn forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithInt:sortColumn] forPlaylist:playlist attribute:PRAlbumListViewSortColumnPlaylistAttribute];
}

- (NSArray *)listViewColumnInfoForPlaylist:(PRPlaylist)playlist
{
    NSData *columnInfoData = [self valueForPlaylist:playlist attribute:PRListViewColumnInfoPlaylistAttribute];
    if ([columnInfoData isEqualToData:[NSData data]]) {
        NSString *defaultData  = [[NSBundle mainBundle] pathForResource:@"PRListViewTableColumnsInfo" ofType:@"plist"];
        columnInfoData = [NSData dataWithContentsOfFile:defaultData];
    }
    NSArray *columnInfo = [NSPropertyListSerialization propertyListFromData:columnInfoData 
                                                           mutabilityOption:0 
                                                                     format:nil
                                                           errorDescription:nil];
    return columnInfo;
}

- (void)setListViewColumnInfo:(NSArray *)columnInfo forPlaylist:(PRPlaylist)playlist
{
    NSData *columnInfoData = [NSPropertyListSerialization dataFromPropertyList:columnInfo 
                                                                        format:NSPropertyListXMLFormat_v1_0 
                                                              errorDescription:nil];
    [self setValue:columnInfoData forPlaylist:playlist attribute:PRListViewColumnInfoPlaylistAttribute];
}

- (NSArray *)albumListViewColumnInfoForPlaylist:(PRPlaylist)playlist
{
    NSData *columnInfoData = [self valueForPlaylist:playlist attribute:PRAlbumListViewColumnInfoPlaylistAttribute];
    if ([columnInfoData isEqualToData:[NSData data]]) {
        NSString *defaultData  = [[NSBundle mainBundle] pathForResource:@"PRAlbumListViewTableColumnsInfo" ofType:@"plist"];
        columnInfoData = [NSData dataWithContentsOfFile:defaultData];
    }
    NSArray *columnInfo = [NSPropertyListSerialization propertyListFromData:columnInfoData 
                                                           mutabilityOption:0 
                                                                     format:nil
                                                           errorDescription:nil];
    return columnInfo;
}

- (void)setAlbumListViewColumnInfo:(NSArray *)columnInfo forPlaylist:(PRPlaylist)playlist
{
    NSData *columnInfoData = [NSPropertyListSerialization dataFromPropertyList:columnInfo 
                                                                        format:NSPropertyListXMLFormat_v1_0 
                                                              errorDescription:nil];
    [self setValue:columnInfoData forPlaylist:playlist attribute:PRAlbumListViewColumnInfoPlaylistAttribute];
}

- (NSArray *)selectionForBrowser:(int)browser playlist:(PRPlaylist)playlist
{
    switch (browser) {
        case 1:
            return [self browser1SelectionForPlaylist:playlist];
            break;
        case 2:
            return [self browser2SelectionForPlaylist:playlist];
            break;
        case 3:
            return [self browser3SelectionForPlaylist:playlist];
            break;
        default:
            return [NSArray array];
            break;
    }
}

- (void)setSelection:(NSArray *)selection forBrowser:(int)browser playlist:(PRPlaylist)playlist
{
    switch (browser) {
        case 1:
            [self setBrowser1Selection:selection forPlaylist:playlist];
            break;
        case 2:
            [self setBrowser2Selection:selection forPlaylist:playlist];
            break;
        case 3:
            [self setBrowser3Selection:selection forPlaylist:playlist];
            break;
        default:
            break;
    }
}

- (NSArray *)browser1SelectionForPlaylist:(PRPlaylist)playlist
{
    NSData *selectionData = [self valueForPlaylist:playlist attribute:PRBrowser1SelectionPlaylistAttribute];
    if ([selectionData length] == 0) {
        return [NSArray array];
    }
    @try {
        NSArray *selection = [NSKeyedUnarchiver unarchiveObjectWithData:selectionData];
        return selection;
    } @catch (NSException *exception) {
    }
    return [NSArray array];
}

- (void)setBrowser1Selection:(NSArray *)selection forPlaylist:(PRPlaylist)playlist
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selection];
    [self setValue:data forPlaylist:playlist attribute:PRBrowser1SelectionPlaylistAttribute];
}

- (NSArray *)browser2SelectionForPlaylist:(PRPlaylist)playlist
{
    NSData *selectionData = [self valueForPlaylist:playlist attribute:PRBrowser2SelectionPlaylistAttribute];
    if ([selectionData length] == 0) {
        return [NSArray array];
    }
    @try {
        NSArray *selection = [NSKeyedUnarchiver unarchiveObjectWithData:selectionData];
        return selection;
    } @catch (NSException *exception) {
    }
    return [NSArray array];
}

- (void)setBrowser2Selection:(NSArray *)selection forPlaylist:(PRPlaylist)playlist
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selection];
    [self setValue:data forPlaylist:playlist attribute:PRBrowser2SelectionPlaylistAttribute];
}

- (NSArray *)browser3SelectionForPlaylist:(PRPlaylist)playlist
{
    NSData *selectionData = [self valueForPlaylist:playlist attribute:PRBrowser3SelectionPlaylistAttribute];
    if ([selectionData length] == 0) {
        return [NSArray array];
    }
    @try {
        NSArray *selection = [NSKeyedUnarchiver unarchiveObjectWithData:selectionData];
        return selection;
    } @catch (NSException *exception) {
    }
    return [NSArray array];
}

- (void)setBrowser3Selection:(NSArray *)selection forPlaylist:(PRPlaylist)playlist
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selection];
    [self setValue:data forPlaylist:playlist attribute:PRBrowser3SelectionPlaylistAttribute];
}

- (int)attributeForBrowser:(int)browser playlist:(PRPlaylist)playlist
{
    PRPlaylistAttribute attribute;
    switch (browser) {
        case 1:
            attribute = PRBrowser1AttributePlaylistAttribute;
            break;
        case 2:
            attribute = PRBrowser2AttributePlaylistAttribute;
            break;
        case 3:
            attribute = PRBrowser3AttributePlaylistAttribute;
            break;
        default:
            break;
    }
    return [[self valueForPlaylist:playlist attribute:attribute] intValue];
}

- (void)setAttribute:(PRFileAttribute)attribute forBrowser:(int)browser playlist:(PRPlaylist)playlist
{
    PRPlaylistAttribute playlistAttribute;
    switch (browser) {
        case 1:
            playlistAttribute = PRBrowser1AttributePlaylistAttribute;
            break;
        case 2:
            playlistAttribute = PRBrowser2AttributePlaylistAttribute;
            break;
        case 3:
            playlistAttribute = PRBrowser3AttributePlaylistAttribute;
            break;
        default:
            break;
    }
    [self setValue:[NSNumber numberWithInt:attribute] forPlaylist:playlist attribute:playlistAttribute];
}

- (int)browser1AttributeForPlaylist:(PRPlaylist)playlist
{
    NSNumber *attribute = [self valueForPlaylist:playlist attribute:PRBrowser1AttributePlaylistAttribute];
    return [attribute intValue];
}

- (void)setBrowser1Attribute:(PRFileAttribute)attribute forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithInt:attribute] forPlaylist:playlist attribute:PRBrowser1AttributePlaylistAttribute];
}

- (int)browser2AttributeForPlaylist:(PRPlaylist)playlist
{
    NSNumber *attribute = [self valueForPlaylist:playlist attribute:PRBrowser2AttributePlaylistAttribute];
    return [attribute intValue];
}

- (void)setBrowser2Attribute:(PRFileAttribute)attribute forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithInt:attribute] forPlaylist:playlist attribute:PRBrowser2AttributePlaylistAttribute];
}

- (int)browser3AttributeForPlaylist:(PRPlaylist)playlist
{
    NSNumber *attribute = [self valueForPlaylist:playlist attribute:PRBrowser3AttributePlaylistAttribute];
    return [attribute intValue];
}

- (void)setBrowser3Attribute:(PRFileAttribute)attribute forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithInt:attribute] forPlaylist:playlist attribute:PRBrowser3AttributePlaylistAttribute];
}

- (PRPlaylistType)typeForPlaylist:(PRPlaylist)playlist
{
    return [[self valueForPlaylist:playlist attribute:PRTypePlaylistAttribute] intValue];
}

- (void)setType:(PRPlaylistType)type forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithInt:type] forPlaylist:playlist attribute:PRTypePlaylistAttribute];
}

- (NSString *)titleForPlaylist:(PRPlaylist)playlist
{
    return [self valueForPlaylist:playlist attribute:PRTitlePlaylistAttribute];
}

- (void)setTitle:(NSString *)title forPlaylist:(PRPlaylist)playlist
{
    [self setValue:title forPlaylist:playlist attribute:PRTitlePlaylistAttribute];
}

- (NSString *)searchForPlaylist:(PRPlaylist)playlist
{
    return [self valueForPlaylist:playlist attribute:PRSearchPlaylistAttribute];
}

- (void)setSearch:(NSString *)search forPlaylist:(PRPlaylist)playlist
{
    [self setValue:search forPlaylist:playlist attribute:PRSearchPlaylistAttribute];
}

- (PRLibraryViewMode)libraryViewModeForPlaylist:(PRPlaylist)playlist
{
    return [[self valueForPlaylist:playlist attribute:PRLibraryViewModePlaylistAttribute] intValue];
}

- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode forPlaylist:(PRPlaylist)playlist
{
    [self setValue:[NSNumber numberWithInt:libraryViewMode] forPlaylist:playlist attribute:PRLibraryViewModePlaylistAttribute];
}

- (NSData *)ruleForPlaylist:(PRPlaylist)playlist
{
    return [self valueForPlaylist:playlist attribute:PRRulesPlaylistAttribute];
}

- (void)setRule:(NSData *)rule forPlaylist:(PRPlaylist)playlist
{
    [self setValue:rule forPlaylist:playlist attribute:PRRulesPlaylistAttribute];
}

@end