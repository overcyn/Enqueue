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
- (BOOL)initialize;

// ========================================
// Validation

- (void)clean;

// ========================================
// Accessors

- (int)count;
- (void)appendPlaylistItem:(PRPlaylistItem)playlistItem;
- (PRPlaylistItem)playlistItemAtIndex:(int)index;
- (void)clear;

- (NSArray *)playlistItemsInPlaylist:(PRPlaylist)playlist notInPlaybackOrderAfterIndex:(int)index;

// ========================================
// Update

- (BOOL)confirmPlaylistItemDelete:(NSError **)error;

@end
