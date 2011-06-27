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

- (BOOL)create_error:(NSError **)error;
- (BOOL)initialize_error:(NSError **)error;
- (BOOL)validate_error:(NSError **)error;

// ========================================
// Action

- (BOOL)validateAndClean_error:(NSError **)error;

// ========================================
// Accessors

+ (NSDictionary *)columnDict;
+ (NSString *)columnNameForFileAttribute:(PRFileAttribute)attribute;
+ (PRFileAttribute)fileAttributeForName:(NSString *)name;

- (BOOL)value:(id *)value forFile:(PRFile)file attribute:(PRFileAttribute)attr _error:(NSError **)error;
- (BOOL)setValue:(id)value forFile:(PRFile)file attribute:(PRFileAttribute)attr _error:(NSError **)error;
- (BOOL)intValue:(int *)value forFile:(PRFile)file attribute:(PRFileAttribute)attribute _error:(NSError **)error;
- (BOOL)setIntValue:(int)value forFile:(PRFile)file attribute:(PRFileAttribute)attr _error:(NSError **)error;
- (BOOL)attributes:(NSDictionary **)dictionary forFile:(PRFile)file _error:(NSError **)error;
- (BOOL)setAttributes:(NSDictionary *)dictionary forFile:(PRFile)file _error:(NSError **)error;

- (BOOL)addFile:(PRFile *)file withPath:(NSString *)path _error:(NSError **)error;
- (BOOL)removeFiles:(NSIndexSet *)fileIndexes _error:(NSError **)error;
- (BOOL)addFile:(PRFile *)file withAttributes:(NSDictionary *)attributes _error:(NSError **)error;

- (BOOL)files:(NSIndexSet **)files withPath:(NSString *)path caseSensitive:(BOOL)caseSensitive _error:(NSError **)error;
- (BOOL)files:(NSIndexSet **)files withValue:(id)value forAttribute:(PRFileAttribute)attribute _error:(NSError **)error;
- (BOOL)arrayOfUniqueValues:(NSArray **)array forAttribute:(PRFileAttribute)attr _error:(NSError **)error;
- (BOOL)arrayOfFileIDsSortedByAlbumAndArtist:(NSArray **)array _error:(NSError **)error;

// ========================================
// Update

- (BOOL)propagateFileDelete_error:(NSError **)error;

@end
