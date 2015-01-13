#import <Cocoa/Cocoa.h>
#import "PRDb.h"

@class PRDb;
@class PRConnection;
@class PRLibraryDescription;
@class PRBrowserDescription;
@class PRItem;

typedef NSNumber PRItemID;
typedef NSString PRItemAttr;
/* File Attributes */
extern PRItemAttr * const PRItemAttrPath;
extern PRItemAttr * const PRItemAttrSize;
extern PRItemAttr * const PRItemAttrCheckSum;
extern PRItemAttr * const PRItemAttrLastModified;
/* Song Attributes */
extern PRItemAttr * const PRItemAttrKind;
extern PRItemAttr * const PRItemAttrChannels;
extern PRItemAttr * const PRItemAttrTime;
extern PRItemAttr * const PRItemAttrBitrate;
extern PRItemAttr * const PRItemAttrSampleRate;
/* String Tags */
extern PRItemAttr * const PRItemAttrTitle;
extern PRItemAttr * const PRItemAttrArtist;
extern PRItemAttr * const PRItemAttrAlbumArtist;
extern PRItemAttr * const PRItemAttrAlbum;
extern PRItemAttr * const PRItemAttrComposer;
extern PRItemAttr * const PRItemAttrGenre;
extern PRItemAttr * const PRItemAttrComments;
extern PRItemAttr * const PRItemAttrLyrics;
/* Number Tags */
extern PRItemAttr * const PRItemAttrBPM;
extern PRItemAttr * const PRItemAttrYear;
extern PRItemAttr * const PRItemAttrTrackNumber;
extern PRItemAttr * const PRItemAttrTrackCount;
extern PRItemAttr * const PRItemAttrDiscNumber;
extern PRItemAttr * const PRItemAttrDiscCount;
extern PRItemAttr * const PRItemAttrCompilation;
/* Artwork Tags */
extern PRItemAttr * const PRItemAttrArtwork;
/* Custom Attributes */
extern PRItemAttr * const PRItemAttrArtistAlbumArtist;
extern PRItemAttr * const PRItemAttrDateAdded;
extern PRItemAttr * const PRItemAttrLastPlayed;
extern PRItemAttr * const PRItemAttrPlayCount;
extern PRItemAttr * const PRItemAttrRating;


@interface PRLibrary : NSObject
/* Initialization */
- (id)initWithDb:(PRDb *)db_;
- (instancetype)initWithConnection:(PRConnection *)connection;
- (void)create;
- (BOOL)initialize;

/* Accessors */
- (BOOL)containsItem:(PRItemID *)item;
- (PRItemID *)addItemWithAttrs:(NSDictionary *)attrs;
- (void)removeItems:(NSArray *)items;
- (id)valueForItem:(PRItemID *)item attr:(PRItemAttr *)attr;
- (void)setValue:(id)value forItem:(PRItemID *)item attr:(PRItemAttr *)attr;
- (NSDictionary *)attrsForItem:(PRItemID *)item;
- (void)setAttrs:(NSDictionary *)attrs forItem:(PRItemID *)item;

- (NSString *)artistValueForItem:(PRItemID *)item;
- (NSURL *)URLForItem:(PRItemID *)item;
- (NSArray *)itemsWithSimilarURL:(NSURL *)URL;
- (NSArray *)itemsWithValue:(id)value forAttr:(PRItemAttr *)attr;

/* zAccessors */
- (BOOL)zContainsItem:(PRItemID *)item out:(BOOL *)outValue;
- (BOOL)zAddItemWithAttrs:(NSDictionary *)attrs out:(PRItemID **)outValue;
- (BOOL)zRemoveItems:(NSArray *)items;
- (BOOL)zValueForItem:(PRItemID *)item attr:(PRItemAttr *)attr out:(id *)outValue;
- (BOOL)zSetValue:(id)value forItem:(PRItemID *)item attr:(PRItemAttr *)attr;
- (BOOL)zAttrsForItem:(PRItemID *)item out:(NSDictionary **)outValue;
- (BOOL)zSetAttrs:(NSDictionary *)attrs forItem:(PRItemID *)item;

- (BOOL)zItemDescriptionForItem:(PRItemID *)item out:(PRItem **)outValue;
- (BOOL)zSetItemDescription:(PRItem *)value forItem:(PRItemID *)item;

- (BOOL)zArtistValueForItem:(PRItemID *)item out:(NSString **)outValue;
- (BOOL)zURLForItem:(PRItemID *)item out:(NSURL **)outValue;
- (BOOL)zItemsWithSimilarURL:(NSURL *)url out:(NSArray **)outValue;
- (BOOL)zItemsWithValue:(id)value forAttr:(PRItemAttr *)attr out:(NSArray **)outValue;

/* Misc */
+ (NSArray *)itemAttrProperties;
+ (NSArray *)itemAttrs;
+ (NSString *)columnNameForItemAttr:(PRItemAttr *)attr;
+ (PRCol *)columnTypeForItemAttr:(PRItemAttr *)attr;
+ (NSString *)titleForItemAttr:(PRItemAttr *)attr;
+ (NSNumber *)internalForItemAttr:(PRItemAttr *)attr;
+ (PRItemAttr *)itemAttrForInternal:(NSNumber *)internal;
@end
