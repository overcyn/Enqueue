#import <Foundation/Foundation.h>
#import "PRPlaylists.h"
@class PRDb;
@class PRConnection;


@interface PRQueue : NSObject
/* Initialization */
- (id)initWithDb:(PRDb *)db;
- (instancetype)initWithConnection:(PRConnection *)connection;
- (void)create;
- (BOOL)initialize;

/* Accessors */
- (BOOL)zQueueArray:(NSArray **)out;
- (BOOL)zRemoveListItem:(PRListItem *)listItem;
- (BOOL)zAppendListItem:(PRListItem *)listItem;
- (BOOL)zClear;

- (NSArray *)queueArray;
- (void)removeListItem:(PRListItem *)listItem;
- (void)appendListItem:(PRListItem *)listItem;
- (void)clear;
@end
