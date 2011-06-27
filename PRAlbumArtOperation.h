#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"


extern NSString * const PRAmazonAssociatesTag;
extern NSString * const PRAWSAccessKeyID;
extern NSString * const PRAWSSecretAccessKey;

@class PRDb;
@class PRLibrary;

@interface PRAlbumArtOperation : NSOperation 
{
	PRDb *db;
	PRLibrary *library;
	
	NSString *prevArtist;
	NSString *prevAlbum;
	NSImage *prevAlbumArt;
}

- (id)initWithDb:(PRDb *)db_;
- (NSImage *)albumArtForFile:(PRFile)file;

+ (NSImage *)amazonAlbumArtForArtist:(NSString *)artist album:(NSString *)album;
+ (NSImage *)freecoversAlbumArtForArtist:(NSString *)artist album:(NSString *)album;
+ (NSImage *)lastfmAlbumArtForArtist:(NSString *)artist album:(NSString *)album;

@end


@interface PRAlbumArtOperation() 

+ (NSString *)amazonSignedURL:(NSString *)URLString;

@end