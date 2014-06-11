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
- (void)clearArtworkForItem:(PRItem *)item;

/* Async Accessors */
- (NSDictionary *)artworkInfoForItem:(PRItem *)item;
- (NSDictionary *)artworkInfoForItems:(NSArray *)items;
- (NSDictionary *)artworkInfoForArtist:(NSString *)artist;
- (NSImage *)artworkForArtworkInfo:(NSDictionary *)info;

- (void)setTempArtwork:(int)temp forItem:(PRItem *)item;
- (int)saveTempArtwork:(NSImage *)image;
- (void)clearTempArtwork;
@end
