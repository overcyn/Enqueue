#import "PRAlbumArtController.h"
#import "PRLibrary.h"
#import "PRUserDefaults.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NSImage+Extensions.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRUserDefaults.h"

@implementation PRAlbumArtController

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_ {
    if (!(self = [super init])){return nil;}
    _tempIndex = 0; 
    _fileManager = [[NSFileManager alloc] init];
    db = db_;
    lib	= [db library];
	return self;
}

// ========================================
// Accessors

- (NSDictionary *)artworkInfoForFile:(PRFile)file {
    return [self artworkInfoForFiles:[NSIndexSet indexSetWithIndex:file]];
}

- (NSDictionary *)artworkInfoForFiles:(NSIndexSet *)files {
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT file_id FROM library WHERE file_id IN ("];
    NSInteger index = [files firstIndex];
    while (index != NSNotFound) {
        [string appendFormat:@"%d, ", index];
        index = [files indexGreaterThanIndex:index];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@") AND albumArt = 1"];
    NSArray *results = [db execute:string bindings:nil columns:[NSArray arrayWithObject:PRColInteger]];
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSArray *i in results) {
        [indexSet addIndex:[[i objectAtIndex:0] intValue]];
    }
    
    // Artwork in Folder
    if (![[PRUserDefaults userDefaults] folderArtwork]) {
        return [NSDictionary dictionaryWithObjectsAndKeys:indexSet, @"files", [NSArray array], @"paths", nil];
    }
    
    string = [NSMutableString stringWithString:@"SELECT path FROM library WHERE file_id IN ("];
    index = [files firstIndex];
    while (index != NSNotFound) {
        [string appendFormat:@"%d, ", index];
        index = [files indexGreaterThanIndex:index];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@")"];
    results = [db execute:string bindings:nil columns:[NSArray arrayWithObject:PRColString]];
    
    NSMutableArray *paths = [NSMutableArray array];
    for (NSArray *i in results) {
        [paths addObject:[i objectAtIndex:0]];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:indexSet, @"files", paths, @"paths", nil];
}

- (NSDictionary *)artworkInfoForArtist:(NSString *)artist {
    NSString *string;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        string = @"SELECT file_id FROM library WHERE artistAlbumArtist COLLATE NOCASE2 = ?1";
    } else {
        string = @"SELECT file_id FROM library WHERE artist COLLATE NOCASE2 = ?1";
    }
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              artist, [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:PRColInteger, nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    NSMutableIndexSet *files = [NSMutableIndexSet indexSet];
    for (NSArray *i in results) {
        [files addIndex:[[i objectAtIndex:0] intValue]];
    }
    return [self artworkInfoForFiles:files];
}

- (NSImage *)artworkForArtworkInfo:(NSDictionary *)info {
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSIndexSet *files = [info objectForKey:@"files"];
    NSArray *paths = [info objectForKey:@"paths"];
    
    NSInteger file = [files firstIndex];
    while (file != NSNotFound) {
        BOOL isDirectory;
        BOOL fileExists = [fileManager fileExistsAtPath:[self cachedAlbumArtPathForFile:file] isDirectory:&isDirectory];
        if (fileExists && !isDirectory) {
            NSImage *albumArt = [[[NSImage alloc] initWithContentsOfFile:[self cachedAlbumArtPathForFile:file]] autorelease];
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
        NSArray *contents = [fileManager contentsOfDirectoryAtURL:URL 
                                       includingPropertiesForKeys:[NSArray array] 
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
                NSImage *albumArt = [[[NSImage alloc] initWithContentsOfFile:[content path]] autorelease];
                if (albumArt && [albumArt isValid]) {
                    return albumArt;
                }
            }
        }
    }

    return nil;
}

- (NSImage *)albumArtForFile:(PRFile)file {
    return [self albumArtForFiles:[NSIndexSet indexSetWithIndex:file]];
}

