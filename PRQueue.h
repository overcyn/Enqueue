#import <Foundation/Foundation.h>
@class PRDb, PRListItem;


@interface PRQueue : NSObject {
    __weak PRDb *_db;
}
// Initialization
- (id)initWithDb:(PRDb *)db;
- (void)create;
- (BOOL)initialize;

// Accessors
- (NSArray *)queueArray;
- (void)removeListItem:(PRListItem *)listItem;
- (void)appendListItem:(PRListItem *)listItem;
- (void)clear;
@end