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
// ========================================

- (id)initWithDb:(PRDb *)db_
{
    self = [super init];
	if (self) {
		db = db_;
		lib	= [db library];
	}
	return self;
}

// ========================================
// Accessors
// ========================================

- (NSDictionary *)artworkInfoForFile:(PRFile)file
{
    return [self artworkInfoForFiles:[NSIndexSet indexSetWithIndex:file]];
}

- (NSDictionary *)artworkInfoForFiles:(NSIndexSet *)files
{
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT file_id FROM library WHERE file_id IN ("];
    NSInteger index = [files firstIndex];
    while (index != NSNotFound) {
        [string appendFormat:@"%d, ", index];
        index = [files indexGreaterThanIndex:index];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@") AND albumArt = 1"];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:nil columns:columns];
    
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
    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
    results = [db execute:string bindings:nil columns:columns];
    
    NSMutableArray *paths = [NSMutableArray array];
    for (NSArray *i in results) {
        [paths addObject:[i objectAtIndex:0]];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:indexSet, @"files", paths, @"paths", nil];
}

- (NSDictionary *)artworkInfoForArtist:(NSString *)artist
{
    NSString *string;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        string = @"SELECT file_id FROM library WHERE artistAlbumArtist COLLATE NOCASE2 = ?1";
    } else {
        string = @"SELECT file_id FROM library WHERE artist COLLATE NOCASE2 = ?1";
    }
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              artist, [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    NSMutableIndexSet *files = [NSMutableIndexSet indexSet];
    for (NSArray *i in results) {
        [files addIndex:[[i objectAtIndex:0] intValue]];
    }
    return [self artworkInfoForFiles:files];
}

- (NSImage *)artworkForArtworkInfo:(NSDictionary *)info
{
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

- (NSImage *)albumArtForFile:(PRFile)file
{
    return [self albumArtForFiles:[NSIndexSet indexSetWithIndex:file]];
}

- (NSImage *)albumArtForFiles:(NSIndexSet *)files
{
    // Cached album art
    NSMutableString *string = [NSMutableString stringWithString:@"SELECT file_id FROM library WHERE file_id IN ("];
    NSInteger index = [files firstIndex];
    while (index != NSNotFound) {
        [string appendFormat:@"%d, ", index];
        index = [files indexGreaterThanIndex:index];
    }
    [string deleteCharactersInRange:NSMakeRange([string length] - 2, 1)];
    [string appendString:@") AND albumArt = 1"];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
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
                [[db library] setValue:[NSNumber numberWithBool:FALSE] forFile:file attribute:PRAlbumArtFileAttribute];
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
    columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnString], nil];
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

- (NSImage *)albumArtForArtist:(NSString *)artist
{
    NSString *string;
    if ([[PRUserDefaults userDefaults] useAlbumArtist]) {
        string = @"SELECT file_id FROM library WHERE artistAlbumArtist COLLATE NOCASE2 = ?1";
    } else {
        string = @"SELECT file_id FROM library WHERE artist COLLATE NOCASE2 = ?1";
    }
    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              artist, [NSNumber numberWithInt:1], nil];
    NSArray *columns = [NSArray arrayWithObjects:[NSNumber numberWithInt:PRColumnInteger], nil];
    NSArray *results = [db execute:string bindings:bindings columns:columns];
    NSMutableIndexSet *files = [NSMutableIndexSet indexSet];
    for (NSArray *i in results) {
        [files addIndex:[[i objectAtIndex:0] intValue]];
    }
    return [self albumArtForFiles:files];
}

- (void)setCachedAlbumArt:(NSImage *)image forFile:(PRFile)file;
{
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
    [[db library] setValue:[NSNumber numberWithBool:TRUE] forFile:file attribute:PRAlbumArtFileAttribute];
	return;
}

// ========================================
// Misc
// ========================================

- (NSString *)cachedAlbumArtPathForFile:(PRFile)file
{
	NSString *path = [[PRUserDefaults userDefaults] cachedAlbumArtPath];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000000) % 1000)]];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000) % 1000)]];
	path = [path stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%09d", file]];
    
	return path;
}

- (NSString *)downloadedAlbumArtPathForFile:(PRFile)file
{
	NSString *path = [[PRUserDefaults userDefaults] downloadedAlbumArtPath];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000000) % 1000)]];
	path = [path stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%03d", ((file / 1000) % 1000)]];
	path = [path stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%09d", file]];
    
	return path;
}

- (void)clearAlbumArtForFile:(PRFile)file
{
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    [fileManager removeItemAtPath:[self cachedAlbumArtPathForFile:file] error:nil];
    [fileManager removeItemAtPath:[self downloadedAlbumArtPathForFile:file] error:nil];
    [[db library] setValue:[NSNumber numberWithInt:0] forFile:file attribute:PRAlbumArtFileAttribute];
}

- (BOOL)fileHasAlbumArt:(PRFile)file
{
    int isAlbumArt = [[[db library] valueForFile:file attribute:PRAlbumArtFileAttribute] intValue];
    return isAlbumArt;
}

@end