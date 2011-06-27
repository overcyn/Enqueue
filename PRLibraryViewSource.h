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
	
    int cachedRow;
    NSDictionary *cachedValues;
    
    BOOL force;
    NSString *prevLibraryStatement;
    NSDictionary *prevLibraryBindings;
    NSString *prevBrowser1Statement;
    NSDictionary *prevBrowser1Bindings;
    NSString *prevBrowser2Statement;
    NSDictionary *prevBrowser2Bindings;
    NSString *prevBrowser3Statement;
    NSDictionary *prevBrowser3Bindings;
    
    NSString *prevSortStatement;
    NSString *prevBrowser1Grouping;
    NSString *prevBrowser2Grouping;
    NSString *prevBrowser3Grouping;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)sqlDb;

- (BOOL)create_error:(NSError **)error;
- (BOOL)initialize_error:(NSError **)error;
- (BOOL)validate_error:(NSError **)error;

// =======================================
// Update

- (BOOL)forceUpdateOnNextRefresh_error:(NSError **)error;
- (BOOL)refreshWithPlaylist:(PRPlaylist)playlist tablesToUpdate:(int *)tables _error:(NSError **)error;

- (BOOL)updateSortIndexWithPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)populateSourceWithPlaylist:(PRPlaylist)playlist didUpdate:(BOOL *)didUpdate _error:(NSError **)error;
- (BOOL)populateBrowser:(int)browser withPlaylist:(PRPlaylist)playlist didUpdate:(BOOL *)didUpdate _error:(NSError **)error;


// ========================================
// Accessors

@property (readwrite, retain) NSDictionary *cachedValues;

- (NSString *)tableNameForBrowser:(int)browser;
+ (PRPlaylistAttribute)groupingPlaylistAttributeForBrowser:(int)browser;
- (NSString *)groupingStringForPlaylist:(PRPlaylist)playlist browser:(int)browser;
+ (PRPlaylistAttribute)selectionPlaylistAttributeForBrowser:(int)browser;
- (NSArray *)selectionForPlaylist:(PRPlaylist)playlist browser:(int)browser;


- (BOOL)count:(int *)count _error:(NSError **)error;
- (BOOL)file:(PRFile *)file forRow:(int)row _error:(NSError **)error;
- (BOOL)     value:(id *)value 
            forRow:(int)row 
         attribute:(PRFileAttribute)attribute 
  cachedAttributes:(NSArray *)cachedAttributes 
            _error:(NSError **)error;
- (BOOL)row:(int *)row forFile:(PRFile)file _error:(NSError **)error;

- (BOOL)count:(int *)count forBrowser:(int)browser _error:(NSError **)error;
- (BOOL)value:(NSString **)value_ forRow:(int)row browser:(int)browser _error:(NSError **)error;

- (BOOL)selectionIndexSet:(NSIndexSet **)indexSet 
			   forBrowser:(int)browser 
			 withPlaylist:(int)playlist 
				   _error:(NSError **)error;

- (BOOL)totalTime:(long long *)time _error:(NSError **)error;
- (BOOL)totalSize:(long long *)size_ _error:(NSError **)error;

- (BOOL)arrayOfAlbumCounts:(NSArray **)array _error:(NSError **)error;

@end