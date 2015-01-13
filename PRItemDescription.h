#import <Foundation/Foundation.h>
#import "PRPlaylists.h"

@interface PRItemDescription : NSObject
@property (nonatomic, readonly) PRItem *item;

/* File Attributes */
@property (nonatomic, strong) NSString *path;
@property (nonatomic) NSInteger size;
@property (nonatomic, strong) NSData *checkSum;
@property (nonatomic, strong) NSDate *lastModified;

/* Song Attributes */
@property (nonatomic) NSInteger kind;
@property (nonatomic) NSInteger channels;
@property (nonatomic) NSInteger time;
@property (nonatomic) NSInteger bitrate;
@property (nonatomic) NSInteger sampleRate;

/* String Tags */
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *albumArtist;
@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSString *composer;
@property (nonatomic, strong) NSString *genre;
@property (nonatomic, strong) NSString *comments;
@property (nonatomic, strong) NSString *lyrics;

/* Number Tags */
@property (nonatomic) NSInteger BPM;
@property (nonatomic) NSInteger year;
@property (nonatomic) NSInteger trackNumber;
@property (nonatomic) NSInteger trackCount;
@property (nonatomic) NSInteger discNumber;
@property (nonatomic) NSInteger discCount;
@property (nonatomic) NSInteger compilation;

/* Artwork Tags */
@property (nonatomic) NSInteger artwork;

/* Custom Attributes */
@property (nonatomic, strong) NSString *artistAlbumArtist;
@property (nonatomic, strong) NSDate *dateAdded;
@property (nonatomic, strong) NSDate *lastPlayed;
@property (nonatomic) NSInteger playCount;
@property (nonatomic) NSInteger rating;
@end
