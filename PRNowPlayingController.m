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


NSString * const PRCurrentFileDidChangeNotification = @"PRCurrentFileDidChangeNotification";
NSString * const PRShuffleDidChangeNotification = @"PRShuffleDidChangeNotification";
NSString * const PRRepeatDidChangeNotification = @"PRRepeatDidChangeNotification";

@implementation PRNowPlayingController

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_
{
    if (!(self = [super init])) {return nil;}
    db = db_;
    mov = [[PRMoviePlayer alloc] init];
    
    currentPlaylist = [[db playlists] nowPlayingPlaylist];
    currentPlaylistItem = 0;
    [self clearHistory];
    
    // queue
    queue = [[NSMutableArray alloc] init];
    
    // invalid songs
    invalidSongs = [[NSMutableIndexSet alloc] init];
    
    // register for movie notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidFinish) name:PRMovieDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistDidChange:) name:PRPlaylistDidChangeNotification object:nil];
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PRMovieDidFinishNotification object:nil];
    [mov release];
    [super dealloc];
}

// ========================================
// Accessors
// ========================================

@synthesize invalidSongs;
@synthesize queue;
@dynamic shuffle;
@dynamic repeat;

- (PRMoviePlayer *)mov
{
    return mov;
}

- (int)repeat
{
	return [[PRUserDefaults userDefaults] repeat];
}

- (void)setRepeat:(int)repeat
{
    [[PRUserDefaults userDefaults] setRepeat:repeat];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRRepeatDidChangeNotification object:self];
}

- (BOOL)shuffle
{
	return [[PRUserDefaults userDefaults] shuffle];
}

- (void)setShuffle:(BOOL)shuffle
{
	[[PRUserDefaults userDefaults] setShuffle:shuffle];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRShuffleDidChangeNotification object:self];
}

- (PRPlaylist)currentPlaylist
{
	return currentPlaylist;
}

- (void)setCurrentPlaylist:(PRPlaylist)playlist
{
    [self stop];
	currentPlaylist = playlist;
}

- (int)currentIndex
{	
	if (currentPlaylistItem == 0) {
        return 0;
	}
	return [[db playlists] indexForPlaylistItem:currentPlaylistItem];
}

- (void)setCurrentIndex:(int)index
{
	if (index == 0) {
		currentPlaylistItem = 0;
	} else {
		currentPlaylistItem = [[db playlists] playlistItemAtIndex:index inPlaylist:currentPlaylist];
	}
    [self didChangeValueForKey:@"currentFile"];
    [self willChangeValueForKey:@"currentFile"];
}

- (PRFile)currentFile
{
	if ([self currentIndex] == 0) {
		return 0;
	} 
    return [[db playlists] fileAtIndex:[self currentIndex] forPlaylist:currentPlaylist];
}

- (void)appendToQueue:(PRPlaylistItem)playlistItem
{
    [queue addObject:[NSNumber numberWithInt:playlistItem]];
}

- (void)removeFromQueueObjectAtIndex:(int)index
{
    [queue removeObjectAtIndex:index];
}

- (void)clearQueue
{
    [queue removeAllObjects];
}

// ========================================
// Action
// ========================================

- (BOOL)playFileAtIndex:(int)index
{
    NSArray *array = [[db queue] queueArray];
    if ([array count] > 0) {
        PRPlaylistItem playlistItem = [[db playlists] playlistItemAtIndex:index inPlaylist:currentPlaylist]; 
        [[db queue] removePlaylistItem:playlistItem];
    }
    
	PRFile file = [[db playlists] fileAtIndex:index forPlaylist:currentPlaylist];
	NSString *URLString = [[db library] valueForFile:file attribute:PRPathFileAttribute];
    
    // update tags
    PRTagEditor *tagEditor = [[[PRTagEditor alloc] initWithFile:file db:db] autorelease];
    [tagEditor setPostNotification:TRUE];
    [tagEditor updateTags];
    [self setCurrentIndex:index];
    if (![mov openFileAndPlay:URLString]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PRCurrentFileDidChangeNotification object:self];
        [invalidSongs addIndex:file];
        [self movieDidFinish];
        return FALSE;
    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName:PRCurrentFileDidChangeNotification object:self];
    return TRUE;
}

