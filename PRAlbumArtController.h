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

- (BOOL)albumArt:(NSImage **)albumArt
		 forFile:(PRFile)file
		  _error:(NSError **)error;
- (BOOL)albumArt:(NSImage **)albumArt
       forArtist:(NSString *)artist
          _error:(NSError **)error;

- (BOOL)setDownloadedAlbumArt:(NSImage *)albumArt
                      forFile:(PRFile)file
					   _error:(NSError **)error;
- (BOOL)setCachedAlbumArt:(NSImage *)albumArt 
                  forFile:(PRFile)file 
                   _error:(NSError **)error;

// ========================================
// Misc

- (NSString *)cachedAlbumArtPathForFile:(PRFile)file;
- (NSString *)downloadedAlbumArtPathForFile:(PRFile)file;
- (void)clearAlbumArtForFile:(PRFile)file;
- (BOOL)fileHasAlbumArt:(PRFile)file;

@end