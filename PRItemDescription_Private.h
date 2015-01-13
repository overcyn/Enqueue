#import "PRItemDescription.h"
#import "PRPlaylists.h"

@interface PRItemDescription (Private)
- (id)initWithItem:(PRItemID *)item connection:(PRConnection *)conn;
- (BOOL)writeToConnection:(PRConnection *)conn;
@end
