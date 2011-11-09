#import "PRNowPlayingController.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRPlaybackOrder.h"
#import "PRHistory.h"
#import "PRDb.h"
#import "PRTagEditor.h"
#import "PRMoviePlayer.h"
#import "PRQueue.h"
#import "PRUserDefaults.h"

@interface PRNowPlayingController ()

// ========================================
// Playback

- (void)playPlaylistItem:(PRPlaylistItem)playlistItem withSel:(SEL)selector; // should only be called by playPlayistItem: and playPlaylistItemIfNotQueued:
- (void)playPlaylistItem:(PRPlaylistItem)playlistItem;
- (void)playPlaylistItemIfNotQueued:(PRPlaylistItem)playlistItem;
- (PRPlaylistItem)nextItem:(BOOL)update;
- (PRPlaylistItem)previousItem:(BOOL)update;

// ========================================
// Update

- (void)movieDidFinish;
- (void)movieAlmostFinished;

// ========================================
// Order

@property (readwrite) int position;
@property (readwrite) int marker;

- (void)clearHistory;

@end

@implementation PRNowPlayingController

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_
{
    if (!(self = [super init])) {return nil;}
    db = db_;
    mov = [[PRMoviePlayer alloc] init];
    
    currentPlaylistItem = 0;
    [self clearHistory];
        
    // invalid songs
    _invalidSongs = [[NSMutableIndexSet alloc] init];
    
    // register for movie notifications
    [[NSNotificationCenter defaultCenter] observeMovieFinished:self sel:@selector(movieDidFinish)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeMovieAlmostFinished:self sel:@selector(movieAlmostFinished)];
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [mov release];
    [_invalidSongs release];
    [super dealloc];
}

// ========================================
// Accessors
// ========================================

@synthesize invalidSongs = _invalidSongs;
@synthesize mov;
@dynamic currentPlaylist;
@synthesize currentPlaylistItem;
@dynamic currentIndex;
@dynamic currentFile;

- (PRPlaylist)currentPlaylist
{
	return [[db playlists] nowPlayingPlaylist];
}

- (int)currentIndex
{	
	if (currentPlaylistItem == 0) {
        return 0;
	}
	return [[db playlists] indexForPlaylistItem:currentPlaylistItem];
}

- (PRFile)currentFile
{
	if ([self currentIndex] == 0) {
		return 0;
	} 
    return [[db playlists] fileAtIndex:[self currentIndex] forPlaylist:[self currentPlaylist]];
}

@dynamic shuffle;
@dynamic repeat;

- (int)repeat
{
	return [[PRUserDefaults userDefaults] repeat];
}

- (void)setRepeat:(int)repeat
{
    [[PRUserDefaults userDefaults] setRepeat:repeat];
    [[NSNotificationCenter defaultCenter] postRepeatChanged];
}

- (BOOL)shuffle
{
	return [[PRUserDefaults userDefaults] shuffle];
}

- (void)setShuffle:(BOOL)shuffle
{
	[[PRUserDefaults userDefaults] setShuffle:shuffle];
    [[NSNotificationCenter defaultCenter] postShuffleChanged];
}

- (void)toggleRepeat
{
	[self setRepeat:![self repeat]];
}

- (void)toggleShuffle
{
	[self setShuffle:![self shuffle]];
}

// ========================================
// Playback
// ========================================

- (void)stop 
{
	[mov stop];
	currentPlaylistItem = 0;
    [[NSNotificationCenter defaultCenter] postPlayingFileChanged];
	[self clearHistory];
}

- (IBAction)playPause
{
	if ([self currentIndex] == 0) {
		if ([[db playlists] countForPlaylist:[self currentPlaylist]] != 0) {
			[self playItemAtIndex:1];
		}
	} else {
        if ([mov isPlaying]) {
            [mov pause];
        } else {
            [mov unpause];
        }
	}
}

- (void)playItemAtIndex:(int)index
{
    [_invalidSongs removeAllIndexes];
	PRPlaylistItem item = [[db playlists] playlistItemAtIndex:index inPlaylist:[self currentPlaylist]];
    [[db queue] removePlaylistItem:item];
    [self clearHistory];
    [[db playbackOrder] appendPlaylistItem:item];
    self.position += 1;
    [self playPlaylistItem:item];
}

