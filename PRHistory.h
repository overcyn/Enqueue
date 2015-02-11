#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRDb;

@interface PRHistory : NSObject
// Initialization
- (id)initWithDb:(PRDb *)db;
- (instancetype)initWithConnection:(PRConnection *)connection;
- (void)create;
- (BOOL)initialize;

// Accessors
- (BOOL)zAddItem:(PRItemID *)item withDate:(NSDate *)date;
- (BOOL)zClear;
- (BOOL)zTopArtists:(NSArray **)out;
- (BOOL)zTopSongs:(NSArray **)out;
- (BOOL)zRecentlyAdded:(NSArray **)out;
- (BOOL)zRecentlyPlayed:(NSArray **)out;

// Update
- (BOOL)confirmFileDelete_error:(NSError **)error;
@end
