#import <Cocoa/Cocoa.h>
@class PRDb, PRItem;


@interface PRHistory : NSObject {   
    __weak PRDb *_db;
}
// Initialization
- (id)initWithDb:(PRDb *)db;
- (void)create;
- (BOOL)initialize;

// Accessors
- (void)addItem:(PRItem *)item withDate:(NSDate *)date;
- (void)clear;
- (NSArray *)topArtists;
- (NSArray *)topSongs;
- (NSArray *)recentlyAdded;
- (NSArray *)recentlyPlayed;

// Update
- (BOOL)confirmFileDelete_error:(NSError **)error;
@end
