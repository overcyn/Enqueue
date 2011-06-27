#import "PRNowPlayingController.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRPlaybackOrder.h"
#import "PRHistory.h"
#import "PRDb.h"
#import "PRTagEditor.h"
#import "PRMoviePlayer.h"
#import "PRQueue.h"


NSString * const PRCurrentFileDidChangeNotification = @"PRCurrentFileDidChangeNotification";
NSString * const PRShuffleDidChangeNotification = @"PRShuffleDidChangeNotification";
NSString * const PRRepeatDidChangeNotification = @"PRRepeatDidChangeNotification";

@implementation PRNowPlayingController

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_
{
    self = [super init];
	if (self) {
		db = db_;
		lib = [db library];
		play = [db playlists];
		ord = [db playbackOrder];
        mov = [[PRMoviePlayer alloc] init];
        
		currentPlaylist = [[db playlists] nowPlayingPlaylist];
		currentPlaylistItem = 0;
		[self clearHistory];
        
        // queue
        queue = [[NSMutableArray alloc] init];
        
        // invalid songs
        invalidSongs = [[NSMutableIndexSet alloc] init];
		
		// register for movie notifications
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(movieDidFinish) 
													 name:PRMovieDidFinishNotification 
												   object:nil];
		
        // register defaults
		[[NSUserDefaults standardUserDefaults] registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:0], @"repeat",
          [NSNumber numberWithBool:FALSE], @"shuffle",
          [NSNumber numberWithFloat:1.0], @"volume",
          nil]];
		repeat = [[NSUserDefaults standardUserDefaults] integerForKey:@"repeat"];
		shuffle = [[NSUserDefaults standardUserDefaults] boolForKey:@"shuffle"];
	}
	
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

- (PRMoviePlayer *)mov
{
    return mov;
}

- (int)repeat
{
	return repeat;
}

- (void)setRepeat:(int)repeat_
{
	repeat = repeat_;
	[[NSUserDefaults standardUserDefaults] setInteger:repeat forKey:@"repeat"];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRRepeatDidChangeNotification object:self];
}

- (BOOL)shuffle
{
	return shuffle;
}

- (void)setShuffle:(BOOL)shuffle_
{
	shuffle = shuffle_;
	[[NSUserDefaults standardUserDefaults] setBool:shuffle forKey:@"shuffle"];
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
	
    int index;
	PRPlaylist playlist;
	[play index:&index andPlaylist:&playlist forPlaylistItem:currentPlaylistItem _error:nil];
	
	return index;
}

- (void)setCurrentIndex:(int)index
{
	PRPlaylistItem playlistFilesID;
	if (index == 0) {
		currentPlaylistItem = 0;
	} else {
		[play playlistItem:&playlistFilesID atIndex:index forPlaylist:currentPlaylist _error:nil];
		currentPlaylistItem = playlistFilesID;
	}
    [self didChangeValueForKey:@"currentFile"];
    [self willChangeValueForKey:@"currentFile"];
}

- (PRFile)currentFile
{
	PRFile file_;
	
	if ([self currentIndex] == 0) {
		file_ = 0;
	} else {		
		[play file:&file_ atIndex:[self currentIndex] forPlaylist:currentPlaylist _error:NULL];
	}
	
	return file_;
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
    NSArray *array;
    [[db queue] queueArray:&array _error:nil];
    if ([array count] > 0) {
        PRPlaylistItem playlistItem;
        [[db playlists] playlistItem:&playlistItem atIndex:index forPlaylist:currentPlaylist _error:nil];    
        [[db queue] removePlaylistItem:playlistItem _error:nil];
    }
    
	PRFile file;
	NSString *URLString;
	[play file:&file atIndex:index forPlaylist:currentPlaylist _error:nil];
	[lib value:&URLString forFile:file attribute:PRPathFileAttribute _error:nil];
    
    // update tags
    PRTagEditor *tagEditor = [[[PRTagEditor alloc] initWithFile:file db:db] autorelease];
    [tagEditor updateTagsAndPostNotification:TRUE];
    [self setCurrentIndex:index];
    if (![mov openFileAndPlay:URLString]) {
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
        int count;
		[play count:&count forPlaylist:currentPlaylist _error:nil];
		
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
        [ord appendPlaylistItem:currentPlaylistItem _error:nil];
        orderPosition++;
    }
}

