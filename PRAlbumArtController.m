#import "PRAlbumArtController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRDefaults.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NSImage+Extensions.h"
#import "NSArray+Extensions.h"

@interface PRAlbumArtController ()
@end

@implementation PRAlbumArtController {
    __weak PRDb *_db;
    __weak PRConnection *_conn;
    
    int _tempIndex;
    NSFileManager *_fileManager;
}

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db {
    if (!(self = [super init])){return nil;}
    _tempIndex = 0; 
    _fileManager = [[NSFileManager alloc] init];
    _db = db;
    return self;
}

- (id)initWithConnection:(PRConnection *)conn {
    if (!(self = [super init])){return nil;}
    _tempIndex = 0; 
    _fileManager = [[NSFileManager alloc] init];
    _conn = conn;
    return self;
}

#pragma mark - zAccessors

- (BOOL)zArtworkForItems:(NSArray *)items out:(NSImage **)outValue {
    // Cached album art
    NSMutableString *stm = [NSMutableString stringWithString:@"SELECT file_id FROM library WHERE file_id IN ("];
    for (PRItemID *i in items) {
        [stm appendFormat:@"%llu, ", [i unsignedLongLongValue]];
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
    [stm appendString:@") AND albumArt = 1"];
    
    NSArray *rlt = nil;
    [_db zExecute:stm bindings:nil columns:@[PRColInteger] out:&rlt];
    for (NSArray *i in rlt) {
        PRItemID *item = i[0];
        BOOL isDirectory;
        BOOL fileExists = [_fileManager fileExistsAtPath:[self cachedArtworkPathForItem:item] isDirectory:&isDirectory];
        if (fileExists && !isDirectory) {
            NSImage *albumArt = [[NSImage alloc] initWithContentsOfFile:[self cachedArtworkPathForItem:item]];
            if (!albumArt || ![albumArt isValid]) {
                [self clearArtworkForItem:item];
            } else {
                if (outValue) {
                    *outValue = albumArt;
                }
                return YES;
            }
        }
    }
    
    // Artwork in Folder
    if (![[PRDefaults sharedDefaults] boolForKey:PRDefaultsFolderArtwork]) {
        return NO;
    }
    stm = [NSMutableString stringWithString:@"SELECT path FROM library WHERE file_id IN ("];
    for (PRItemID *i in items) {
        [stm appendFormat:@"%d, ", [i intValue]];
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
    [stm appendString:@")"];
    rlt = nil;
    
    [_db zExecute:stm bindings:nil columns:@[PRColString] out:&rlt];
    NSMutableSet *paths = [NSMutableSet set];
    for (NSArray *i in rlt) {
        NSURL *URL = [NSURL URLWithString:i[0]];
        URL = [NSURL fileURLWithPath:[[URL path] stringByDeletingLastPathComponent]];
        if (!URL || [paths containsObject:[URL absoluteString]]) {
            continue;
        } else {
            [paths addObject:[URL absoluteString]];
        }
        NSArray *directoryURLs = [_fileManager contentsOfDirectoryAtURL:URL includingPropertiesForKeys:@[] options:0 error:nil];
        for (NSURL *j in directoryURLs) {
            NSString *pathExtension = [j pathExtension];
            if ([pathExtension caseInsensitiveCompare:@"jpg"] == NSOrderedSame ||
                [pathExtension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
                [pathExtension caseInsensitiveCompare:@"png"] == NSOrderedSame) {
                NSImage *albumArt = [[NSImage alloc] initWithContentsOfFile:[j path]];
                if (albumArt && [albumArt isValid]) {
                    if (outValue) {
                        *outValue = albumArt;
                    }
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)zArtworkForArtist:(NSString *)artist out:(NSImage **)outValue {
    NSString *stm = [NSString stringWithFormat:@"SELECT file_id FROM library WHERE %@ COLLATE NOCASE2 = ?1",
        ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist] ? @"artistAlbumArtist" : @"artist")];
    NSArray *rlt = nil;
    BOOL success = [_db zExecute:stm bindings:@{@1:artist} columns:@[PRColInteger] out:&rlt];
    if (!success) {
        return NO;
    }
    NSArray *items = [rlt PRMap:^(NSInteger idx, NSArray *obj){
        return obj[0];
    }];
    return [self zArtworkForItems:items out:outValue];
}

- (BOOL)zClearArtworkForItem:(PRItemID *)item {
    [_fileManager removeItemAtPath:[self cachedArtworkPathForItem:item] error:nil];
    return [[_db library] zSetValue:@0 forItem:item attr:PRItemAttrArtwork];
}

- (BOOL)zArtworkInfoForItems:(NSArray *)items out:(NSDictionary **)outValue {
    // Embedded Artwork 
    NSMutableString *stm = [NSMutableString stringWithString:@"SELECT file_id FROM library WHERE file_id IN ("];
    for (PRItemID *i in items) {
        [stm appendFormat:@"%ld, ", [i integerValue]];
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
    [stm appendString:@") AND albumArt = 1"];
    NSArray *rlt = nil;
    BOOL success = [_db zExecute:stm bindings:nil columns:@[PRColInteger] out:&rlt];
    if (!success) {
        return NO;
    }
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSArray *i in rlt) {
        [indexSet addIndex:[i[0] integerValue]];
    }
    
    // Folder Artwork
    NSArray *paths = @[];
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsFolderArtwork]) {
        stm = [NSMutableString stringWithString:@"SELECT path FROM library WHERE file_id IN ("];
        for (PRItemID *i in items) {
            [stm appendFormat:@"%d, ", [i intValue]];
        }        
        [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 1)];
        [stm appendString:@")"];
        success = [_db zExecute:stm bindings:nil columns:@[PRColString] out:&rlt];
        if (!success) {
            return NO;
        }
        paths = [rlt PRMap:^(NSInteger idx, NSArray *obj){
            return obj[0];
        }];
    }
    
    if (outValue) {
        *outValue = @{@"files":indexSet, @"paths":paths};
    }
    return YES;
}

- (BOOL)zArtworkInfoForArtist:(NSString *)artist out:(NSDictionary **)outValue {
    NSString *stm = [NSString stringWithFormat:@"SELECT file_id FROM library WHERE %@ COLLATE NOCASE2 = ?1",
        ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist] ? @"artistAlbumArtist" : @"artist")];
    NSArray *rlt = nil;
    BOOL success = [_db zExecute:stm bindings:@{@1:artist} columns:@[PRColInteger] out:&rlt];
    if (!success) {
        return NO;
    }
    NSArray *items = [rlt PRMap:^(NSInteger idx, NSArray *obj){
        return obj[0];
    }];
    return [self zArtworkInfoForItems:items out:outValue];
}

