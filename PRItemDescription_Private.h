#import "PRItemDescription.h"

@interface PRItemDescription (Private)
- (id)initWithItem:(PRItem *)item connection:(PRConnection *)conn;
- (BOOL)writeToConnection:(PRConnection *)conn;
@end
