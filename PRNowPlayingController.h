/*
 Shuffle is implemented in the following manner: PRPlaybackOrder contains a list of recently played
 playlist_item_ids from oldest to newest. orderPosition indicates the current position in the 
 playlist history. Ordinarily this would be the last item in playbackorder. 
 
         <-- 0 : Marker
 0  fileA
         <-- 1
 1  fileB
         <-- 2
 2  fileC
         <-- 3
 3  fileD
         <-- 4 : Position
 count:4
 
 orderPostion by default when not in history would be 4.
 orderMarker by default would be 0.
 */

#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
#import "PRLibrary.h"


@class PRDb, PRPlaybackOrder, PRHistory, PRMoviePlayer;

@interface PRNowPlayingController : NSObject 
{
	PRPlaylistItem currentPlaylistItem; // 0 if none
	int _position; // current position in playback history. usually count of playbackorder
	int _marker; // position in history AFTER which not to random from
	NSMutableIndexSet *_invalidSongs;
    
	PRMoviePlayer *mov;

	// weak
	PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_;

// ========================================
// Accessors

@property (readonly) NSMutableIndexSet *invalidSongs;
@property (readonly) PRMoviePlayer *mov;
@property (readonly) PRPlaylist currentPlaylist;
@property (readonly) PRPlaylistItem currentPlaylistItem;
@property (readonly) PRFile currentFile; // convenience method
@property (readonly) int currentIndex; // convenience method

@property (readwrite) BOOL shuffle;
@property (readwrite) int repeat;

- (void)toggleRepeat;
- (void)toggleShuffle;

// ========================================
// Playback

- (void)playItemAtIndex:(int)index;
- (void)playPause;
- (void)playNext;
- (void)playPrevious;
- (void)stop;

@end
