#import <Foundation/Foundation.h>

@class PRCore;

@interface PRAction : NSOperation
@property (nonatomic, weak) PRCore *core;
@end

@interface PRClearNowPlayingAction : PRAction
@end

@interface PRAddNowPlayingAction : PRAction
@property (nonatomic, strong) NSArray *items;
@property (nonatomic) NSInteger index;
@end

@interface PRBlockAction : PRAction
+ (instancetype)blockActionWithBlock:(void (^)(PRCore *))block;
@property (nonatomic, copy) void (^block)(PRCore *);
@end

@interface PRPlayNextAction : PRAction
@end

@interface PRPlayPreviousAction : PRAction
@end

@interface PRStopAction : PRAction
@end

@interface PRPlayItemAtIndexAction : PRAction
@property (nonatomic) NSInteger index;
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