- (void)stop 
{
	[mov stop];
	[self setCurrentIndex:0];
	[self clearHistory];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRCurrentFileDidChangeNotification 
                                                        object:self];
}

- (IBAction)playPause
{
	if ([self currentIndex] == 0) {
        int count = [[db playlists] countForPlaylist:currentPlaylist];
		if (count == 0) {
			return;
		}
		if ([self currentIndex] == 0) {
			[self setCurrentIndex:1];
		}
		[self playPlaylist:[self currentPlaylist] fileAtIndex:[self currentIndex]];
	} else {
        if ([mov isPlaying]) {
            [mov pause];
        } else {
            [mov play];
        }
	}
}

- (void)playPlaylist:(PRPlaylist)playlist fileAtIndex:(int)index
{
    if (playlist == [self currentPlaylist]) {
        currentPlaylist = playlist;
    } else {
        [self setCurrentPlaylist:playlist];
    }
	[self clearHistory];
    [invalidSongs release];
    invalidSongs = [[NSMutableIndexSet alloc] init];
	
	if ([self playFileAtIndex:index]) {
        [[db playbackOrder] appendPlaylistItem:currentPlaylistItem];
        orderPosition++;
    }
}

- (void)playNext
{
    BOOL shuffle = [self shuffle];
    BOOL repeat = [self repeat];
    // check if there are valid files
	int currentPlaylistCount = [[db playlists] countForPlaylist:currentPlaylist];
    bool areValidFiles = FALSE;
    for (int i = 1; i < currentPlaylistCount + 1; i++) {
        PRFile file = [[db playlists] fileAtIndex:i forPlaylist:currentPlaylist];
        if (![invalidSongs containsIndex:file]) {
            areValidFiles = TRUE;
            break;
        }
    }
    if (!areValidFiles) {
        [self stop];
        return;
    }
        
    NSArray *array = [[db queue] queueArray];
    if ([array count] > 0) {
        int index = [[db playlists] indexForPlaylistItem:[[array objectAtIndex:0] intValue]];
        [[db queue] removePlaylistItem:[[array objectAtIndex:0] intValue]];
        [self playFileAtIndex:index];
        if (shuffle) {
            [[db playbackOrder] appendPlaylistItem:currentPlaylistItem];
            orderPosition += 1;
        }
        return;
    }
        
	int ordCount = [[db playbackOrder] count];
    if (orderPosition < 0 || orderPosition > ordCount) {
        orderPosition = ordCount;
        NSLog(@"orderPostion inconsistency");
    }
    if (orderMarker < 0 || orderMarker > ordCount) {
        orderMarker = ordCount;
        NSLog(@"orderMarker inconsistency");
    }
    
    // take all songs in playlist. remove the songs in playbackOrder that are after playback marker.
    NSMutableArray *availableSongs = [NSMutableArray arrayWithArray:[[db playbackOrder] playlistItemsInPlaylist:currentPlaylist notInPlaybackOrderAfterIndex:orderMarker]];
	if (repeat == -1) {
		// if repeat song: repeat song
		[self playFileAtIndex:[self currentIndex]];
		
	} else if (shuffle && orderPosition < ordCount) {
		// if shuffle and inside history: play next song in history
		orderPosition += 1;
		PRPlaylistItem playlistItem = [[db playbackOrder] playlistItemAtIndex:orderPosition];
        int index = [[db playlists] indexForPlaylistItem:playlistItem];
		[self playFileAtIndex:index];
		
	} else if (shuffle && [availableSongs count] > 0) {
		// if shuffle, not in history and available songs: play random available song
		int rand = random() % [availableSongs count];
		int playlistItem = [[availableSongs objectAtIndex:rand] intValue];
		int index = [[db playlists] indexForPlaylistItem:playlistItem];
		if ([self playFileAtIndex:index]) {
            [[db playbackOrder] appendPlaylistItem:currentPlaylistItem];
            orderPosition += 1;
        }
	} else if (shuffle && [availableSongs count] == 0 && repeat == 0) {
		// if shuffle, not in history, no available songs and repeat is off: stop
		[self stop];
		[self clearHistory];
		
	} else if (shuffle && [availableSongs count] == 0 && repeat == 1) {
		// if shuffle, not in history, no available songs and repeat is on:
		// move the history index half a playlist forward and get new set of available songs
		orderMarker = ordCount - floor(currentPlaylistCount * 0.25);
		availableSongs = [NSMutableArray arrayWithArray:[[db playbackOrder] playlistItemsInPlaylist:currentPlaylist notInPlaybackOrderAfterIndex:orderMarker]];        
        if ([availableSongs count] == 0) {
            orderMarker = ordCount;
            NSLog(@"ordMarker reset");
        }
        [self playNext];
        
	} else if (!shuffle && [self currentIndex] < currentPlaylistCount) { 
		// if shuffle is off and songs left in playlist: play next song
		[self clearHistory];
        if ([self playFileAtIndex:[self currentIndex] + 1]) {
            [[db playbackOrder] appendPlaylistItem:currentPlaylistItem];
            orderPosition += 1;
        }
		
	} else if (!shuffle && repeat == 1) {
		// if shuffle is off, no songs left in playlist and repeat is on: repeat playlist
		[self clearHistory];
		if ([self playFileAtIndex:1]) {
            [[db playbackOrder] appendPlaylistItem:currentPlaylistItem];
            orderPosition += 1;
        }
		
	} else if (!shuffle && repeat == 0) {
		// if shuffle is off, no songs left in playlist and repeat is off: stop
		[self stop];
	}
}

