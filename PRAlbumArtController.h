#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"

@class PRDb;
@class PRLibrary;

@interface PRAlbumArtController : NSObject 
{
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

- (void)setCachedAlbumArt:(NSImage *)image forFile:(PRFile)file;

// ========================================
// Misc

- (NSString *)cachedAlbumArtPathForFile:(PRFile)file;
- (NSString *)downloadedAlbumArtPathForFile:(PRFile)file;
- (void)clearAlbumArtForFile:(PRFile)file;
- (BOOL)fileHasAlbumArt:(PRFile)file;

@end