- (void)playNext
{
    PRPlaylistItem item = [self nextItem:TRUE];
    if (item == 0) {
        [self stop];
        return;
    }
    [self playPlaylistItem:item];
}

- (void)playPrevious
{
    PRPlaylistItem item = [self previousItem:TRUE];
    if (item == 0) {
        [self stop];
        return;
    }
    [self playPlaylistItem:item];
}

// ========================================
// Playback Priv
// ========================================

- (void)playPlaylistItem:(PRPlaylistItem)playlistItem withSel:(SEL)selector
{
    if ([_invalidSongs count] == [[db playlists] countForPlaylist:[self currentPlaylist]]) {
        [self stop];
        return;
    }
    PRFile file = [[db playlists] fileForPlaylistItem:playlistItem];
    currentPlaylistItem = playlistItem;
    
    // update tags
    BOOL updated = [[db library] updateTagsForFile:file];
    if (updated) {
        [[NSNotificationCenter defaultCenter] postFilesChanged:[NSIndexSet indexSetWithIndex:file]];
    }
    
    NSString *path = [[db library] valueForFile:file attribute:PRPathFileAttribute];
    if (![mov performSelector:selector withObject:path]) {
        // we delay posting playingFileChanged notification here because we recurse
        // until currentPlaylistItem is valid or 0.
        [_invalidSongs addIndex:file];
        [self playNext];
        return;
    }
    [[NSNotificationCenter defaultCenter] postPlayingFileChanged];
}

- (void)playPlaylistItem:(PRPlaylistItem)playlistItem
{
    [self playPlaylistItem:playlistItem withSel:@selector(play:)];
}

- (void)playPlaylistItemIfNotQueued:(PRPlaylistItem)playlistItem
{
    [self playPlaylistItem:playlistItem withSel:@selector(playIfNotQueued:)];
}

- (PRPlaylistItem)nextItem:(BOOL)update
{
    // if items in queue
    NSArray *queue = [[db queue] queueArray];
    if ([queue count] > 0) {
        PRPlaylistItem item = [[queue objectAtIndex:0] intValue];
        if (update) {
            [[db queue] removePlaylistItem:[[queue objectAtIndex:0] intValue]];
            if (![self shuffle]) {
                [self clearHistory];
            }
            [[db playbackOrder] appendPlaylistItem:item];
            [self setPosition:[self position] + 1];
        }
        return item;
    }
    
    // NOT SHUFFLE
    if (![self shuffle]) {
        if ([self currentIndex] < [[db playlists] countForPlaylist:[self currentPlaylist]]) {
            PRPlaylistItem item = [[db playlists] playlistItemAtIndex:[self currentIndex] + 1 inPlaylist:[self currentPlaylist]];
            if (update) {
                [self clearHistory];
                [[db playbackOrder] appendPlaylistItem:item];
                [self setPosition:[self position] + 1];
            }
            return item;
        } else {
            if ([self repeat]) {
                PRPlaylistItem item = [[db playlists] playlistItemAtIndex:1 inPlaylist:[self currentPlaylist]];
                if (update) {
                    [self clearHistory];
                    [[db playbackOrder] appendPlaylistItem:item];
                    [self setPosition:[self position] + 1];
                }
                return item;
            } else {
                return 0;
            }
        }
    }
    
    // SHUFFLE
    // if inside history
	if ([self position] < [[db playbackOrder] count]) {
		PRPlaylistItem item = [[db playbackOrder] playlistItemAtIndex:[self position] + 1];
        if (update) {
            [self setPosition:[self position] + 1];
        }
        return item;
	}
    
    // not inside history
    NSArray *availableSongs = [[db playbackOrder] playlistItemsInPlaylist:[self currentPlaylist] notInPlaybackOrderAfterIndex:[self marker]];
    if ([self repeat]) {
        int newMarker = [self marker];
        while ([availableSongs count] == 0 && newMarker < [[db playbackOrder] count]) {
            newMarker += floor([[db playlists] countForPlaylist:[self currentPlaylist]] * 0.25) + 1;
            if (newMarker > [[db playbackOrder] count]) {
                newMarker = [[db playbackOrder] count];
            }
            availableSongs = [[db playbackOrder] playlistItemsInPlaylist:[self currentPlaylist] notInPlaybackOrderAfterIndex:newMarker];
        }
        if (update) {
            [self setMarker:newMarker];
        }
    }
    if ([availableSongs count] > 0) {
		int item = [[availableSongs objectAtIndex:random() % [availableSongs count]] intValue];
        if (update) {
            [[db playbackOrder] appendPlaylistItem:item];
            [self setPosition:[self position] + 1];
        }
        return item;
    } else {
        return 0;
    }
}