- (NSImage *)albumArtForFiles:(NSIndexSet *)files {
    // Cached album art
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT file_id FROM library WHERE file_id IN ("];
    NSInteger index = [files firstIndex];
    while (index != NSNotFound) {
        [string appendFormat:@"%d, ", index];
        index = [files indexGreaterThanIndex:index];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@") AND albumArt = 1"];
    NSArray *columns = [NSArray arrayWithObjects:PRColInteger, nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    for (NSArray *i in results) {
        PRFile file = [[i objectAtIndex:0] intValue];
        BOOL isDirectory;
        BOOL fileExists = [fileManager fileExistsAtPath:[self cachedAlbumArtPathForFile:file] isDirectory:&isDirectory];
        if (fileExists && !isDirectory) {
            NSImage *albumArt = [[[NSImage alloc] initWithContentsOfFile:[self cachedAlbumArtPathForFile:file]] autorelease];
            if (!albumArt || ![albumArt isValid]) {
                [fileManager removeItemAtPath:[self cachedAlbumArtPathForFile:file] error:nil];
                [[db library] setValue:[NSNumber numberWithBool:FALSE] forItem:[NSNumber numberWithInt:file] attr:PRItemAttrArtwork];
            } else {
                return albumArt;
            }
        }
    }
    
    // Artwork in Folder
    if (![[PRUserDefaults userDefaults] folderArtwork]) {
        return nil;
    }
    
    string = [NSMutableString stringWithString:@"SELECT path FROM library WHERE file_id IN ("];
    index = [files firstIndex];
    while (index != NSNotFound) {
        [string appendFormat:@"%d, ", index];
        index = [files indexGreaterThanIndex:index];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@")"];
    columns = [NSArray arrayWithObjects:PRColString, nil];
    results = [db execute:string bindings:nil columns:columns];
    NSMutableSet *paths = [NSMutableSet set];
    for (NSArray *i in results) {
        NSURL *URL = [NSURL URLWithString:[i objectAtIndex:0]];
        URL = [NSURL fileURLWithPath:[[URL path] stringByDeletingLastPathComponent]];
        if (!URL || [paths containsObject:[URL absoluteString]]) {
            continue;
        } else {
            [paths addObject:[URL absoluteString]];
        }
        NSError *error;
        NSArray *directoryURLs = [fileManager contentsOfDirectoryAtURL:URL 
                                            includingPropertiesForKeys:[NSArray array] 
                                                                options:0 
                                                                  error:&error];
        if (!directoryURLs) {
            continue;
        }
        for (NSURL *directoryURL in directoryURLs) {
            NSString *pathExtension = [directoryURL pathExtension];
            if ([pathExtension caseInsensitiveCompare:@"jpg"] == NSOrderedSame ||
                [pathExtension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
                [pathExtension caseInsensitiveCompare:@"png"] == NSOrderedSame) {
                NSImage *albumArt = [[[NSImage alloc] initWithContentsOfFile:[directoryURL path]] autorelease];
                if (albumArt && [albumArt isValid]) {
                    return albumArt;
                }
            }
        }
    }
    return nil;
}

- (NSImage *)albumArtForArtist:(NSString *)artist {
    NSString *string;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        string = @"SELECT file_id FROM library WHERE artistAlbumArtist COLLATE NOCASE2 = ?1";
    } else {
        string = @"SELECT file_id FROM library WHERE artist COLLATE NOCASE2 = ?1";
    }
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              artist, [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:PRColInteger, nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    NSMutableIndexSet *files = [NSMutableIndexSet indexSet];
    for (NSArray *i in results) {
        [files addIndex:[[i objectAtIndex:0] intValue]];
    }
    return [self albumArtForFiles:files];
}

- (NSImage *)cachedArtForFile:(PRFile)file {
    NSIndexSet *files = [NSIndexSet indexSetWithIndex:file];
    // Cached album art
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT file_id FROM library WHERE file_id IN ("];
    NSInteger index = [files firstIndex];
    while (index != NSNotFound) {
        [string appendFormat:@"%d, ", index];
        index = [files indexGreaterThanIndex:index];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@") AND albumArt = 1"];
    NSArray *columns = [NSArray arrayWithObjects:PRColInteger, nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    for (NSArray *i in results) {
        PRFile file = [[i objectAtIndex:0] intValue];
        BOOL isDirectory;
        BOOL fileExists = [fileManager fileExistsAtPath:[self cachedAlbumArtPathForFile:file] isDirectory:&isDirectory];
        if (fileExists && !isDirectory) {
            NSImage *albumArt = [[[NSImage alloc] initWithContentsOfFile:[self cachedAlbumArtPathForFile:file]] autorelease];
            if (!albumArt || ![albumArt isValid]) {
                [fileManager removeItemAtPath:[self cachedAlbumArtPathForFile:file] error:nil];
                [[db library] setValue:[NSNumber numberWithBool:FALSE] forItem:[NSNumber numberWithInt:file] attr:PRItemAttrArtwork];
            } else {
                return albumArt;
            }
        }
    }
    return nil;
}

- (void)setCachedAlbumArt:(NSImage *)image forFile:(PRFile)file; {
    if (![image isValid]) {
        [self clearAlbumArtForFile:file];
        return;
    }
	
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSData *data = [image jpegRepresentationWithCompressionFactor:0.8];
	NSString *path = [self cachedAlbumArtPathForFile:file];
	if (![fileManager findOrCreateDirectoryAtPath:[path stringByDeletingLastPathComponent] error:nil]) {
        [self clearAlbumArtForFile:file];
        return;
    }
	if (![data writeToFile:path atomically:TRUE]) {
        [self clearAlbumArtForFile:file];
		return;
	}
    [[db library] setValue:[NSNumber numberWithBool:TRUE] forItem:[NSNumber numberWithInt:file] attr:PRItemAttrArtwork];
	return;
}

- (void)setCachedAlbumArt2:(NSImage *)image forFile:(PRFile)file; {
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSData *data = [image jpegRepresentationWithCompressionFactor:0.8];
	NSString *path = [self cachedAlbumArtPathForFile:file];
	if (![fileManager findOrCreateDirectoryAtPath:[path stringByDeletingLastPathComponent] error:nil]) {
        return;
    }
	if (![data writeToFile:path atomically:TRUE]) {
		return;
	}
}

// ========================================
// Misc

- (NSString *)cachedAlbumArtPathForFile:(PRFile)file {
	NSString *path = [[PRUserDefaults userDefaults] cachedAlbumArtPath];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000000) % 1000)]];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000) % 1000)]];
	path = [path stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%09d", file]];
	return path;
}

