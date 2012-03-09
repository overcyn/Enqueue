#import <Cocoa/Cocoa.h>
#import "PRDb.h"
@class PRDb;


typedef NSNumber PRItem;

typedef NSString PRItemAttr;
extern PRItemAttr * const PRItemAttrPath;
extern PRItemAttr * const PRItemAttrSize;
extern PRItemAttr * const PRItemAttrKind;
extern PRItemAttr * const PRItemAttrTime;
extern PRItemAttr * const PRItemAttrBitrate;
extern PRItemAttr * const PRItemAttrChannels;
extern PRItemAttr * const PRItemAttrSampleRate;
extern PRItemAttr * const PRItemAttrCheckSum;
extern PRItemAttr * const PRItemAttrLastModified;
extern PRItemAttr * const PRItemAttrTitle;
extern PRItemAttr * const PRItemAttrArtist;
extern PRItemAttr * const PRItemAttrAlbum;
extern PRItemAttr * const PRItemAttrBPM;
extern PRItemAttr * const PRItemAttrYear;
extern PRItemAttr * const PRItemAttrTrackNumber;
extern PRItemAttr * const PRItemAttrTrackCount;
extern PRItemAttr * const PRItemAttrComposer;
extern PRItemAttr * const PRItemAttrDiscNumber;
extern PRItemAttr * const PRItemAttrDiscCount;
extern PRItemAttr * const PRItemAttrComments;
extern PRItemAttr * const PRItemAttrAlbumArtist;
extern PRItemAttr * const PRItemAttrGenre;
extern PRItemAttr * const PRItemAttrCompilation;
extern PRItemAttr * const PRItemAttrLyrics;
extern PRItemAttr * const PRItemAttrArtwork;
extern PRItemAttr * const PRItemAttrArtistAlbumArtist;
extern PRItemAttr * const PRItemAttrDateAdded;
extern PRItemAttr * const PRItemAttrLastPlayed;
extern PRItemAttr * const PRItemAttrPlayCount;
extern PRItemAttr * const PRItemAttrRating;


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
    PRCompilationFileAttribute = 29,
    PRLyricsFileAttribute = 30,
	
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


@interface PRLibrary : NSObject {
	PRDb *db;
}
// Initialization
- (id)initWithDb:(PRDb *)db_;
- (void)create;
- (BOOL)initialize;

// Misc
+ (NSDictionary *)columnDict;
+ (NSDictionary *)columnForAttribute;
+ (NSString *)columnNameForFileAttribute:(PRFileAttribute)attribute;
+ (PRFileAttribute)fileAttributeForName:(NSString *)name;
+ (NSString *)nameForFileAttribute:(PRFileAttribute)attribute;

- (PRFile)addFileWithAttributes:(NSDictionary *)attrs;
- (void)removeFiles:(NSIndexSet *)files;

// Accessors Tag
- (BOOL)updateTagsForFile:(PRFile)file;

// Accessors Misc
- (NSURL *)URLforFile:(PRFile)file;
- (NSString *)comparisonArtistForFile:(PRFile)file;
- (NSArray *)filesWithSimilarURL:(NSURL *)URL;
- (NSIndexSet *)filesWithValue:(id)value forAttribute:(PRFileAttribute)attribute;

// Update
- (BOOL)propagateItemDelete;

// ========================================

// Misc
+ (NSArray *)itemAttrProperties;
+ (NSArray *)itemAttrs;
+ (NSDictionary *)itemAttrToColumnNameDictionary;
+ (NSDictionary *)itemAttrToColumnTypeDictionary;
+ (NSDictionary *)itemAttrToTitleDictionary;
+ (NSDictionary *)itemAttrToInternalDictionary;

+ (NSString *)columnNameForItemAttr:(PRItemAttr *)attr;
+ (PRCol *)columnTypeForItemAttr:(PRItemAttr *)attr;
+ (NSString *)titleForItemAttr:(PRItemAttr *)attr;
+ (NSNumber *)internalForItemAttr:(PRItemAttr *)attr;
+ (PRItemAttr *)itemAttrForInternal:(NSNumber *)internal;

// Accessors
- (BOOL)containsItem:(PRItem *)item;
- (PRItem *)addItemWithAttrs:(NSDictionary *)attrs;
- (void)removeItems:(NSArray *)items;
- (id)valueForItem:(PRItem *)item attr:(PRItemAttr *)attr;
- (void)setValue:(id)value forItem:(PRItem *)item attr:(PRItemAttr *)attr;
- (NSDictionary *)attrsForItem:(PRItem *)item;
- (void)setAttrs:(NSDictionary *)attrs forItem:(PRItem *)item;

// Misc Accessors
- (NSString *)artistValueForItem:(PRItem *)item;
- (NSURL *)URLForItem:(PRItem *)item;
- (NSArray *)itemsWithSimilarURL:(NSURL *)URL;
- (NSArray *)itemsWithValue:(id)value forAttr:(PRItemAttr *)attr;
- (BOOL)updateTagsForItem:(PRItem *)item;
@end
