#import <Foundation/Foundation.h>
#import "PRPlaylists.h"

@class PRCore;

typedef void (^PRTask)(PRCore *core);

// Now Playing
PRTask PRClearNowPlayingTask(void);
PRTask PRPlayPauseTask(void);
PRTask PRPlayNextTask(void);
PRTask PRPlayPreviousTask(void);
PRTask PRStopTask(void);
PRTask PRPlayIndexTask(NSInteger index);
PRTask PRPlayItemsTask(NSArray *items, NSInteger index);
PRTask PRSetVolumeTask(CGFloat volume);
PRTask PRSetTimeTask(NSInteger time);
PRTask PRToggleShuffleTask(void);
PRTask PRToggleRepeatTask(void);

// Lists
PRTask PRAddItemsToListTask(NSArray *items, NSInteger index, PRList *list); // -1 to append, -2 to append next
PRTask PRRemoveItemsFromListTask(NSIndexSet *indexes, PRList *list);
PRTask PRMoveIndexesInListTask(NSIndexSet *indexes, NSInteger index, PRList *list);
PRTask PRSetListDescriptionTask(PRListDescription *ld, PRList *list);
PRTask PRDuplicateListTask(PRList *list);

// Misc
PRTask PRHighightItemsTask(NSArray *items);
PRTask PRRevealTask(NSArray *items);

// Library
PRTask PRDeleteItemsTask(NSArray *items);

// Queue
PRTask PRClearQueueTask(void);
PRTask PRRemoveFromQueueTask(NSArray *listItems);
PRTask PRAddToQueueTask(NSArray *listItems);
