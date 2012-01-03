#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRLibraryViewController.h"

@class PRDb;

// ========================================
// Constants

extern NSString * const libraryViewSource;
extern NSString * const browser1ViewSource;
extern NSString * const browser2ViewSource;
extern NSString * const browser3ViewSource;

typedef enum {
    PRLibraryView = 1 << 0,
    PRBrowser1View = 1 << 1,
    PRBrowser2View = 1 << 2,
    PRBrowser3View = 1 << 3,
} PRBrowser;

// ========================================
// PRLibraryViewSource
// ========================================
@interface PRLibraryViewSource : NSObject 
{
	PRDb *db;
	
    PRPlaylist _playlist;
    NSCache *_cachedValues;
    BOOL _compilation;
    
    BOOL _force;
    NSString *_prevSourceString;
    NSDictionary *_prevSourceBindings;
    NSString *prevBrowser1Statement;
    NSDictionary *prevBrowser1Bindings;
    NSString *prevBrowser2Statement;
    NSDictionary *prevBrowser2Bindings;
    NSString *prevBrowser3Statement;
    NSDictionary *prevBrowser3Bindings;
    
    NSString *_cachedSortIndexStatement;
    NSString *_cachedBrowser1Statement;
    NSString *_cachedBrowser2Statement;
    NSString *_cachedBrowser3Statement;
    BOOL _cachedCompilation;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)sqlDb;
- (void)create;
- (BOOL)initialize;

// =======================================
// Update

- (int)refreshWithPlaylist:(PRPlaylist)playlist force:(BOOL)force;
- (BOOL)updateSortIndex;
- (BOOL)populateSource;
- (BOOL)populateBrowser:(int)browser;

// ========================================
// Library Accessors

- (int)count;
- (PRFile)fileForRow:(int)row;
- (int)rowForFile:(PRFile)file;
- (id)valueForRow:(int)row attribute:(PRFileAttribute)attribute andCacheAttributes:(NSArray *)attributes;

- (NSDictionary *)info;
- (NSArray *)albumCounts;

// ========================================
// Browser Accessors

- (int)countForBrowser:(int)browser;
- (NSString *)valueForRow:(int)row browser:(int)browser;
- (NSIndexSet *)selectionForBrowser:(int)browser;

- (BOOL)compilation;

// ========================================
// Misc

- (BOOL)compilationForBrowser:(int)browser;
- (int)firstRowWithValue:(id)value forAttribute:(PRFileAttribute)attribute;
- (NSString *)tableNameForBrowser:(int)browser;
- (NSString *)groupingStringForPlaylist:(PRPlaylist)playlist browser:(int)browser;

@end
