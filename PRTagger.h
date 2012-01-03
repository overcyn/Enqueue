#import <Foundation/Foundation.h>
@class PRFileInfo;

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

// ========================================
// Tags

+ (PRFileInfo *)infoForURL:(NSURL *)URL;
+ (NSDictionary *)tagsForURL:(NSURL *)URL;
+ (NSDictionary *)simpleTagsForURL:(NSURL *)URL;

+ (void)setTag:(id)tag forAttribute:(PRFileAttribute)attr URL:(NSURL *)URL;

+ (NSDictionary *)defaultTags;

// ========================================
// Properties

+ (NSDate *)lastModifiedAtURL:(NSURL *)URL;
+ (NSDate *)lastModifiedForFileAtPath:(NSString *)path;
+ (NSData *)checkSumForFileAtPath:(NSString *)path;
+ (NSNumber *)sizeForFileAtPath:(NSString *)path;

@end
