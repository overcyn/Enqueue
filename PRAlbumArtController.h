#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
@class PRDb, PRLibrary;


@interface PRAlbumArtController : NSObject {
	__weak PRDb *_db;
	
    int _tempIndex;
    NSFileManager *_fileManager;
}
/* Initialization */
- (id)initWithDb:(PRDb *)db;

/* Accessors */
- (NSImage *)artworkForItem:(PRItem *)item;
- (NSImage *)artworkForItems:(NSArray *)items;
- (NSImage *)artworkForArtist:(NSString *)artist;

- (NSDictionary *)artworkInfoForItem:(PRItem *)item;
- (NSDictionary *)artworkInfoForItems:(NSArray *)items;
- (NSDictionary *)artworkInfoForArtist:(NSString *)artist;
- (NSImage *)artworkForArtworkInfo:(NSDictionary *)info;

/* Cache */
- (void)clearArtworkForItem:(PRItem *)item;

/* Misc */
- (NSString *)cachedArtworkPathForItem:(PRItem *)item;

/* Temp */
- (void)setTempArtwork:(int)temp forItem:(PRItem *)item;
- (int)saveTempArt:(NSImage *)image;
- (void)clearTempArt;

/* Temp Misc */
- (int)nextTempValue;
- (NSString *)tempArtPathForTempValue:(int)temp;
@end
