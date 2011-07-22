#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRDb.h"

@class PRDb;

// ========================================
// Constants & Typedefs

typedef int PRPlaylist;
typedef int PRPlaylistItem;

typedef enum {
	PRLibraryPlaylistType = 0,
    PRNowPlayingPlaylistType = 1,
	PRStaticPlaylistType = 2,
	PRSmartPlaylistType = 3,
    PRDuplicatePlaylistType = 4,
    PRMissingPlaylistType = 5,
} PRPlaylistType;

typedef enum {
	PRTitlePlaylistAttribute,
	PRTypePlaylistAttribute,
	PRRulesPlaylistAttribute,
	PRListViewColumnInfoPlaylistAttribute,
	PRListViewSortColumnPlaylistAttribute,
	PRListViewAscendingPlaylistAttribute,
	PRAlbumListViewColumnInfoPlaylistAttribute,
	PRAlbumListViewSortColumnPlaylistAttribute,
	PRAlbumListViewAscendingPlaylistAttribute,
	PRSearchPlaylistAttribute,
	PRBrowser1AttributePlaylistAttribute,
	PRBrowser2AttributePlaylistAttribute,
	PRBrowser3AttributePlaylistAttribute,
	PRBrowser1SelectionPlaylistAttribute,
	PRBrowser2SelectionPlaylistAttribute,
	PRBrowser3SelectionPlaylistAttribute,
	PRBrowserInfoPlaylistAttribute,
	PRLibraryViewModePlaylistAttribute,
} PRPlaylistAttribute;

typedef enum {
	PRArtistAlbumSort = -1,
	PRPlaylistIndexSort = -2,
} PRSort;

// ========================================
// Class - PRPlaylists
// ========================================
@interface PRPlaylists : NSObject 
{
	PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_;

- (void)create;
- (void)initialize;
- (BOOL)validate;

// ========================================
// Accessors

+ (NSDictionary *)columnDict;
+ (NSString *)columnNameForPlaylistAttribute:(PRPlaylistAttribute)attribute;
+ (PRColumn)columnForPlaylistAttribute:(PRPlaylistAttribute)attribute;
//
- (BOOL)cleanPlaylists;
- (BOOL)cleanPlaylistItems_error:(NSError **)error;

// ========================================
// Playlist Accessors

- (NSArray *)playlists;
- (NSArray *)playlistsWithAttributes;

- (PRPlaylist)addPlaylist;
- (PRPlaylist)addStaticPlaylist;
- (PRPlaylist)addSmartPlaylist;
- (void)removePlaylist:(PRPlaylist)playlist;

- (void)setValue:(id)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute;
- (id)valueForPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute;

- (PRPlaylist)libraryPlaylist;
- (PRPlaylist)nowPlayingPlaylist;

// ========================================
// Playlist Update

- (BOOL)propagatePlaylistDelete_error:(NSError **)error;

// ========================================
// PlaylistItems Accessors

// Setters
- (void)addFile:(PRFile)file atIndex:(int)index toPlaylist:(PRPlaylist)playlist;
- (void)appendFile:(PRFile)file toPlaylist:(PRPlaylist)playlist;
- (void)appendFiles:(NSIndexSet *)files toPlaylist:(PRPlaylist)playlist;
- (void)removeFileAtIndex:(int)index fromPlaylist:(PRPlaylist)playlist;
- (void)removeFilesAtIndexes:(NSIndexSet *)indexes fromPlaylist:(PRPlaylist)playlist;
- (void)clearPlaylist:(PRPlaylist)playlist;
- (void)clearPlaylist:(PRPlaylist)playlist exceptForIndex:(int)index;
- (void)moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(int)index inPlaylist:(PRPlaylist)playlist;
- (void)appendFilesFromLibraryViewSourceToPlaylist:(PRPlaylist)playlist;
- (void)copyFilesFromPlaylist:(PRPlaylist)playlist toPlaylist:(PRPlaylist)playlist2;

// Getters
- (int)countForPlaylist:(PRPlaylist)playlist;
- (PRPlaylistItem)playlistItemAtIndex:(int)index inPlaylist:(PRPlaylist)playlist;
- (PRFile)fileAtIndex:(int)index forPlaylist:(PRPlaylist)playlist;
- (PRFile)fileForPlaylistItem:(PRPlaylistItem)playlistItem;
- (int)indexForPlaylistItem:(PRPlaylistItem)playlistItem;
- (PRPlaylist)playlistForPlaylistItem:(PRPlaylistItem)playlistItem;
- (BOOL)playlist:(PRPlaylist)playlist containsFile:(PRFile)file;

- (BOOL)playlistIndexes:(NSIndexSet **)indexes forPlaylist:(PRPlaylist)playlist file:(PRFile)file _error:(NSError **)error;

// ========================================
// PlaylistItems Update

- (BOOL)confirmFileDelete_error:(NSError **)error;
- (BOOL)confirmPlaylistDelete_error:(NSError **)error;
- (BOOL)propagatePlaylistItemDelete_error:(NSError **)error;

@end