- (NSString *)downloadedAlbumArtPathForFile:(PRFile)file {
	NSString *path = [[PRUserDefaults userDefaults] downloadedAlbumArtPath];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000000) % 1000)]];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000) % 1000)]];
	path = [path stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%09d", file]];
    
	return path;
}

- (void)clearAlbumArtForFile:(PRFile)file {
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    [fileManager removeItemAtPath:[self cachedAlbumArtPathForFile:file] error:nil];
    [fileManager removeItemAtPath:[self downloadedAlbumArtPathForFile:file] error:nil];
    [[db library] setValue:[NSNumber numberWithInt:0] forItem:[NSNumber numberWithInt:file] attr:PRItemAttrArtwork];
}

- (void)clearAlbumArtForFile2:(PRFile)file {
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    [fileManager removeItemAtPath:[self cachedAlbumArtPathForFile:file] error:nil];
    [fileManager removeItemAtPath:[self downloadedAlbumArtPathForFile:file] error:nil];
}

- (BOOL)fileHasAlbumArt:(PRFile)file {
    return [[[db library] valueForItem:[NSNumber numberWithInt:file] attr:PRItemAttrArtwork] intValue];
}

// ========================================
// Temp

- (void)setTempArt:(int)temp forFile:(PRFile)file {
    if (temp == 0) {
        return;
    }
    NSString *path = [self tempArtPathForTempValue:temp];
    NSString *path2 = [self cachedAlbumArtPathForFile:file];
    if (![_fileManager findOrCreateDirectoryAtPath:[path2 stringByDeletingLastPathComponent] error:nil]) {return;}
    NSURL *URL = [NSURL fileURLWithPath:path];
    NSURL *URL2 = [NSURL fileURLWithPath:path2];
    [_fileManager moveItemAtURL:URL toURL:URL2 error:nil];
}

- (int)saveTempArt:(NSImage *)image {
    if (![image isValid]) {
        return 0;
    }
    NSData *data = [image jpegRepresentationWithCompressionFactor:0.8];
    int tempValue = [self nextTempValue];
    if (tempValue == 0) {
        return 0;
    }
    NSString *path = [self tempArtPathForTempValue:tempValue];
	if (![data writeToFile:path atomically:TRUE]) {
		return 0;
	}
    return tempValue;
}

- (void)clearTempArt {
    _tempIndex = 1;
    [_fileManager removeItemAtURL:[NSURL fileURLWithPath:[[PRUserDefaults userDefaults] tempArtPath]] error:nil];
    [_fileManager findOrCreateDirectoryAtPath:[[PRUserDefaults userDefaults] tempArtPath] error:nil];
}

// ========================================
// Temp Misc

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
    NSString *path = [[PRUserDefaults userDefaults] tempArtPath];
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%03d", temp]];
	return path;
}

// ========================================
// ========================================

- (NSDictionary *)artworkInfoForItem:(PRItem *)item {
    return [self artworkInfoForFile:[item intValue]];
}

- (NSDictionary *)artworkInfoForItems:(NSArray *)items {
    NSMutableIndexSet *indexSet = [[[NSMutableIndexSet alloc] init] autorelease];
    for (NSNumber *i in items) {
        [indexSet addIndex:[i intValue]];
    }
    return [self artworkInfoForFiles:indexSet];
}

- (NSImage *)artworkForItem:(PRItem *)item {
    return [self albumArtForFile:[item intValue]];
}

- (NSImage *)artworkForItems:(NSArray *)items {
    NSMutableIndexSet *indexSet = [[[NSMutableIndexSet alloc] init] autorelease];
    for (NSNumber *i in items) {
        [indexSet addIndex:[i intValue]];
    }
    return [self albumArtForFiles:indexSet];
}

- (NSImage *)artworkForArtist:(NSString *)artist {
    return [self albumArtForArtist:artist];
}

- (NSImage *)cachedArtworkForItem:(PRItem *)item {
    return [self cachedArtForFile:[item intValue]];
}

- (void)setCachedArtwork:(NSImage *)artwork forItem:(PRItem *)item {
    [self setCachedAlbumArt:artwork forFile:[item intValue]];
}

- (void)clearArtworkForItem:(PRItem *)item {
    [self clearAlbumArtForFile:[item intValue]];
}

- (NSString *)cachedArtworkPathForItem:(PRItem *)item {
    return [self cachedAlbumArtPathForFile:[item intValue]];
}

- (void)setTempArtwork:(int)temp forItem:(PRItem *)item {
    [self setTempArt:temp forFile:[item intValue]];
}

- (void)clearArtworkForItemNoUpdate:(NSNumber *)item {
    [self clearAlbumArtForFile2:[item intValue]];
}

@end