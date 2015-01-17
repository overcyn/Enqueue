#import "PRPlayer.h"
#import "NSNotificationCenter+Extensions.h"
#import "PRDefaults.h"
#import "PRHistory.h"
#import "PRLibrary.h"
#import "PRMovie.h"
#import "PRPlaybackOrder.h"
#import "PRPlaylists.h"
#import "PRQueue.h"
#import "PRTagger.h"
#import "PRPlayerState_Private.h"
#import "PRConnection.h"

@implementation PRPlayer {
    PRListItemID *_currentListItem;
    NSMutableArray *_invalidItems;
    int _position; // current position in playback history. usually count of playbackorder
    int _marker; // position in history AFTER which not to random from
    long _random; // next random number
    
    PRMovie *_movie;
    __weak PRConnection *_conn;
}

- (id)initWithConnection:(PRConnection *)conn {
    if (!(self = [super init])) {return nil;}
    _conn = conn;
    _movie = [[PRMovie alloc] init];
    
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

- (PRPlayerState *)playerState {
    PRPlayerState *description = [[PRPlayerState alloc] init];
    [description setInvalidItems:[self invalidItems]];
    [description setCurrentList:[self currentList]];
    [description setCurrentItem:[self currentItem]];
    [description setCurrentIndex:[self currentIndex]-1];
    [description setShuffle:[self shuffle]];
    [description setRepeat:[self repeat]];
    return description;
}

- (PRMovieState *)movieState {
    PRMovieState *description = [[PRMovieState alloc] init];
    [description setIsPlaying:[_movie isPlaying]];
    [description setVolume:[_movie volume]];
    [description setCurrentTime:[_movie currentTime]];
    [description setDuration:[_movie duration]];
    return description;
}

@synthesize invalidItems = _invalidItems;
@synthesize movie = _movie;

- (PRListID *)currentList {
    PRListID *rlt = nil;
    [[_conn playlists] zNowPlayingList:&rlt];
    return rlt;
}

- (PRListItemID *)currentListItem {
    return _currentListItem;
}

- (PRItemID *)currentItem {
    if ([self currentIndex] == 0) {
        return nil;
    } 
    PRItemID *item = nil;
    [[_conn playlists] zItemAtIndex:[self currentIndex] forList:[self currentList] out:&item];
    return item;
}

- (NSInteger)currentIndex {
    if (![self currentListItem]) {
        return 0;
    }
    NSInteger rlt = 0;
    [[_conn playlists] zIndexForListItem:[self currentListItem] out:&rlt];
    return rlt;
}

- (int)repeat {
    return [[PRDefaults sharedDefaults] boolForKey:PRDefaultsRepeat];
}

- (void)setRepeat:(int)repeat {
    [[PRDefaults sharedDefaults] setBool:repeat forKey:PRDefaultsRepeat];
    [self _postChangeSet];
}

- (BOOL)shuffle {
    return [[PRDefaults sharedDefaults] boolForKey:PRDefaultsShuffle];
}

- (void)setShuffle:(BOOL)shuffle {
    [[PRDefaults sharedDefaults] setBool:shuffle forKey:PRDefaultsShuffle];
    [self _postChangeSet];
}

- (void)toggleRepeat {
    [self setRepeat:![self repeat]];
}

- (void)toggleShuffle {
    [self setShuffle:![self shuffle]];
}

#pragma mark - Playback

- (void)stop {
    [_movie stop];
    _currentListItem = nil;
    [self clearHistory];
    [self _postChangeSet];
}

- (void)playPause {
    if ([self currentIndex] == 0) {
        PRListItemID *item = [self nextItem:YES];
        if (item) {
            [self playNext];
        }
    } else {
        [_movie pauseUnpause];
    }
}

- (void)playItemAtIndex:(NSInteger)index {
    [_invalidItems removeAllObjects];
    PRListItemID *item = nil;
    BOOL success = [[_conn playlists] zListItemAtIndex:index inList:[self currentList] out:&item];
    if (!success) {
        return;
    }
    [[_conn queue] zRemoveListItem:item];
    [self clearHistory];
    [[_conn playbackOrder] zAppendListItem:item];
    self.position += 1;
    [self playListItem:item evenIfQueued:YES];
}

- (void)playNext {
    PRListItemID *item = [self nextItem:YES];
    if (!item) {
        [self stop];
        return;
    }
    [self playListItem:item evenIfQueued:YES];
}

- (void)playPrevious {
    PRListItemID *item = [self previousItem:YES];
    if (!item) {
        [self stop];
        return;
    }
    [self playListItem:item evenIfQueued:YES];
}

#pragma mark - Playback Priv

- (void)playListItem:(PRListItemID *)listItem evenIfQueued:(BOOL)evenIfQueued {
    PRPlaylists *playlists = [_conn playlists];
    PRLibrary *library = [_conn library];
    
    if ([_invalidItems count] == [playlists countForList:[self currentList]]) {
        [self stop];
        return;
    }
    PRItemID *item = nil;
    [playlists zItemForListItem:listItem out:&item];
    _currentListItem = listItem;
    
    // update tags
    BOOL updated = [PRTagger updateTagsForItem:item database:_conn];
    if (updated) {
        [[NSNotificationCenter defaultCenter] postItemsChanged:@[item]];
    }
    
    NSString *path = nil;
    [library zValueForItem:item attr:PRItemAttrPath out:&path];
    bool err = evenIfQueued ? [_movie play:path] : [_movie playIfNotQueued:path];
    if (!err) {
        if (![_invalidItems containsObject:item]) {
            [_invalidItems addObject:item];
        }
        [self playNext];
        return;
    }
    [self _postChangeSet];
}

- (PRListItemID *)nextItem:(BOOL)update {
    PRQueue *queue = [_conn queue];
    PRPlaybackOrder *playbackOrder = [_conn playbackOrder];
    PRPlaylists *playlists = [_conn playlists];
    
    // if items in queue
    NSArray *queueArray = nil;
    [queue zQueueArray:&queueArray];
    if ([queueArray count] > 0) {
        PRListItemID *item = queueArray[0];
        if (update) {
            [queue zRemoveListItem:item];
            if (![self shuffle]) {
                [self clearHistory];
            }
            [playbackOrder zAppendListItem:item];
            [self setPosition:[self position] + 1];
        }
        return item;
    }
    
    // NOT SHUFFLE
    if (![self shuffle]) {
        NSInteger count = 0;
        [playlists zCountForList:[self currentList] out:&count];
        if ([self currentIndex] < count) {
            PRListItemID *item = nil;
            [playlists zListItemAtIndex:[self currentIndex] + 1 inList:[self currentList] out:&item];
            if (update) {
                [self clearHistory];
                [playbackOrder zAppendListItem:item];
                [self setPosition:[self position] + 1];
            }
            return item;
        } else {
            if ([self repeat]) {
                PRListItemID *item = nil;
                [playlists zListItemAtIndex:1 inList:[self currentList] out:&item];
                if (update) {
                    [self clearHistory];
                    [playbackOrder zAppendListItem:item];
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
    NSInteger count = 0;
    [playbackOrder zCount:&count];
    if ([self position] < count) {
        PRListItemID *item = nil;
        [playbackOrder zListItemAtIndex:[self position] + 1 out:&item];
        if (update) {
            [self setPosition:[self position] + 1];
        }
        return item;
    }
    
    // not inside history
    NSArray *availableSongs = [playbackOrder listItemsInList:[self currentList] notInPlaybackOrderAfterIndex:[self marker]];
    if ([self repeat]) {
        int newMarker = [self marker];
        while ([availableSongs count] == 0 && newMarker < [playbackOrder count]) {
            newMarker += floor([playlists countForList:[self currentList]] * 0.25) + 1;
            if (newMarker > [playbackOrder count]) {
                newMarker = [playbackOrder count];
            }
            availableSongs = [playbackOrder listItemsInList:[self currentList] notInPlaybackOrderAfterIndex:newMarker];
        }
        if (update) {
            [self setMarker:newMarker];
        }
    }
    if ([availableSongs count] > 0) {
        PRListItemID *item = [availableSongs objectAtIndex:_random % [availableSongs count]];
        if (update) {
            _random = random();
            [playbackOrder zAppendListItem:item];
            [self setPosition:[self position] + 1];
        }
        return item;
    } else {
        return 0;
    }
}

- (PRListItemID *)previousItem:(BOOL)update {
    PRQueue *queue = [_conn queue];
    PRPlaybackOrder *playbackOrder = [_conn playbackOrder];
    PRPlaylists *playlists = [_conn playlists];
    
    // if playing song jump to beginning
    if ([_movie currentTime] > 4000.0) {
        return [self currentListItem];
    }
    
    // NOT SHUFFLE
    if (![self shuffle]) {
        if ([self currentIndex] > 1) {
            PRListItemID *item = nil;
            [playlists zListItemAtIndex:[self currentIndex] - 1 inList:[self currentList] out:&item];
            if (update) {
                [self clearHistory];
                [playbackOrder zAppendListItem:item];
                [self setPosition:[self position] + 1];
                [queue zRemoveListItem:item];
            }
            return item;
        } else {
            if ([self repeat]) {
                NSInteger count = 0;
                [playlists zCountForList:[self currentList] out:&count];
                PRListItemID *item = nil;
                [playlists zListItemAtIndex:count inList:[self currentList] out:&item];
                if (update) {
                    [self clearHistory];
                    [playbackOrder zAppendListItem:item];
                    [self setPosition:[self position] + 1];
                    [queue zRemoveListItem:item];
                }
                return item;
            } else {
                return nil;
            }
        }
    }
    
    // SHUFFLE
    if ([self position] > 1) {
        PRListItemID *item = nil;
        [playbackOrder zListItemAtIndex:[self position] - 1 out:&item];
        if (update) {
            [self setPosition:[self position] - 1];
            [queue zRemoveListItem:item];
        }
        return item;
    } else {
        return nil;
    }
}

#pragma mark - Notifications

- (void)movieDidFinish {
    PRLibrary *library = [_conn library];
    PRHistory *history = [_conn history];
    
    NSNumber *playCount = nil;
    BOOL success = [library zValueForItem:[self currentItem] attr:PRItemAttrPlayCount out:&playCount];
    if (success) {
        [library zSetValue:@([playCount integerValue]+1) forItem:[self currentItem] attr:PRItemAttrPlayCount];
    }
    [library zSetValue:[[NSDate date] description] forItem:[self currentItem] attr:PRItemAttrLastPlayed];
    [history zAddItem:[self currentItem] withDate:[NSDate date]];
    
    // essentially playNext but if not queued
    PRListItemID *item = [self nextItem:YES];
    if (item) {
        [self playListItem:item evenIfQueued:NO];
    } else {
        [self stop];
    }
}

- (void)movieAlmostFinished {
    PRLibrary *library = [_conn library];
    PRPlaylists *playlists = [_conn playlists];
    PRListItemID *listItemID = [self nextItem:NO];
    if (listItemID) {
        PRItemID *itemID = nil;
        NSString *path = nil;
        [playlists zItemForListItem:listItemID out:&itemID];
        [library zValueForItem:itemID attr:PRItemAttrPath out:&path];
        [_movie queue:path];
    }
}

- (void)playlistDidChange:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"playlist"] isEqual:[self currentList]]) {
        NSInteger count = nil;
        [[_conn playbackOrder] zCount:&count];
        [_invalidItems removeAllObjects];
        [self setPosition:count];
        [self setMarker:count];
    }
}

#pragma mark - Order Priv

- (int)position {
    NSInteger count = nil;
    [[_conn playbackOrder] zCount:&count];
    if (_position < 0 || _position > count) {
        NSLog(@"invalid orderPosition");
        return count;
    }
    return _position;
}

- (void)setPosition:(int)position {
    _position = position;
}

- (int)marker {
    NSInteger count = nil;
    [[_conn playbackOrder] zCount:&count];
    if (_marker < 0 || _marker > count) {
        NSLog(@"invalid orderMarker");
        return count;
    }
    return _marker;
}

- (void)setMarker:(int)marker {
    _marker = marker;
}

- (void)clearHistory {
    [[_conn playbackOrder] clear];
    _position = 0;
    _marker = 0;
}

#pragma mark - Internal

- (void)_postChangeSet {
    [[NSNotificationCenter defaultCenter] postChanges:@[[[PRNowPlayingChange alloc] init]]];
}

@end
