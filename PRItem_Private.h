#import "PRItem.h"
#import "PRPlaylists.h"

@interface PRItem (Private)
- (id)initWithItemID:(PRItemID *)item connection:(PRConnection *)conn;
- (BOOL)writeToConnection:(PRConnection *)conn;
@end
