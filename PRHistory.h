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

- (void)addItem:(PRItemID *)item withDate:(NSDate *)date;
- (void)clear;
- (NSArray *)topArtists;
- (NSArray *)topSongs;
- (NSArray *)recentlyAdded;
- (NSArray *)recentlyPlayed;

// Update
- (BOOL)confirmFileDelete_error:(NSError **)error;
@end
