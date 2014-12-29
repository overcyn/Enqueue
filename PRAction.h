#import <Foundation/Foundation.h>

@class PRCore;

typedef void (^PRAction)(PRCore *core);

// Now Playing
PRAction PRClearNowPlayingTask(void);
PRAction PRPlayNextTask(void);
PRAction PRPlayPreviousTask(void);
PRAction PRStopTask(void);
PRAction PRPlayIndexTask(NSInteger index);

PRAction PRPlayItemsTask(NSArray *items, NSInteger index);

// Lists
PRAction PRAddItemsToListTask(NSArray *items, NSInteger index, PRList *list);
PRAction PRRemoveItemsFromListTask(NSIndexSet *indexes, PRList *list);
PRAction PRMoveIndexesInListTask(NSIndexSet *indexes, NSInteger, index, PRList *list);
PRAction PRSetListDescriptionTask(PRListDescription *ld, PRList *list);
PRAction PRDuplicateListTask(PRList *list);

// Misc
PRAction PRHighightItemsTask(NSArray *items);
PRAction PRRevealTask(NSArray *items);

// Library
PRAction PRDeleteItemsTask(NSArray *items);

// Queue
PRAction PRClearQueueTask();
PRAction PRRemoveFromQueueTask(NSArray *listItems);
PRAction PRAddToQueueTask(NSArray *listItems);



@interface PRAction2 : NSOperation
@property (nonatomic, weak) PRCore *core;
@end    

@interface PRRemoveItemsFromListAction : PRAction2
@property (nonatomic, strong) NSIndexSet *indexes;
@property (nonatomic, strong) PRList *list;
@end

@interface PRHighlightItemsAction : PRAction2
@property (nonatomic, strong) NSArray *items;
@end

@interface PRDuplicatePlaylistAction : PRAction2
@property (nonatomic, strong) PRList *list;
@end

@interface PRPlayItemsAction : PRAction2
@property (nonatomic, strong) NSArray *items;
@property (nonatomic) NSInteger index;
@end

@interface PRAddItemsToListAction : PRAction2
@property (nonatomic, strong) NSArray *items;
@property (nonatomic) NSInteger index; // -1 to append, -2 to append next
@property (nonatomic, strong) PRList *list; // default now playing list
@end

@interface PRMoveIndexesInListAction : PRAction2
@property (nonatomic, strong) NSIndexSet *indexes;
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) PRList *list;
@end

@interface PRSetListDescriptionAction : PRAction2
@property (nonatomic, strong) PRListDescription *listDescription;
@property (nonatomic, strong) PRList *list;
@end

@interface PRRevealAction : PRAction2
@property (nonatomic, strong) NSArray *items;
@end

@interface PRDeleteItemsAction : PRAction2
@property (nonatomic, strong) NSArray *items;
@end

#pragma mark - Queue

@interface PRClearQueueAction : PRAction2
@end

@interface PRRemoveFromQueueAction : PRAction2
@property (nonatomic, strong) NSArray *listItems;
@end

@interface PRAddToQueueAction : PRAction2
@property (nonatomic, strong) NSArray *listItems;
@end
