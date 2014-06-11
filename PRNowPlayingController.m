#import "PRNowPlayingController.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRHistory.h"
#import "PRLibrary.h"
#import "PRMoviePlayer.h"
#import "PRPlaybackOrder.h"
#import "PRPlaylists.h"
#import "PRQueue.h"
#import "PRTagger.h"


@implementation PRNowPlayingController {
    PRListItem *_currentListItem;
    NSMutableArray *_invalidItems;
    int _position; // current position in playback history. usually count of playbackorder
    int _marker; // position in history AFTER which not to random from
    
    long _random; // next random number
    
    PRMoviePlayer *_mov;

    __weak PRDb *_db;
}

#pragma mark - Initialization

- (id)initWithDb:(PRDb *)db {
    if (!(self = [super init])) {return nil;}
    _db = db;
    _mov = [[PRMoviePlayer alloc] init];
    
    _currentListItem = nil;
    [self clearHistory];
    
    _invalidItems = [[NSMutableArray alloc] init];
    
    srandomdev();
    _random = random();
    
    [[NSNotificationCenter defaultCenter] observeMovieFinished:self sel:@selector(movieDidFinish)];
    [[NSNotificationCenter defaultCenter] observePlaylistFilesChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observeMovieAlmostFinished:self sel:@selector(movieAlmostFinished)];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessors

@synthesize invalidItems = _invalidItems;
@synthesize mov = _mov;

- (PRList *)currentList {
    return [[_db playlists] nowPlayingList];
}

- (PRListItem *)currentListItem {
    return _currentListItem;
}

- (PRItem *)currentItem {
    if ([self currentIndex] == 0) {
        return nil;
    } 
    return [[_db playlists] itemAtIndex:[self currentIndex] forList:[self currentList]];
}

- (int)currentIndex {
    if (![self currentListItem]) {
        return 0;
    }
    return [[_db playlists] indexForListItem:[self currentListItem]];
}

- (int)repeat {
    return [[PRDefaults sharedDefaults] boolForKey:PRDefaultsRepeat];
}

- (void)setRepeat:(int)repeat {
    [[PRDefaults sharedDefaults] setBool:repeat forKey:PRDefaultsRepeat];
    [[NSNotificationCenter defaultCenter] postRepeatChanged];
}

- (BOOL)shuffle {
    return [[PRDefaults sharedDefaults] boolForKey:PRDefaultsShuffle];
}

- (void)setShuffle:(BOOL)shuffle {
    [[PRDefaults sharedDefaults] setBool:shuffle forKey:PRDefaultsShuffle];
    [[NSNotificationCenter defaultCenter] postShuffleChanged];
}

- (void)toggleRepeat {
    [self setRepeat:![self repeat]];
}

- (void)toggleShuffle {
    [self setShuffle:![self shuffle]];
}

#pragma mark - Playback

- (void)stop {
    [_mov stop];
    _currentListItem = nil;
    [[NSNotificationCenter defaultCenter] postPlayingFileChanged];
    [self clearHistory];
}

- (void)playPause {
    if ([self currentIndex] == 0) {
        PRListItem *item = [self nextItem:YES];
        if (item) {
            [self playNext];
        }
    } else {
        [_mov pauseUnpause];
    }
}

- (void)playItemAtIndex:(int)index {
    [_invalidItems removeAllObjects];
    PRListItem *item = [[_db playlists] listItemAtIndex:index inList:[self currentList]];
    [[_db queue] removeListItem:item];
    [self clearHistory];
    [[_db playbackOrder] appendListItem:item];
    self.position += 1;
    [self playListItem:item evenIfQueued:YES];
}

- (void)playNext {
    PRListItem *item = [self nextItem:YES];
    if (!item) {
        [self stop];
        return;
    }
    [self playListItem:item evenIfQueued:YES];
}

- (void)playPrevious {
    PRListItem *item = [self previousItem:YES];
    if (!item) {
        [self stop];
        return;
    }
    [self playListItem:item evenIfQueued:YES];
}

#pragma mark - Playback Priv

- (void)playListItem:(PRListItem *)listItem evenIfQueued:(BOOL)evenIfQueued {
    if ([_invalidItems count] == [[_db playlists] countForList:[self currentList]]) {
        [self stop];
        return;
    }
    PRItem *item = [[_db playlists] itemForListItem:listItem];
    _currentListItem = listItem;
    
    // update tags
    BOOL updated = [PRTagger updateTagsForItem:item database:_db];
    if (updated) {
        [[NSNotificationCenter defaultCenter] postItemsChanged:@[item]];
    }
    
    NSString *path = [[_db library] valueForItem:item attr:PRItemAttrPath];
    bool err = evenIfQueued ? [_mov play:path] : [_mov playIfNotQueued:path];
    if (!err) {
        if (![_invalidItems containsObject:item]) {
            [_invalidItems addObject:item];
        }
        [self playNext];
        return;
    }
    [[NSNotificationCenter defaultCenter] postPlayingFileChanged];
}

- (PRListItem *)nextItem:(BOOL)update {
    // if items in queue
    NSArray *queue = [[_db queue] queueArray];
    if ([queue count] > 0) {
        PRListItem *item = [queue objectAtIndex:0];
        if (update) {
            [[_db queue] removeListItem:[queue objectAtIndex:0]];
            if (![self shuffle]) {
                [self clearHistory];
            }
            [[_db playbackOrder] appendListItem:item];
            [self setPosition:[self position] + 1];
        }
        return item;
    }
    
    // NOT SHUFFLE
    if (![self shuffle]) {
        if ([self currentIndex] < [[_db playlists] countForList:[self currentList]]) {
            PRListItem *item = [[_db playlists] listItemAtIndex:[self currentIndex] + 1 inList:[self currentList]];
            if (update) {
                [self clearHistory];
                [[_db playbackOrder] appendListItem:item];
                [self setPosition:[self position] + 1];
            }
            return item;
        } else {
            if ([self repeat]) {
                PRListItem *item = [[_db playlists] listItemAtIndex:1 inList:[self currentList]];
                if (update) {
                    [self clearHistory];
                    [[_db playbackOrder] appendListItem:item];
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
    if ([self position] < [[_db playbackOrder] count]) {
        PRListItem *item = [[_db playbackOrder] listItemAtIndex:[self position] + 1];
        if (update) {
            [self setPosition:[self position] + 1];
        }
        return item;
    }
    
    // not inside history
    NSArray *availableSongs = [[_db playbackOrder] listItemsInList:[self currentList] notInPlaybackOrderAfterIndex:[self marker]];
    if ([self repeat]) {
        int newMarker = [self marker];
        while ([availableSongs count] == 0 && newMarker < [[_db playbackOrder] count]) {
            newMarker += floor([[_db playlists] countForList:[self currentList]] * 0.25) + 1;
            if (newMarker > [[_db playbackOrder] count]) {
                newMarker = [[_db playbackOrder] count];
            }
            availableSongs = [[_db playbackOrder] listItemsInList:[self currentList] notInPlaybackOrderAfterIndex:newMarker];
        }
        if (update) {
            [self setMarker:newMarker];
        }
    }
    if ([availableSongs count] > 0) {
        PRListItem *item = [availableSongs objectAtIndex:_random % [availableSongs count]];
        if (update) {
            _random = random();
            [[_db playbackOrder] appendListItem:item];
            [self setPosition:[self position] + 1];
        }
        return item;
    } else {
        return 0;
    }
}

- (PRListItem *)previousItem:(BOOL)update {
    // if playing song jump to beginning
    if ([_mov currentTime] > 4000.0) {
        return [self currentListItem];
    }
    
    // NOT SHUFFLE
    if (![self shuffle]) {
        if ([self currentIndex] > 1) {
            PRListItem *item = [[_db playlists] listItemAtIndex:[self currentIndex] - 1 inList:[self currentList]];
            if (update) {
                [self clearHistory];
                [[_db playbackOrder] appendListItem:item];
                [self setPosition:[self position] + 1];
                [[_db queue] removeListItem:item];
            }
            return item;
        } else {
            if ([self repeat]) {
                int count = [[_db playlists] countForList:[self currentList]];
                PRListItem *item = [[_db playlists] listItemAtIndex:count inList:[self currentList]];
                if (update) {
                    [self clearHistory];
                    [[_db playbackOrder] appendListItem:item];
                    [self setPosition:[self position] + 1];
                    [[_db queue] removeListItem:item];
                }
                return item;
            } else {
                return nil;
            }
        }
    }
    
    // SHUFFLE
    if ([self position] > 1) {
        PRListItem *item = [[_db playbackOrder] listItemAtIndex:[self position] - 1];
        if (update) {
            [self setPosition:[self position] - 1];
            [[_db queue] removeListItem:item];
        }
        return item;
    } else {
        return nil;
    }
}

#pragma mark - Notifications

- (void)movieDidFinish {
    int playCount = [[[_db library] valueForItem:[self currentItem] attr:PRItemAttrPlayCount] intValue];
    [[_db library] setValue:[NSNumber numberWithInt:playCount+1] forItem:[self currentItem] attr:PRItemAttrPlayCount];
    [[_db library] setValue:[[NSDate date] description] forItem:[self currentItem] attr:PRItemAttrLastPlayed];
    [[_db history] addItem:[self currentItem] withDate:[NSDate date]];
    
    // essentially playNext but if not queued
    PRListItem *item = [self nextItem:YES];
    if (item) {
        [self playListItem:item evenIfQueued:NO];
    } else {
        [self stop];
    }
}

- (void)movieAlmostFinished {
    PRListItem *item = [self nextItem:NO];
    if (item) {
        NSString *path = [[_db library] valueForItem:[[_db playlists] itemForListItem:item] attr:PRItemAttrPath];
        [_mov queue:path];
    }
}

- (void)playlistDidChange:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"playlist"] isEqual:[self currentList]]) {
        [_invalidItems removeAllObjects];
        [self setPosition:[[_db playbackOrder] count]];
        [self setMarker:[[_db playbackOrder] count]];
    }
}

#pragma mark - Order Priv

- (int)position {
    if (_position < 0 || _position > [[_db playbackOrder] count]) {
        NSLog(@"invalid orderPosition");
        return [[_db playbackOrder] count];
    }
    return _position;
}

- (void)setPosition:(int)position {
    _position = position;
}

- (int)marker {
    if (_marker < 0 || _marker > [[_db playbackOrder] count]) {
        NSLog(@"invalid orderMarker");
        return [[_db playbackOrder] count];
    }
    return _marker;
}

- (void)setMarker:(int)marker {
    _marker = marker;
}

- (void)clearHistory {
    [[_db playbackOrder] clear];
    _position = 0;
    _marker = 0;
}

@end
