#import <Cocoa/Cocoa.h>
@class PRDb, PRStatement;


extern NSString * const libraryViewSource;
extern NSString * const browser1ViewSource;
extern NSString * const browser2ViewSource;
extern NSString * const browser3ViewSource;
extern NSString * const PRCompilationString;

typedef enum {
    PRLibraryView = 1 << 0,
    PRBrowser1View = 1 << 1,
    PRBrowser2View = 1 << 2,
    PRBrowser3View = 1 << 3,
} PRBrowser;


@interface PRLibraryViewSource : NSObject
/* Initialization */
- (id)initWithDb:(PRDb *)sqlDb;
- (void)create;
- (BOOL)initialize;

/* Update */
- (int)refreshWithList:(PRList *)list force:(BOOL)force;

- (BOOL)zCount:(NSInteger *)outValue;

/* Library Accessors */
- (int)count;
- (PRItem *)itemForRow:(int)row;
- (int)rowForItem:(PRItem *)item;
- (id)valueForRow:(int)row attribute:(PRItemAttr *)attribute andCacheAttributes:(NSArray *(^)(void))attributes;

- (int)firstRowWithValue:(id)value forAttr:(PRItemAttr *)attr;
- (NSDictionary *)info;
- (NSArray *)albumCounts;

/* Browser Accessor */
- (int)countForBrowser:(int)browser;
- (NSString *)valueForRow:(int)row browser:(int)browser;
- (NSIndexSet *)selectionForBrowser:(int)browser;
@end
