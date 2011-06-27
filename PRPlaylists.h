#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"

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

- (BOOL)create_error:(NSError **)error;
- (BOOL)initialize_error:(NSError **)error;
- (BOOL)validate_error:(NSError **)error;

// ========================================
// Accessors

+ (NSDictionary *)columnDict;
+ (NSString *)columnNameForPlaylistAttribute:(PRPlaylistAttribute)attribute;

//
- (BOOL)cleanPlaylists;
- (BOOL)cleanPlaylistItems_error:(NSError **)error;

// ========================================
// Playlist Accessors

- (NSArray *)playlists;
- (NSArray *)playlistsWithAttributes;

- (BOOL)addPlaylist:(PRPlaylist *)playlist atIndex:(int)index _error:(NSError **)error;
- (BOOL)appendPlaylist:(PRPlaylist *)playlist _error:(NSError **)error;
- (BOOL)removePlaylist:(PRPlaylist)playlist _error:(NSError **)error;

- (BOOL)addStaticPlaylist:(PRPlaylist *)playlist _error:(NSError *)error;
- (BOOL)addSmartPlaylist:(PRPlaylist *)playlist _error:(NSError *)error;

- (BOOL)playlistCount:(int *)count _error:(NSError **)error;
- (BOOL)playlistArray:(NSArray **)playlistArray _error:(NSError **)error;
- (BOOL)value:(id *)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error;
- (BOOL)setValue:(id)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error;
- (BOOL)intValue:(int *)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error;
- (BOOL)setIntValue:(int)value forPlaylist:(PRPlaylist)playlist attribute:(PRPlaylistAttribute)attribute _error:(NSError **)error;

- (PRPlaylist)libraryPlaylist;
- (PRPlaylist)nowPlayingPlaylist;

// ========================================
// Playlist Update

- (BOOL)propagatePlaylistDelete_error:(NSError **)error;

// ========================================
// PlaylistItems Accessors

- (BOOL)addFile:(PRFile)file atIndex:(int)index toPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)appendFile:(PRFile)file toPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)removeFileAtIndex:(int)index forPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)removeFilesAtIndexes:(NSIndexSet *)indexSet forPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)clearPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)clearPlaylist:(PRPlaylist)playlist exceptForIndex:(int)index _error:(NSError **)error;
- (BOOL)moveItemsAtIndexes:(NSIndexSet *)indexSet inPlaylist:(PRPlaylist)playlist toRow:(int)row error:(NSError **)error;
- (BOOL)appendFilesFromLibraryViewSourceToPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)copyFilesFromPlaylist:(PRPlaylist)playlist toPlaylist:(PRPlaylist)playlist2 _error:(NSError **)error;

- (BOOL)count:(int *)count forPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)file:(PRFile *)file atIndex:(int)index forPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)contains:(BOOL *)contains file:(PRFile)file inPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)playlistItem:(PRPlaylistItem *)playlistItem atIndex:(int)index forPlaylist:(PRPlaylist)playlist _error:(NSError **)error;
- (BOOL)index:(int *)index andPlaylist:(PRPlaylist *)playlist forPlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error;

- (BOOL)playlistIndexes:(NSIndexSet **)indexes forPlaylist:(PRPlaylist)playlist file:(PRFile)file _error:(NSError **)error;

// ========================================
// PlaylistItems Update

- (BOOL)confirmFileDelete_error:(NSError **)error;
- (BOOL)confirmPlaylistDelete_error:(NSError **)error;
- (BOOL)propagatePlaylistItemDelete_error:(NSError **)error;

@end