- (PRPlaylistItem)previousItem:(BOOL)update
{
    // if playing song jump to beginning
    if ([mov currentTime] > 4000.0) {
        return [self currentPlaylistItem];
    }
    
    // NOT SHUFFLE
    if (![self shuffle]) {
        if ([self currentIndex] > 1) {
            PRPlaylistItem item = [[db playlists] playlistItemAtIndex:[self currentIndex] - 1 inPlaylist:[self currentPlaylist]];
            if (update) {
                [self clearHistory];
                [[db playbackOrder] appendPlaylistItem:item];
                [self setPosition:[self position] + 1];
                [[db queue] removePlaylistItem:item];
            }
            return item;
        } else {
            if ([self repeat]) {
                int count = [[db playlists] countForPlaylist:[self currentPlaylist]];
                PRPlaylistItem item = [[db playlists] playlistItemAtIndex:count inPlaylist:[self currentPlaylist]];
                if (update) {
                    [self clearHistory];
                    [[db playbackOrder] appendPlaylistItem:item];
                    [self setPosition:[self position] + 1];
                    [[db queue] removePlaylistItem:item];
                }
                return item;
            } else {
                return 0;
            }
        }
    }
    
    // SHUFFLE
    if ([self position] > 1) {
        PRPlaylistItem item = [[db playbackOrder] playlistItemAtIndex:[self position] - 1];
        if (update) {
            [self setPosition:[self position] - 1];
            [[db queue] removePlaylistItem:item];
        }
        return item;
    } else {
        return 0;
    }
}

// ========================================
// Update Priv
// ========================================

- (void)movieDidFinish
{
	int playCount = [[[db library] valueForFile:[self currentFile] attribute:PRPlayCountFileAttribute] intValue];
    [[db library] setValue:[NSNumber numberWithInt:playCount+1] forFile:[self currentFile] attribute:PRPlayCountFileAttribute];
    [[db library] setValue:[[NSDate date] description] forFile:[self currentFile] attribute:PRLastPlayedFileAttribute];
    [[db history] addFile:[self currentFile] withDate:[NSDate date]];
    
    PRPlaylistItem item = [self nextItem:TRUE];
    if (item == 0) {
        [self stop];
        return;
    }
    [self playPlaylistItemIfNotQueued:item];
}

- (void)movieAlmostFinished
{
    PRPlaylistItem item = [self nextItem:FALSE];
    if (item == 0) {
        return;
    }
    NSString *str = [[db library] valueForFile:[[db playlists] fileForPlaylistItem:item] attribute:PRPathFileAttribute];
    [mov queue:str];
}

- (void)playlistDidChange:(NSNotification *)notification
{
    if ([[[notification userInfo] objectForKey:@"playlist"] intValue] == [self currentPlaylist]) {
        [_invalidSongs removeAllIndexes];
        [self setPosition:[[db playbackOrder] count]];
        [self setMarker:[[db playbackOrder] count]];
    }
}

// ========================================
// Order Priv
// ========================================

@dynamic position;
@dynamic marker;

- (int)position
{
    if (_position < 0 || _position > [[db playbackOrder] count]) {
        NSLog(@"invalid orderPosition");
        return [[db playbackOrder] count];
    }
    return _position;
}

- (void)setPosition:(int)position
{
    _position = position;
}

- (int)marker
{
    if (_marker < 0 || _marker > [[db playbackOrder] count]) {
        NSLog(@"invalid orderMarker");
        return [[db playbackOrder] count];
    }
    return _marker;
}

- (void)setMarker:(int)marker
{
    _marker = marker;
}

- (void)clearHistory
{
	[[db playbackOrder] clear];
	_position = 0;
	_marker = 0;
}

@end