#pragma mark - Accessors

- (NSImage *)artworkForItem:(PRItemID *)item {
    return [self artworkForItems:@[item]];
}

- (NSImage *)artworkForItems:(NSArray *)items {
    NSImage *rlt = nil;
    [self zArtworkForItems:items out:&rlt];
    return rlt;
}

- (NSImage *)artworkForArtist:(NSString *)artist {
    NSImage *rlt = nil;
    [self zArtworkForArtist:artist out:&rlt];
    return rlt;
}

- (void)clearArtworkForItem:(PRItemID *)item {
    [self zClearArtworkForItem:item];
}

#pragma mark - Async Accessors

- (NSDictionary *)artworkInfoForItem:(PRItemID *)item {
    return [self artworkInfoForItems:@[item]];
}

- (NSDictionary *)artworkInfoForItems:(NSArray *)items {
    NSDictionary *rlt = nil;
    [self zArtworkInfoForItems:items out:&rlt];
    return rlt;
}

- (NSDictionary *)artworkInfoForArtist:(NSString *)artist {
    NSDictionary *rlt = nil;
    [self zArtworkInfoForArtist:artist out:&rlt];
    return rlt;
}

- (NSImage *)artworkForArtworkInfo:(NSDictionary *)info {
    NSIndexSet *files = [info objectForKey:@"files"];
    NSArray *paths = [info objectForKey:@"paths"];
    
    NSInteger file = [files firstIndex];
    while (file != NSNotFound) {
        PRItemID *item = [PRItemID numberWithInt:file];
        BOOL isDirectory;
        BOOL fileExists = [_fileManager fileExistsAtPath:[self cachedArtworkPathForItem:item] isDirectory:&isDirectory];
        if (fileExists && !isDirectory) {
            NSImage *albumArt = [[NSImage alloc] initWithContentsOfFile:[self cachedArtworkPathForItem:item]];
            if (albumArt || [albumArt isValid]) {
                return albumArt;
            } 
        }
        file = [files indexGreaterThanIndex:file];
    }
    
    NSMutableSet *folderPaths = [NSMutableSet set];
    for (NSString *path in paths) {
        NSURL *URL = [NSURL URLWithString:path];
        URL = [NSURL fileURLWithPath:[[URL path] stringByDeletingLastPathComponent]];
        if (!URL || [folderPaths containsObject:[URL absoluteString]]) {
            continue;
        }
        [folderPaths addObject:[URL absoluteString]];
        NSError *error;
        NSArray *contents = [_fileManager contentsOfDirectoryAtURL:URL 
                                        includingPropertiesForKeys:@[] 
                                                           options:0 
                                                             error:&error];
        if (!contents) {
            continue;
        }
        for (NSURL *content in contents) {
            NSString *pathExtension = [content pathExtension];
            if ([pathExtension caseInsensitiveCompare:@"jpg"] == NSOrderedSame ||
                [pathExtension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
                [pathExtension caseInsensitiveCompare:@"png"] == NSOrderedSame) {
                NSImage *albumArt = [[NSImage alloc] initWithContentsOfFile:[content path]];
                if (albumArt && [albumArt isValid]) {
                    return albumArt;
                }
            }
        }
    }

    return nil;
}

- (void)setTempArtwork:(int)temp forItem:(PRItemID *)item {
    if (temp == 0) {
        [_fileManager removeItemAtPath:[self cachedArtworkPathForItem:item] error:nil];
        return;
    }
    NSString *path = [self tempArtPathForTempValue:temp];
    NSString *path2 = [self cachedArtworkPathForItem:item];
    if (![_fileManager findOrCreateDirectoryAtPath:[path2 stringByDeletingLastPathComponent] error:nil]) {return;}
    NSURL *URL = [NSURL fileURLWithPath:path];
    NSURL *URL2 = [NSURL fileURLWithPath:path2];
    [_fileManager moveItemAtURL:URL toURL:URL2 error:nil];
}

- (int)saveTempArtwork:(NSImage *)image {
    if (![image isValid]) {
        return 0;
    }
    NSData *data = [image jpegRepresentationWithCompressionFactor:0.8];
    int tempValue = [self nextTempValue];
    if (tempValue == 0) {
        return 0;
    }
    NSString *path = [self tempArtPathForTempValue:tempValue];
    if (![data writeToFile:path atomically:YES]) {
        return 0;
    }
    return tempValue;
}

- (void)clearTempArtwork {
    _tempIndex = 1;
    [_fileManager removeItemAtURL:[NSURL fileURLWithPath:[[PRDefaults sharedDefaults] tempArtPath]] error:nil];
    [_fileManager findOrCreateDirectoryAtPath:[[PRDefaults sharedDefaults] tempArtPath] error:nil];
}

#pragma mark - Priv

- (NSString *)cachedArtworkPathForItem:(PRItemID *)item {
    unsigned long long file = [item unsignedLongLongValue];
    NSString *path = [[PRDefaults sharedDefaults] cachedAlbumArtPath];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%03llu", ((file / 1000000) % 1000)]];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%03llu", ((file / 1000) % 1000)]];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%09llu", file]];
    return path;
}

- (int)nextTempValue {
    while (_tempIndex < 1000) {
        NSString *tempPath = [self tempArtPathForTempValue:_tempIndex];
        BOOL exists = [_fileManager fileExistsAtPath:tempPath];
        if (!exists) {
            return _tempIndex;;
        }
        _tempIndex++;
    }
    return 0;
}

- (NSString *)tempArtPathForTempValue:(int)temp {
    NSString *path = [[PRDefaults sharedDefaults] tempArtPath];
    return [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%03d", temp]];
}

@end
