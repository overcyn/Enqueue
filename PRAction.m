#import "PRAction.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PRQueue.h"
#import "PRPlaylists.h"
#import "PRNowPlayingController.h"
#import "PRMainWindowController.h"
#import "PRLibraryViewController.h"
#import "PRBrowserViewController.h"
#import "PRPlaylistsViewController.h"


PRAction PRClearNowPlayingTask(void) {
    return ^(PRCore *core){
        int count = [[[core db] playlists] countForList:[[core now] currentList]];
        if (count == 1 || [[core now] currentIndex] == 0) {
            // if nothing playing or count == 1, clear playlist
            [[core now] stop];
            [[[core db] playlists] clearList:[[core now] currentList]];
        } else {
            // otherwise delete all previous songs
            [[[core db] playlists] clearList:[[core now] currentList] exceptIndex:[[core now] currentIndex]];
        }
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[[core now] currentList]];
    };
}

PRAction PRPlayNextTask(void) {
    return ^(PRCore *core){
        [[core now] playNext];
    };
}

PRAction PRPlayPreviousTask(void) {
    return ^(PRCore *core){
        [[core now] playPrevious];
    };
}

PRAction PRStopTask(void) {
    return ^(PRCore *core){
        [[core now] stop];
    };
}

PRAction PRPlayIndexTask(NSInteger index) {
    return ^(PRCore *core){
        [[core now] playItemAtIndex:index + 1];
    };
}

@implementation PRAction2 {
    __weak PRCore *_core;
}

@synthesize core = _core;

@end

@implementation PRHighlightItemsAction {
    NSArray *_items;
}

@synthesize items = _items;

- (void)main {
    PRMainWindowController *win = [[self core] win];
    PRPlaylists *playlists = [[[self core] db] playlists];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [win setCurrentMode:PRLibraryMode];
        [[win libraryViewController] setCurrentList:[playlists libraryList]];
        [[[win libraryViewController] currentViewController] highlightItem:[_items firstObject]];
    });
}

@end

@implementation PRDuplicatePlaylistAction {
    PRList *_list;
}

@synthesize list = _list;

- (void)main {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[[[self core] win] playlistsViewController] duplicatePlaylist:[_list integerValue]];
    });
}

@end

@implementation PRPlayItemsAction

- (void)main {
    dispatch_sync(dispatch_get_main_queue(), ^{
        PRNowPlayingController *now = [[self core] now];
        PRPlaylists *playlists = [[[self core] db] playlists];
        [now stop];
        [playlists clearList:[now currentList]];
        for (PRItem *i in [self items]) {
            [playlists zAppendItem:i toList:[now currentList]];
        }
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[now currentList]];
        [now playItemAtIndex:[self index]+1];
    });
}

@end

@implementation PRAddItemsToListAction

- (void)main {
    dispatch_sync(dispatch_get_main_queue(), ^{
        PRNowPlayingController *now = [[self core] now];
        PRList *list = [self list] ?: [now currentList];
        PRPlaylists *playlists = [[[self core] db] playlists];
        
        NSInteger index = [self index];
        if (index == -1) {
            NSInteger count;
            [playlists zCountForList:list out:&count];
            index = count + 1;
        } else if (index == -2) {
            // KD: TODO
            NSInteger count;
            [playlists zCountForList:list out:&count];
            index = count + 1;
        } else {
            index += 1;
        }
        
        [playlists zAddItems:[self items] atIndex:index toList:list];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:list];
    });
}

@end

@implementation PRMoveIndexesInListAction
- (void)main {
    dispatch_async(dispatch_get_main_queue(), ^{
        PRPlaylists *playlists = [[[self core] db] playlists];
        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        [[self indexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
            [indexes addIndex:i+1];
        }];
        [playlists zMoveItemsAtIndexes:indexes toIndex:[self index]+1 inList:[self list]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[self list]];
    });
}
@end

