#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#import "PRLibrary.h"

@class PRDb, PRLibrary, PRAlbumArtController;

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

@interface PRTagEditor : NSObject 
{
    NSURL *_URL;
    void *_taglibFile;
    PRFileType _fileType;
}

// ========================================
// Initialization

// Does not include PRAlbumArtFileAttribute
- (id)initWithURL:(NSURL *)URL;
+ (PRTagEditor *)tagEditorForURL:(NSURL *)URL;

// ========================================
// Constants

+ (NSArray *)tagList;
+ (NSDictionary *)defaultTags;

// ========================================
// Accessors

- (NSMutableDictionary *)info; //mutabledict with artwork as @"art" and mutableattributes as @"attr"
- (NSDictionary *)tags;
- (void)setValue:(id)value forTag:(PRFileAttribute)tag;

// ========================================
// Tag Reading 

+ (NSDate *)lastModifiedAtURL:(NSURL *)URL;
+ (NSDate *)lastModifiedForFileAtPath:(NSString *)path;
+ (NSData *)checkSumForFileAtPath:(NSString *)path;
+ (NSNumber *)sizeForFileAtPath:(NSString *)path;

@end
