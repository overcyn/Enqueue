#import "PRNowPlayingController.h"
#import "NSNotificationCenter+Extensions.h"
#import "PRDb.h"
#import "PRDefaults.h"
#import "PRHistory.h"
#import "PRLibrary.h"
#import "PRMoviePlayer.h"
#import "PRPlaybackOrder.h"
#import "PRPlaylists.h"
#import "PRQueue.h"
#import "PRTagger.h"
#import "PRPlayerDescription_Private.h"
#import "PRConnection.h"


@implementation PRNowPlayingController {
    PRListItem *_currentListItem;
    NSMutableArray *_invalidItems;
    int _position; // current position in playback history. usually count of playbackorder
    int _marker; // position in history AFTER which not to random from
    
    long _random; // next random number
    
    PRMoviePlayer *_mov;

    __weak PRDb *_db;
    __weak PRConnection *_conn;
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

- (id)initWithConnection:(PRConnection *)conn {
    if (!(self = [super init])) {return nil;}
    _conn = conn;
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

- (PRPlayerDescription *)description {
    PRPlayerDescription *description = [[PRPlayerDescription alloc] init];
    [description setInvalidItems:[self invalidItems]];
    [description setCurrentList:[self currentList]];
    [description setCurrentItem:[self currentItem]];
    [description setCurrentIndex:[self currentIndex]-1];
    [description setShuffle:[self shuffle]];
    [description setRepeat:[self repeat]];
    return description;
}

- (PRMovieDescription *)movDescription {
    PRMovieDescription *description = [[PRMovieDescription alloc] init];
    [description setIsPlaying:[_mov isPlaying]];
    [description setVolume:[_mov volume]];
    [description setCurrentTime:[_mov currentTime]];
    [description setDuration:[_mov duration]];
    return description;
}

@synthesize invalidItems = _invalidItems;
@synthesize mov = _mov;

- (PRList *)currentList {
    PRList *rlt = nil;
    [[(PRDb *)(_db?:(id)_conn) playlists] zNowPlayingList:&rlt];
    return rlt;
}

- (PRListItem *)currentListItem {
    return _currentListItem;
}

- (PRItem *)currentItem {
    if ([self currentIndex] == 0) {
        return nil;
    } 
    PRItem *item = nil;
    [[(PRDb *)(_db?:(id)_conn) playlists] zItemAtIndex:[self currentIndex] forList:[self currentList] out:&item];
    return item;
}

- (int)currentIndex {
    if (![self currentListItem]) {
        return 0;
    }
    NSInteger rlt = 0;
    [[(PRDb *)(_db?:(id)_conn) playlists] zIndexForListItem:[self currentListItem] out:&rlt];
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
    [_mov stop];
    _currentListItem = nil;
    [self clearHistory];
    [self _postChangeSet];
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
    PRListItem *item = nil;
    BOOL success = [[(PRDb *)(_db?:(id)_conn) playlists] zListItemAtIndex:index inList:[self currentList] out:&item];
    if (!success) {
        return;
    }
    [[(PRDb *)(_db?:(id)_conn) queue] zRemoveListItem:item];
    [self clearHistory];
    [[(PRDb *)(_db?:(id)_conn) playbackOrder] zAppendListItem:item];
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
    PRPlaylists *playlists = [(PRDb *)(_db?:(id)_conn) playlists];
    PRLibrary *library = [(PRDb *)(_db?:(id)_conn) library];
    
    if ([_invalidItems count] == [playlists countForList:[self currentList]]) {
        [self stop];
        return;
    }
    PRItem *item = [playlists itemForListItem:listItem];
    _currentListItem = listItem;
    
    // update tags
    BOOL updated = [PRTagger updateTagsForItem:item database:(PRDb *)(_db?:(id)_conn)];
    if (updated) {
        [[NSNotificationCenter defaultCenter] postItemsChanged:@[item]];
    }
    
    NSString *path = nil;
    [library zValueForItem:item attr:PRItemAttrPath out:&path];
    bool err = evenIfQueued ? [_mov play:path] : [_mov playIfNotQueued:path];
    if (!err) {
        if (![_invalidItems containsObject:item]) {
            [_invalidItems addObject:item];
        }
        [self playNext];
        return;
    }
    [self _postChangeSet];
}

- (PRListItem *)nextItem:(BOOL)update {
    PRQueue *queue = [(PRDb *)(_db?:(id)_conn) queue];
    PRPlaybackOrder *playbackOrder = [(PRDb *)(_db?:(id)_conn) playbackOrder];
    PRPlaylists *playlists = [(PRDb *)(_db?:(id)_conn) playlists];
    
    // if items in queue
    NSArray *queueArray = nil;
    [queue zQueueArray:&queueArray];
    if ([queueArray count] > 0) {
        PRListItem *item = queueArray[0];
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
            PRListItem *item = nil;
            [playlists zListItemAtIndex:[self currentIndex] + 1 inList:[self currentList] out:&item];
            if (update) {
                [self clearHistory];
                [playbackOrder zAppendListItem:item];
                [self setPosition:[self position] + 1];
            }
            return item;
        } else {
            if ([self repeat]) {
                PRListItem *item = nil;
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
        PRListItem *item = nil;
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
        PRListItem *item = [availableSongs objectAtIndex:_random % [availableSongs count]];
        if (update) {
            _random = random();
            [playbackOrder appendListItem:item];
            [self setPosition:[self position] + 1];
        }
        return item;
    } else {
        return 0;
    }
}

- (PRListItem *)previousItem:(BOOL)update {
    PRQueue *queue = [(PRDb *)(_db?:(id)_conn) queue];
    PRPlaybackOrder *playbackOrder = [(PRDb *)(_db?:(id)_conn) playbackOrder];
    PRPlaylists *playlists = [(PRDb *)(_db?:(id)_conn) playlists];
    
    // if playing song jump to beginning
    if ([_mov currentTime] > 4000.0) {
        return [self currentListItem];
    }
    
    // NOT SHUFFLE
    if (![self shuffle]) {
        if ([self currentIndex] > 1) {
            PRListItem *item = nil;
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
                PRListItem *item = nil;
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
        PRListItem *item = nil;
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
    PRLibrary *library = [(PRDb *)(_db?:(id)_conn) library];
    PRHistory *history = [(PRDb *)(_db?:(id)_conn) history];
    
    NSNumber *playCount = nil;
    BOOL success = [library zValueForItem:[self currentItem] attr:PRItemAttrPlayCount out:&playCount];
    if (success) {
        [library zSetValue:@([playCount integerValue]+1) forItem:[self currentItem] attr:PRItemAttrPlayCount];
    }
    [library zSetValue:[[NSDate date] description] forItem:[self currentItem] attr:PRItemAttrLastPlayed];
    [history zAddItem:[self currentItem] withDate:[NSDate date]];
    
    // essentially playNext but if not queued
    PRListItem *item = [self nextItem:YES];
    if (item) {
        [self playListItem:item evenIfQueued:NO];
    } else {
        [self stop];
    }
}

- (void)movieAlmostFinished {
    PRLibrary *library = [(PRDb *)(_db?:(id)_conn) library];
    PRPlaylists *playlists = [(PRDb *)(_db?:(id)_conn) playlists];
    PRListItem *item = [self nextItem:NO];
    if (item) {
        NSString *path = nil;
        [library zValueForItem:[playlists itemForListItem:item] attr:PRItemAttrPath out:&path];
        [_mov queue:path];
    }
}

- (void)playlistDidChange:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey:@"playlist"] isEqual:[self currentList]]) {
        NSInteger count = nil;
        [[(PRDb *)(_db?:(id)_conn) playbackOrder] zCount:&count];
        [_invalidItems removeAllObjects];
        [self setPosition:count];
        [self setMarker:count];
    }
}

#pragma mark - Order Priv

- (int)position {
    NSInteger count = nil;
    [[(PRDb *)(_db?:(id)_conn) playbackOrder] zCount:&count];
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
    [[(PRDb *)(_db?:(id)_conn) playbackOrder] zCount:&count];
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
    [[(PRDb *)(_db?:(id)_conn) playbackOrder] clear];
    _position = 0;
    _marker = 0;
}

#pragma mark - Internal

- (void)_postChangeSet {
    [[NSNotificationCenter defaultCenter] postChanges:@[[[PRNowPlayingChange alloc] init]]];
}

@end
