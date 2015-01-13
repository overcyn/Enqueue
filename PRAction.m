#import "PRAction.h"
#import "NSNotificationCenter+Extensions.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRQueue.h"
#import "PRPlaylists.h"
#import "PRNowPlayingController.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRBrowserViewController.h"
#import "PRPlaylistsViewController.h"
#import "PRMoviePlayer.h"

#pragma mark - Now Playing

PRTask PRClearNowPlayingTask(void) {
    return ^(PRCore *core){
        int count = [[[core db] playlists] countForList:[[core now] currentList]];
        if (count == 1 || [[core now] currentIndex] == 0) {
            [[core now] stop];
            [[[core db] playlists] clearList:[[core now] currentList]];
        } else {
            [[[core db] playlists] clearList:[[core now] currentList] exceptIndex:[[core now] currentIndex]];
        }
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[[core now] currentList]];
    };
}

PRTask PRPlayPauseTask(void) {
    return ^(PRCore *core){
        [[core now] playPause];
    };
}

PRTask PRPlayNextTask(void) {
    return ^(PRCore *core){
        [[core now] playNext];
    };
}

PRTask PRPlayPreviousTask(void) {
    return ^(PRCore *core){
        [[core now] playPrevious];
    };
}

PRTask PRStopTask(void) {
    return ^(PRCore *core){
        [[core now] stop];
    };
}

PRTask PRPlayIndexTask(NSInteger index) {
    return ^(PRCore *core){
        [[core now] playItemAtIndex:index + 1];
    };
}

PRTask PRPlayItemsTask(NSArray *items, NSInteger index) {
    return ^(PRCore *core){
        PRNowPlayingController *now = [core now];
        PRPlaylists *playlists = [[core db] playlists];
        [now stop];
        [playlists clearList:[now currentList]];
        for (PRItemID *i in items) {
            [playlists zAppendItem:i toList:[now currentList]];
        }
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
        [now playItemAtIndex:index+1];
    };
}

PRTask PRSetVolumeTask(CGFloat volume) {
    return ^(PRCore *core){
        [[[core now] mov] setVolume:volume];
    };
}

PRTask PRSetTimeTask(NSInteger time) {
    return ^(PRCore *core){
        [[[core now] mov] setCurrentTime:time];
    };
}

PRTask PRToggleShuffleTask(void) {
    return ^(PRCore *core){
        [[core now] toggleShuffle];
    };
}

PRTask PRToggleRepeatTask(void) {
    return ^(PRCore *core){
        [[core now] toggleRepeat];
    };
}

#pragma mark - Lists

PRTask PRAddItemsToListTask(NSArray *items, NSInteger index, PRListID *list) {
    return ^(PRCore *core){
        PRListID *list2 = list ?: [[core now] currentList];
        PRPlaylists *playlists = [[core db] playlists];
        NSInteger index2 = index;
        if (index == -1) {
            NSInteger count;
            [playlists zCountForList:list2 out:&count];
            index2 = count + 1;
        } else if (index == -2) {
            // KD: TODO
            NSInteger count;
            [playlists zCountForList:list2 out:&count];
            index2 = count + 1;
        } else {
            index2 += 1;
        }
        
        [playlists zAddItems:items atIndex:index toList:list];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
    };
}

PRTask PRRemoveItemsFromListTask(NSIndexSet *indexes, PRListID *list) {
    return ^(PRCore *core){
        PRPlaylists *playlists = [[core db] playlists];
        NSMutableIndexSet *indexes2 = [NSMutableIndexSet indexSet];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
            [indexes2 addIndex:i+1];
        }];
        [playlists zRemoveItemsAtIndexes:indexes2 fromList:list];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
    };
}

PRTask PRMoveIndexesInListTask(NSIndexSet *indexes, NSInteger index, PRListID *list) {
    return ^(PRCore *core){
        PRPlaylists *playlists = [[core db] playlists];
        NSMutableIndexSet *indexes2 = [NSMutableIndexSet indexSet];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
            [indexes2 addIndex:i+1];
        }];
        [playlists zMoveItemsAtIndexes:indexes2 toIndex:index+1 inList:list];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
    };
}

PRTask PRSetListDescriptionTask(PRList *ld, PRListID *list) {
    return ^(PRCore *core){
        PRPlaylists *playlists = [[core db] playlists]; 
        [playlists zSetListDescription:ld forList:list];
        
        PRListChange *listChange = [[PRListChange alloc] init];
        [listChange setList:list];
        [[NSNotificationCenter defaultCenter] postChanges:@[listChange]];
    };
}

PRTask PRDuplicateListTask(PRListID *list) {
    return ^(PRCore *core){
        [[[core win] playlistsViewController] duplicatePlaylist:[list integerValue]]; // KD: WTF
    };
}

#pragma mark - Misc

PRTask PRHighightItemsTask(NSArray *items) {
    return ^(PRCore *core){
        PRMainWindowController *win = [core win];
        PRPlaylists *playlists = [[core db] playlists];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [win setCurrentMode:PRWindowModeLibrary];
            [[win libraryViewController] setCurrentList:[playlists libraryList]];
            [[[win libraryViewController] currentViewController] highlightItem:[items firstObject]];
        });
    };
}

PRTask PRRevealTask(NSArray *items) {
    return ^(PRCore *core){
        // KD: 
    };
}

#pragma mark - Library

PRTask PRDeleteItemsTask(NSArray *items) {
    return ^(PRCore *core){
        // KD: 
    };
}

#pragma mark - Queue

PRTask PRClearQueueTask(void) {
    return ^(PRCore *core){
        [[[core db] queue] clear];
    };
}

PRTask PRRemoveFromQueueTask(NSArray *listItems) {
    return ^(PRCore *core){
        for (PRListItemID *i in listItems) {
            [[[core db] queue] removeListItem:i];
        }
    };
}

PRTask PRAddToQueueTask(NSArray *listItems) {
    return ^(PRCore *core){
        for (PRListItemID *i in listItems) {
            [[[core db] queue] appendListItem:i];
        }
    };
}
