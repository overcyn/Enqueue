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
- (BOOL)zRemoveListItem:(PRListItemID *)listItem;
- (BOOL)zAppendListItem:(PRListItemID *)listItem;
- (BOOL)zClear;
@end
