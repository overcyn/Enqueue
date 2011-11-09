#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"

@class PRDb;
@class PRLibrary;

@interface PRAlbumArtController : NSObject 
{
    int _tempIndex;
    NSFileManager *_fileManager;
    
	PRLibrary *lib;
	PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_;

// ========================================
// Accessors

- (NSDictionary *)artworkInfoForFile:(PRFile)file;
- (NSDictionary *)artworkInfoForFiles:(NSIndexSet *)files;
- (NSDictionary *)artworkInfoForArtist:(NSString *)artist;
- (NSImage *)artworkForArtworkInfo:(NSDictionary *)info;

- (NSImage *)albumArtForFile:(PRFile)file;
- (NSImage *)albumArtForFiles:(NSIndexSet *)files;
- (NSImage *)albumArtForArtist:(NSString *)artist;

- (NSImage *)cachedArtForFile:(PRFile)file;

- (void)setCachedAlbumArt:(NSImage *)image forFile:(PRFile)file;
- (void)setCachedAlbumArt2:(NSImage *)image forFile:(PRFile)file;

// ========================================
// Misc

- (NSString *)cachedAlbumArtPathForFile:(PRFile)file;
- (NSString *)downloadedAlbumArtPathForFile:(PRFile)file;
- (void)clearAlbumArtForFile:(PRFile)file;
- (void)clearAlbumArtForFile2:(PRFile)file;
- (BOOL)fileHasAlbumArt:(PRFile)file;

// ========================================
// Temp

- (void)setTempArt:(int)temp forFile:(PRFile)file;
- (int)saveTempArt:(NSImage *)image;
- (void)clearTempArt;

// ========================================
// Temp Misc

- (int)nextTempValue;
- (NSString *)tempArtPathForTempValue:(int)temp;


@end