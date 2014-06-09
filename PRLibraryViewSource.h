#import <Cocoa/Cocoa.h>
@class PRDb, PRStatement;


extern NSString * const libraryViewSource;
extern NSString * const browser1ViewSource;
extern NSString * const browser2ViewSource;
extern NSString * const browser3ViewSource;
extern NSString * const compilationString;

typedef enum {
    PRLibraryView = 1 << 0,
    PRBrowser1View = 1 << 1,
    PRBrowser2View = 1 << 2,
    PRBrowser3View = 1 << 3,
} PRBrowser;


@interface PRLibraryViewSource : NSObject {
	__weak PRDb *_db;
	
    // state of current/last refresh
    PRList *_list;
    BOOL _force;
    
    // flag indicating if compilations browser item should be shown.
    BOOL _compilation;
    
    // info about last refresh so as not to unnecessarily repopulate tables
    NSString *_prevSourceString;
    NSDictionary *_prevSourceBindings;
    NSString *prevBrowser1Statement;
    NSDictionary *prevBrowser1Bindings;
    NSString *prevBrowser2Statement;
    NSDictionary *prevBrowser2Bindings;
    NSString *prevBrowser3Statement;
    NSDictionary *prevBrowser3Bindings;
    
    // cache for basic library with no browser selection or search
    NSString *_cachedLibraryStatement;
    NSString *_cachedBrowser1Statement;
    NSString *_cachedBrowser2Statement;
    NSString *_cachedBrowser3Statement;
    BOOL _cachedCompilation;
    
    // cache for valueForRow:attribute:andCacheAttributes:
    int _cachedRow;
    NSArray *_cachedAttrs;
    NSArray *_cachedAttrValues;
    PRStatement *_cachedStatement;
}
/* Initialization */
- (id)initWithDb:(PRDb *)sqlDb;
- (void)create;
- (BOOL)initialize;

/* Update */
- (int)refreshWithList:(PRList *)list force:(BOOL)force;

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
