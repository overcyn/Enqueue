#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#import "PRLibrary.h"
#import "PRTagger.h"

@class PRDb, PRLibrary, PRAlbumArtController, PRFileInfo;


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
- (PRFileInfo *)fileInfo;
- (NSDictionary *)tags;
- (void)setValue:(id)value forTag:(PRFileAttribute)tag;

// ========================================
// Tag Reading 

+ (NSDate *)lastModifiedAtURL:(NSURL *)URL;
+ (NSDate *)lastModifiedForFileAtPath:(NSString *)path;
+ (NSData *)checkSumForFileAtPath:(NSString *)path;
+ (NSNumber *)sizeForFileAtPath:(NSString *)path;

@end
