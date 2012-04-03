#import <Foundation/Foundation.h>
@class PRDb, PRFileInfo;


typedef enum {
    PRFileTypeUnknown,
    PRFileTypeAPE,
    PRFileTypeASF,
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
+ (void)setTag:(id)tag forAttribute:(PRItemAttr *)attr URL:(NSURL *)URL;
+ (BOOL)updateTagsForItem:(PRItem *)item database:(PRDb *)db; // post ItemsDidChangeNotification if this updates

/* Properties */
+ (NSDate *)lastModifiedAtURL:(NSURL *)URL;
+ (NSDate *)lastModifiedForFileAtPath:(NSString *)path;
+ (NSData *)checkSumForFileAtPath:(NSString *)path;
+ (NSNumber *)sizeForFileAtPath:(NSString *)path;
@end