- (void)playPrevious
{
    BOOL shuffle = [self shuffle];
    BOOL repeat = [self repeat];
	if ([mov currentTime] > 3000.0) {
		[self playFileAtIndex:[self currentIndex]];
	} else if (repeat == -1) {
		// if repeat song: repeat song
		[self clearHistory];
		[self playFileAtIndex:[self currentIndex]];
		[[db playbackOrder] appendPlaylistItem:currentPlaylistItem];
		orderPosition += 1;
		
	} else if (!shuffle && [self currentIndex] > 1) {
		// if shuffle is off and previous songs: play previous song
		[self clearHistory];
		[self playFileAtIndex:[self currentIndex] - 1];
		[[db playbackOrder] appendPlaylistItem:currentPlaylistItem];
		orderPosition += 1;
		
	} else if (!shuffle && repeat == 0) {
		// if shuffle is off, repeat is off and no previous songs: stop
		[self stop];
		
	} else if (!shuffle && repeat == 1) {
		// if shuffle is off, repeat is on and no previous songs: play last song
		int count = [[db playlists] countForPlaylist:currentPlaylist];
		[self clearHistory];
		[self playFileAtIndex:count];
		orderPosition += 1;
		
	} else if (shuffle && orderPosition > 1) {
		// if shuffle is on and songs left in playbackOrder: play song
		orderPosition -= 1;
		PRPlaylistItem playlistItem = [[db playbackOrder] playlistItemAtIndex:orderPosition];
        int index = [[db playlists] indexForPlaylistItem:playlistItem];
		[self playFileAtIndex:index];
		
	} else if (shuffle && repeat == 0) {
		// if shuffle is on, repeat is off and no songs left in playbackOrder:stop
		[self stop];
		
	} else if (shuffle && repeat == 1) {
		// if shuffle is on, repeat is on and no songs left in playbackOrder:play random song and insert into playback order at beginning
		[self stop];
	}
}

- (void)toggleRepeat
{
	[self setRepeat:![self repeat]];
}

- (void)toggleShuffle
{
	[self setShuffle:![self shuffle]];
}

- (void)clearHistory
{
	[[db playbackOrder] clear];
	orderPosition = 0;
	orderMarker = 0;
}

- (void)postNotificationForCurrentPlaylist
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentPlaylist] forKey:@"playlist"];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistDidChangeNotification object:self userInfo:userInfo];
}

// ========================================
// Update
// ========================================

- (void)movieDidFinish
{
	int playCount = [[[db library] valueForFile:[self currentFile] attribute:PRPlayCountFileAttribute] intValue];
    [[db library] setValue:[NSNumber numberWithInt:playCount+1] forFile:[self currentFile] attribute:PRPlayCountFileAttribute];
    [[db library] setValue:[[NSDate date] description] forFile:[self currentFile] attribute:PRLastPlayedFileAttribute];
    [[db history] addFile:[self currentFile] withDate:[NSDate date]];
	[self playNext];
}

- (void)playlistDidChange:(NSNotification *)notification
{
    orderPosition = [[db playbackOrder] count];;
    orderMarker = orderPosition;
}

@end