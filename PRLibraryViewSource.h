#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRLibraryViewController.h"

@class PRDb;
@class PRPlaylists;

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
// Class - PRLibraryViewSource
// ========================================
@interface PRLibraryViewSource : NSObject 
{
	PRDb *db;
	PRPlaylists *play;
	
    PRPlaylist _playlist;
    NSCache *_cachedValues;
    
    BOOL _force;
    NSString *_prevSourceString;
    NSDictionary *_prevSourceBindings;
    NSString *prevBrowser1Statement;
    NSDictionary *prevBrowser1Bindings;
    NSString *prevBrowser2Statement;
    NSDictionary *prevBrowser2Bindings;
    NSString *prevBrowser3Statement;
    NSDictionary *prevBrowser3Bindings;
    
    NSString *_prevSort;
    NSString *_prevBrowser1Grouping;
    NSString *_prevBrowser2Grouping;
    NSString *_prevBrowser3Grouping;
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
// Accessors

- (NSDictionary *)info;

- (int)count;
- (PRFile)fileForRow:(int)row;
- (int)rowForFile:(PRFile)file;
- (id)valueForRow:(int)row attribute:(PRFileAttribute)attribute andCacheAttributes:(NSArray *)attributes;

- (int)countForBrowser:(int)browser;
- (NSString *)valueForRow:(int)row browser:(int)browser;
- (NSIndexSet *)selectionForBrowser:(int)browser;

- (NSArray *)albumCounts;

// ========================================
// Misc

- (int)firstRowWithValue:(id)value forAttribute:(PRFileAttribute)attribute;
- (NSString *)tableNameForBrowser:(int)browser;
- (NSString *)groupingStringForPlaylist:(PRPlaylist)playlist browser:(int)browser;

@end