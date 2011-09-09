/*
 Shuffle is implemented in the following manner: PRPlaybackOrder contains a list of recently played
 playlist_item_ids from oldest to newest. orderPosition indicates the current position in the 
 playlist history. Ordinarily this would be the last item in playbackorder. 
 */

#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
#import "PRLibrary.h"


extern NSString * const PRCurrentFileDidChangeNotification;
extern NSString * const PRShuffleDidChangeNotification;
extern NSString * const PRRepeatDidChangeNotification;

@class PRDb, PRPlaybackOrder, PRHistory, PRMoviePlayer;

@interface PRNowPlayingController : NSObject 
{	
	PRPlaylist currentPlaylist;
	PRPlaylistItem currentPlaylistItem; // 0 if none
	
	NSMutableArray *queue;
    
    // current position in playback history. usually the end
	int orderPosition;
	// position in history BEFORE which not to play from
	int orderMarker;
	
	PRMoviePlayer *mov;
	
    NSMutableIndexSet *invalidSongs;
    
	// weak
	PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_;

// ========================================
// Accessors

@property (readonly) NSMutableIndexSet *invalidSongs;
@property (readonly) NSMutableArray *queue;
@property (readwrite) BOOL shuffle;
@property (readwrite) int repeat;

- (PRMoviePlayer *)mov;
- (PRPlaylist)currentPlaylist;
- (void)setCurrentPlaylist:(PRPlaylist)playlist;
- (int)currentIndex;
- (void)setCurrentIndex:(int)index; // private
- (PRFile)currentFile;

- (void)appendToQueue:(PRPlaylistItem)playlistItem;
- (void)removeFromQueueObjectAtIndex:(int)index;
- (void)clearQueue;

// ========================================
// Action

- (void)stop;
- (void)playPause;
- (void)playPlaylist:(PRPlaylist)playlist fileAtIndex:(int)index;
- (void)playNext;
- (void)playPrevious;

- (void)toggleRepeat;
- (void)toggleShuffle;

- (void)clearHistory;

- (void)postNotificationForCurrentPlaylist;

// Update
- (void)movieDidFinish;

@end


// Private methods for PRNowPlayingController
//
@interface PRNowPlayingController ()

- (BOOL)playFileAtIndex:(int)index;

@end