#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
@class PRDb;
@class PRLibrary;


@interface PRAlbumArtController : NSObject
/* Initialization */
- (id)initWithDb:(PRDb *)db;
- (id)initWithConnection:(PRConnection *)conn;

- (BOOL)zArtworkForItems:(NSArray *)items out:(NSImage **)outValue;
- (BOOL)zArtworkForArtist:(NSString *)artist out:(NSImage **)outValue;
- (BOOL)zClearArtworkForItem:(PRItem *)item;

- (BOOL)zArtworkInfoForItems:(NSArray *)items out:(NSDictionary **)outValue;
- (BOOL)zArtworkInfoForArtist:(NSString *)artist out:(NSDictionary **)outValue;

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
