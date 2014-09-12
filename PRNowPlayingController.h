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

@class PRDb;
@class PRMoviePlayer;
@class PRNowPlayingDescription;
@class PRConnection;


@interface PRNowPlayingController : NSObject
/* Initialization */
- (id)initWithDb:(PRDb *)db;
- (id)initWithConnection:(PRConnection *)conn;

/* Accessors */
@property (nonatomic, readonly) PRNowPlayingDescription *description;

@property (readonly) NSArray *invalidItems;
@property (readonly) PRMoviePlayer *mov;
@property (readonly) PRList *currentList;
@property (readonly) PRListItem *currentListItem;
@property (readonly) PRItem *currentItem;
@property (readonly) int currentIndex;

@property (readwrite) BOOL shuffle;
@property (readwrite) int repeat;
- (void)toggleRepeat;
- (void)toggleShuffle;

/* Playback */
- (void)playItemAtIndex:(int)index;
- (void)playPause;
- (void)playNext;
- (void)playPrevious;
- (void)stop;
@end
