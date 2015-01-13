#import <Foundation/Foundation.h>
// #import "PRPlaylists.h"
@class PRDb, PRFileInfo;

typedef enum {
    PRFileTypeUnknown,
    PRFileTypeAPE,
    PRFileTypeASF, /*not used*/
    PRFileTypeFLAC,
    PRFileTypeMP4,
    PRFileTypeMPC,
    PRFileTypeMPEG,
    PRFileTypeOggFLAC,
    PRFileTypeOggVorbis,
    PRFileTypeOggSpeex,
    PRFileTypeAIFF,
    PRFileTypeWAV,
    PRFileTypeTrueAudio,
    PRFileTypeWavPack,
} PRFileType;


@interface PRTagger : NSObject
/* Tags */
+ (PRFileInfo *)infoForURL:(NSURL *)URL; // returns nil if invalid or missing file
+ (NSMutableDictionary *)tagsForURL:(NSURL *)URL; // returns nil if invalid or missing file
+ (void)setTag:(id)tag forAttribute:(NSString *)attr URL:(NSURL *)URL;
+ (BOOL)updateTagsForItem:(NSNumber *)item database:(PRDb *)db; // caller should post ItemsDidChangeNotification if this returns TRUE

/* Properties */
+ (NSDate *)lastModifiedForFileAtPath:(NSString *)path;
+ (NSData *)checkSumForFileAtPath:(NSString *)path;
+ (NSNumber *)sizeForFileAtPath:(NSString *)path;

+ (NSDate *)lastModifiedForURL:(NSURL *)URL;
+ (NSData *)checkSumForURL:(NSURL *)URL;
+ (NSNumber *)sizeForURL:(NSURL *)URL;
@end
