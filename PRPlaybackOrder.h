#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"

@class PRDb;

// ========================================
// Class - PRPlaybackOrder
// ========================================

@interface PRPlaybackOrder : NSObject 
{
	PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)sqlDb;

- (void)create;
- (void)initialize;
- (BOOL)validate;

// ========================================
// Validation

- (BOOL)clean_error:(NSError **)error;

// ========================================
// Accessors

- (BOOL)count:(int *)count _error:(NSError **)error;
- (BOOL)playlistItem:(PRPlaylistItem *)playlistItem atIndex:(int)index _error:(NSError **)error;
- (BOOL)appendPlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error;
- (BOOL)clearPlaybackOrder_error:(NSError **)error;

- (BOOL)removePlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error;

- (BOOL)		 playlistItems:(NSArray **)playlistItems 
			        inPlaylist:(PRPlaylist)playlist 
  notInPlaybackOrderAfterIndex:(int)index
						_error:(NSError **)error;

// ========================================
// Update

- (BOOL)confirmPlaylistItemDelete:(NSError **)error;

@end