@implementation PRRemoveItemsFromListAction
- (void)main {
    dispatch_async(dispatch_get_main_queue(), ^{
        PRPlaylists *playlists = [[[self core] db] playlists];
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        [[self indexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
            [indexSet addIndex:i+1];
        }];
        [playlists zRemoveItemsAtIndexes:indexSet fromList:[self list]];
        [[NSNotificationCenter defaultCenter] postListItemsDidChange:[self list]];
    });
}
@end

@implementation PRSetListDescriptionAction

- (void)main {
    dispatch_sync(dispatch_get_main_queue(), ^{
        PRPlaylists *playlists = [[[self core] db] playlists]; 
        [playlists zSetListDescription:[self listDescription] forList:[self list]];
        
        PRListChange *listChange = [[PRListChange alloc] init];
        [listChange setList:[self list]];
        PRChangeSet *changeSet = [[PRChangeSet alloc] init];
        [changeSet setChanges:@[listChange]];
        [[NSNotificationCenter defaultCenter] postBackendChanged:changeSet];
    });
}

@end

@implementation PRRevealAction

- (void)main {
}

@end

@implementation PRDeleteItemsAction

- (void)main {
    // if ([indexes count] == 0) {
    //     return;
    // }
    // if (![_currentList isEqual:[[_db playlists] libraryList]]) {
    //     NSMutableIndexSet *indexesToDelete = [NSMutableIndexSet indexSet];
    //     NSTableColumn *tableColumn = [_tableView tableColumnWithIdentifier:PRListSortIndex];
    //     [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    //         [indexesToDelete addIndex:[[self tableView:_tableView objectValueForTableColumn:tableColumn row:idx] intValue]];
    //     }];
    //     [[_db playlists] removeItemsAtIndexes:indexesToDelete fromList:_currentList];
        
    //     [[NSNotificationCenter defaultCenter] postListItemsDidChange:_currentList];
    //     [_tableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    // } else {
    //     NSString *message = @"Do you want to remove the selected song from your library?";
    //     if ([indexes count] != 1) {
    //         message = [NSString stringWithFormat:@"Do you want to remove the %lu selected songs from your library?", (unsigned long)[indexes count]];
    //     }
    //     NSAlert *alert = [[NSAlert alloc] init];
    //     [alert addButtonWithTitle:@"Remove"];
    //     [alert addButtonWithTitle:@"Cancel"];
    //     [alert setMessageText:message];
    //     [alert setInformativeText:@"These files will not be deleted from your computer"];
    //     [alert setAlertStyle:NSWarningAlertStyle];
    //     [alert beginSheetModalForWindow:[[self view] window] 
    //                       modalDelegate:self 
    //                      didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:)
    //                         contextInfo:(__bridge_retained void *)indexes];
    // }
    
    // NSIndexSet *indexes = (__bridge_transfer NSIndexSet *)contextInfo;
    // if (returnCode != NSAlertFirstButtonReturn) {
    //     return;
    // }
    // NSMutableArray *items = [NSMutableArray array];
    // [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    //     [items addObject:[[_db libraryViewSource] itemForRow:[self dbRowForTableRow:idx]]];
    // }];
    // if ([items containsObject:[_now currentItem]]) {
    //     [_now stop];
    // }
    // [[_db library] removeItems:items];
    // [[NSNotificationCenter defaultCenter] postLibraryChanged];
    // [[NSNotificationCenter defaultCenter] postListItemsDidChange:[_now currentList]];
    // [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];    
}

@end

#pragma mark - Queue

@implementation PRClearQueueAction : PRAction2
- (void)main {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[[self core] db] queue] clear];
    });
}
@end

@implementation PRRemoveFromQueueAction : PRAction2
- (void)main {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (PRListItem *i in [self listItems]) {
            [[[[self core] db] queue] removeListItem:i];
        }
    });
}
@end

@implementation PRAddToQueueAction : PRAction2
- (void)main {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (PRListItem *i in [self listItems]) {
            [[[[self core] db] queue] appendListItem:i];
        }
    });
}
@end