- (void)playNext
{
    // check if there are valid files
	int currentPlaylistCount;
    [play count:&currentPlaylistCount forPlaylist:currentPlaylist _error:nil];
    bool areValidFiles = FALSE;
    for (int i = 1; i < currentPlaylistCount + 1; i++) {
        PRFile file;
        [play file:&file atIndex:i forPlaylist:currentPlaylist _error:nil];
        if (![invalidSongs containsIndex:file]) {
            areValidFiles = TRUE;
        }
    }
    if (!areValidFiles) {
        [self stop];
        return;
    }
    
    NSArray *array;
    [[db queue] queueArray:&array _error:nil];
    if ([array count] > 0) {
        int index;
        PRPlaylist playlist;
        [[db playlists] index:&index andPlaylist:&playlist forPlaylistItem:[[array objectAtIndex:0] intValue] _error:nil];
        [[db queue] removePlaylistItem:[[array objectAtIndex:0] intValue] _error:nil];
        [self playFileAtIndex:index];
        if (shuffle) {
            [ord appendPlaylistItem:currentPlaylistItem _error:NULL];
            orderPosition += 1;
        }
        return;
    }
    
	int ordCount;
	[ord count:&ordCount _error:nil];
    if (orderPosition < 0 || orderPosition > ordCount) {
        orderPosition = ordCount;
        NSLog(@"orderPostion inconsistency");
    }
    if (orderMarker < 0 || orderMarker > ordCount) {
        orderMarker = ordCount;
        NSLog(@"orderMarker inconsistency");
    }
    
    // take all songs in playlist. remove the songs in playbackOrder that are after playback marker.
    NSMutableArray *availableSongs;
	[ord playlistItems:&availableSongs 
			inPlaylist:currentPlaylist 
  notInPlaybackOrderAfterIndex:orderMarker 
				_error:nil];
  
	if (repeat == -1) {
		// if repeat song: repeat song
		[self playFileAtIndex:[self currentIndex]];
		
	} else if (shuffle && orderPosition < ordCount) {
		// if shuffle and inside history: play next song in history
		PRPlaylistItem playlistItem;
		int index;
		int playlist;
		
		orderPosition += 1;
		[ord playlistItem:&playlistItem atIndex:orderPosition _error:nil];
		[play index:&index andPlaylist:&playlist forPlaylistItem:playlistItem _error:nil];
		[self playFileAtIndex:index];
		
	} else if (shuffle && [availableSongs count] > 0) {
		// if shuffle, not in history and available songs: play random available song
		int index, playlist;
		int rand = random() % [availableSongs count];
		int playlistItem = [[availableSongs objectAtIndex:rand] intValue];
		[play index:&index andPlaylist:&playlist forPlaylistItem:playlistItem _error:nil];
		if ([self playFileAtIndex:index]) {
            [ord appendPlaylistItem:currentPlaylistItem _error:NULL];
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
		[ord playlistItems:&availableSongs 
				inPlaylist:currentPlaylist 
  notInPlaybackOrderAfterIndex:orderMarker 
					_error:nil];
        
        if ([availableSongs count] == 0) {
            orderMarker = ordCount;
            NSLog(@"ordMarker reset");
        }
        [self playNext];
        
	} else if (!shuffle && [self currentIndex] < currentPlaylistCount) { 
		// if shuffle is off and songs left in playlist: play next song
		[self clearHistory];
        if ([self playFileAtIndex:[self currentIndex] + 1]) {
            [ord appendPlaylistItem:currentPlaylistItem _error:nil];
            orderPosition += 1;
        }
		
	} else if (!shuffle && repeat == 1) {
		// if shuffle is off, no songs left in playlist and repeat is on: repeat playlist
		[self clearHistory];
		if ([self playFileAtIndex:1]) {
            [ord appendPlaylistItem:currentPlaylistItem _error:nil];
            orderPosition += 1;
        }
		
	} else if (!shuffle && repeat == 0) {
		// if shuffle is off, no songs left in playlist and repeat is off: stop
		[self stop];
	}
}

- (void)playPrevious
{
	if ([mov currentTime] > 3000.0) {
		[self playFileAtIndex:[self currentIndex]];
	} else if (repeat == -1) {
		// if repeat song: repeat song
		[self clearHistory];
		[self playFileAtIndex:[self currentIndex]];
		[ord appendPlaylistItem:currentPlaylistItem _error:nil];
		orderPosition += 1;
		
	} else if (!shuffle && [self currentIndex] > 1) {
		// if shuffle is off and previous songs: play previous song
		[self clearHistory];
		[self playFileAtIndex:[self currentIndex] - 1];
		[ord appendPlaylistItem:currentPlaylistItem _error:nil];
		orderPosition += 1;
		
	} else if (!shuffle && repeat == 0) {
		// if shuffle is off, repeat is off and no previous songs: stop
		[self stop];
		
	} else if (!shuffle && repeat == 1) {
		// if shuffle is off, repeat is on and no previous songs: play last song
		int count;
		
		[play count:&count forPlaylist:currentPlaylist _error:nil];
		[self clearHistory];
		[self playFileAtIndex:count];
		orderPosition += 1;
		
	} else if (shuffle && orderPosition > 1) {
		// if shuffle is on and songs left in playbackOrder: play song
		PRPlaylistItem playlistItem;
		int index;
		int playlist;
		
		orderPosition -= 1;
		[ord playlistItem:&playlistItem atIndex:orderPosition _error:nil];
		[play index:&index andPlaylist:&playlist forPlaylistItem:playlistItem _error:nil];
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
	[self setRepeat:!repeat];
}

- (void)toggleShuffle
{
	[self setShuffle:!shuffle];
}

- (void)clearHistory
{
	[ord clearPlaybackOrder_error:NULL];
	orderPosition = 0;
	orderMarker = 0;
}

- (void)postNotificationForCurrentPlaylist
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentPlaylist] 
                                                         forKey:@"playlist"];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistDidChangeNotification 
														object:self 
													  userInfo:userInfo];
}

// ========================================
// Update
// ========================================

- (void)movieDidFinish
{
	int playCount;
	[lib intValue:&playCount 
		  forFile:[self currentFile] 
		attribute:PRPlayCountFileAttribute 
		   _error:nil];
	[lib setIntValue:playCount + 1
			 forFile:[self currentFile]
		   attribute:PRPlayCountFileAttribute 
			  _error:nil];
	[lib setValue:[[NSDate date] description] 
		  forFile:[self currentFile] 
		attribute:PRLastPlayedFileAttribute 
		   _error:nil];
    [[db history] addFile:[self currentFile] withDate:[NSDate date]];
	[self playNext];
}

@end
