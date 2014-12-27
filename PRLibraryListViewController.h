#import "PRViewController.h"
@class PRLibraryDescription;

@interface PRLibraryListViewController : PRViewController
- (id)initWithCore:(PRCore *)core;
@property (nonatomic, strong) PRList *currentList;
@property (nonatomic, readonly) NSArray *selectedItems;
@property (nonatomic, readonly) NSArray *allItems;
@end
