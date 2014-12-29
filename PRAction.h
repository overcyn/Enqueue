#import <Foundation/Foundation.h>

@class PRCore;

typedef void (^WLTask)(PRCore *core);

@interface PRAction : NSOperation
@property (nonatomic, weak) PRCore *core;
@end

@interface PRClearNowPlayingAction : PRAction
@end

@interface PRAddNowPlayingAction : PRAction
@property (nonatomic, strong) NSArray *items;
@property (nonatomic) NSInteger index;
@end

@interface PRPlayNextAction : PRAction
@end

@interface PRPlayPreviousAction : PRAction
@end

@interface PRStopAction : PRAction
@end

@interface PRPlayItemAction : PRAction
@property (nonatomic) NSInteger index; // 0 based
@end

@interface PRRemoveItemsFromListAction : PRAction
@property (nonatomic, strong) NSIndexSet *indexes;
@property (nonatomic, strong) PRList *list;
@end

@interface PRHighlightItemsAction : PRAction
@property (nonatomic, strong) NSArray *items;
@end

@interface PRDuplicatePlaylistAction : PRAction
@property (nonatomic, strong) PRList *list;
@end

@interface PRPlayItemsAction : PRAction
@property (nonatomic, strong) NSArray *items;
@property (nonatomic) NSInteger index;
@end

@interface PRAddItemsToListAction : PRAction
@property (nonatomic, strong) NSArray *items;
@property (nonatomic) NSInteger index; // -1 to append, -2 to append next
@property (nonatomic, strong) PRList *list; // default now playing list
@end

@interface PRMoveIndexesInListAction : PRAction
@property (nonatomic, strong) NSIndexSet *indexes;
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) PRList *list;
@end

@interface PRSetListDescriptionAction : PRAction
@property (nonatomic, strong) PRListDescription *listDescription;
@property (nonatomic, strong) PRList *list;
@end

@interface PRRevealAction : PRAction
@property (nonatomic, strong) NSArray *items;
@end

@interface PRDeleteItemsAction : PRAction
@property (nonatomic, strong) NSArray *items;
@end

#pragma mark - Queue

@interface PRClearQueueAction : PRAction
@end

@interface PRRemoveFromQueueAction : PRAction
@property (nonatomic, strong) NSArray *listItems;
@end

@interface PRAddToQueueAction : PRAction
@property (nonatomic, strong) NSArray *listItems;
@end