#import <Cocoa/Cocoa.h>

@class PRDb;


// ========================================
// Constants & Typedefs

typedef int PRFile;

typedef enum {
	PRPathFileAttribute = 25,
	
    // tags
	PRTitleFileAttribute = 1, 
	PRArtistFileAttribute = 2,
	PRAlbumFileAttribute = 3,
	PRBPMFileAttribute = 4,
	PRYearFileAttribute = 5,
	PRTrackNumberFileAttribute = 6,
	PRTrackCountFileAttribute = 7,
	PRComposerFileAttribute = 8,
	PRDiscNumberFileAttribute = 9,
	PRDiscCountFileAttribute = 10,
	PRCommentsFileAttribute = 11,
	PRAlbumArtistFileAttribute = 12,
	PRGenreFileAttribute = 13,
	
    // album art
    PRAlbumArtFileAttribute = 24,
    
    // properties
	PRSizeFileAttribute = 18,
	PRKindFileAttribute = 19,
	PRTimeFileAttribute = 20,
	PRBitrateFileAttribute = 21,
	PRChannelsFileAttribute = 22,
	PRSampleRateFileAttribute = 23,
    PRCheckSumFileAttribute = 27,
    PRLastModifiedFileAttribute = 28,
    
    PRDateAddedFileAttribute = 14,
	PRLastPlayedFileAttribute = 15,
	PRPlayCountFileAttribute = 16,
	PRRatingFileAttribute = 17,
    
    PRArtistAlbumArtistFileAttribute = 26,
} PRFileAttribute;

// ========================================
// PRLibrary
// ========================================
@interface PRLibrary : NSObject 
{
	PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_;

- (void)create;
- (BOOL)initialize;

// ========================================
// Misc

+ (NSDictionary *)columnDict;
+ (NSDictionary *)columnForAttribute;
+ (NSString *)columnNameForFileAttribute:(PRFileAttribute)attribute;
+ (PRFileAttribute)fileAttributeForName:(NSString *)name;

// ========================================
// Accessors

- (BOOL)containsFile:(PRFile)file;

- (PRFile)addFileWithAttributes:(NSDictionary *)attrs;
- (void)removeFiles:(NSIndexSet *)files;

- (id)valueForFile:(PRFile)file attribute:(PRFileAttribute)attribute;
- (NSDictionary *)attributesForFile:(PRFile)file;
- (void)setValue:(id)value forFile:(PRFile)file attribute:(PRFileAttribute)attribute;
- (void)setAttributes:(NSDictionary *)attirbutes forFile:(PRFile)file;

// ========================================
// Accessors Tag

- (BOOL)updateTagsForFile:(PRFile)file;

// ========================================
// Accessors Misc

- (NSURL *)URLforFile:(PRFile)file;
- (NSString *)comparisonArtistForFile:(PRFile)file;
- (NSArray *)filesWithSimilarURL:(NSURL *)URL;
- (NSIndexSet *)filesWithValue:(id)value forAttribute:(PRFileAttribute)attribute;

// ========================================
// Update

- (BOOL)propagateFileDelete_error:(NSError **)error;

@end
