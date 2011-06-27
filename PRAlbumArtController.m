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

- (BOOL)albumArt:(NSImage **)albumArt
		 forFile:(PRFile)file
		  _error:(NSError **)error
{
	*albumArt = nil;
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    int isAlbumArt;
    if (![db intValue:&isAlbumArt 
            forColumn:[PRLibrary columnNameForFileAttribute:PRAlbumArtFileAttribute] 
                  row:file 
                  key:@"file_id"
                table:@"library"
               _error:nil]) {
        return FALSE;
    }
    
    BOOL isDirectory;
    BOOL fileExists = [fileManager fileExistsAtPath:[self cachedAlbumArtPathForFile:file] isDirectory:&isDirectory];
    if (fileExists && !isDirectory) {
		*albumArt = [[[NSImage alloc] initWithContentsOfFile:[self cachedAlbumArtPathForFile:file]] autorelease];
		if (!*albumArt || ![*albumArt isValid]) {
            [fileManager removeItemAtPath:[self cachedAlbumArtPathForFile:file] error:nil];
            *albumArt = nil;
		}
	}
    
    if (*albumArt) {
        return TRUE;
    }
    
    fileExists = [fileManager fileExistsAtPath:[self downloadedAlbumArtPathForFile:file] isDirectory:&isDirectory];
    if (fileExists && !isDirectory) {
		*albumArt = [[[NSImage alloc] initWithContentsOfFile:[self downloadedAlbumArtPathForFile:file]] autorelease];
		
		if (!*albumArt || ![*albumArt isValid]) {
            NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
            [fileManager removeItemAtPath:[self downloadedAlbumArtPathForFile:file] error:nil];
            *albumArt = nil;
		}
	}

    if (*albumArt) {
        return TRUE;
    } else {
        [db setValue:[NSNumber numberWithInt:0] 
           forColumn:[PRLibrary columnNameForFileAttribute:PRAlbumArtFileAttribute] 
                 row:file
                 key:@"file_id" 
               table:@"Library" 
              _error:nil];
    }
    return TRUE;
}

- (BOOL)albumArt:(NSImage **)albumArt
       forArtist:(NSString *)artist
          _error:(NSError **)error
{

    NSDictionary *bindings = [NSDictionary dictionaryWithObjectsAndKeys:
                              artist, [NSNumber numberWithInt:1], nil];
    NSArray *result;
    
    if ([[PRUserDefaults sharedUserDefaults] useAlbumArtist]) {
        if (![db executeStatement:@"SELECT file_id FROM library WHERE artistAlbumArtist COLLATE NOCASE2 = ?1 AND albumArt = 1"
                     withBindings:bindings 
                           result:&result 
                           _error:nil]) {
            return FALSE;
        }
    } else {
        if (![db executeStatement:@"SELECT file_id FROM library WHERE artist COLLATE NOCASE2 = ?1 AND albumArt = 1"
                     withBindings:bindings 
                           result:&result 
                           _error:nil]) {
            return FALSE;
        }
    }
    
    *albumArt = nil;
    for (NSNumber *i in result) {
        [self albumArt:albumArt forFile:[i intValue] _error:nil];
        if (*albumArt != nil) {
            break;
        }
    }
    return TRUE;
}

- (BOOL)setCachedAlbumArt:(NSImage *)albumArt 
                  forFile:(PRFile)file 
				   _error:(NSError **)error
{
    if (![albumArt isValid]) {
        [self clearAlbumArtForFile:file];
        return FALSE;
    }
	
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSData *data = [albumArt jpegRepresentationWithCompressionFactor:0.8];
	NSString *path = [self cachedAlbumArtPathForFile:file];
	if (![fileManager findOrCreateDirectoryAtPath:[path stringByDeletingLastPathComponent] error:nil]) {
        [self clearAlbumArtForFile:file];
		return FALSE;
	}
	if (![data writeToFile:path atomically:TRUE]) {
        [self clearAlbumArtForFile:file];
		return FALSE;
	}
    if (![[db library] setValue:[NSNumber numberWithInt:1] forFile:file attribute:PRAlbumArtFileAttribute _error:nil]) {
        return FALSE;
    }
	return TRUE;
}

- (BOOL)setDownloadedAlbumArt:(NSImage *)albumArt
                      forFile:(PRFile)file
					   _error:(NSError **)error
{	
    if (![albumArt isValid]) {
        return FALSE;
    }
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSData *data = [albumArt jpegRepresentationWithCompressionFactor:0.8];
	NSString *path = [self downloadedAlbumArtPathForFile:file];
	
	if (![fileManager findOrCreateDirectoryAtPath:[path stringByDeletingLastPathComponent] error:nil]) {
		return FALSE;
	}
	if (![data writeToFile:path atomically:TRUE]) {
		return FALSE;
	}
    if (![db setValue:[NSNumber numberWithInt:1] 
            forColumn:[PRLibrary columnNameForFileAttribute:PRAlbumArtFileAttribute] 
                  row:file
                  key:@"file_id" 
                table:@"Library" 
               _error:nil]) {
        return FALSE;
    }
	return TRUE;
}

// ========================================
// Misc
// ========================================

- (NSString *)cachedAlbumArtPathForFile:(PRFile)file
{
	NSString *path = [[PRUserDefaults sharedUserDefaults] cachedAlbumArtPath];
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
	NSString *path = [[PRUserDefaults sharedUserDefaults] downloadedAlbumArtPath];
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
    [[db library] setValue:[NSNumber numberWithInt:0] forFile:file attribute:PRAlbumArtFileAttribute _error:nil];
}

- (BOOL)fileHasAlbumArt:(PRFile)file
{
    int isAlbumArt;
    if (![db intValue:&isAlbumArt 
            forColumn:[PRLibrary columnNameForFileAttribute:PRAlbumArtFileAttribute] 
                  row:file 
                  key:@"file_id"
                table:@"library"
               _error:nil]) {
        return FALSE;
    }

    return isAlbumArt;
}

@end