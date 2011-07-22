#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"

@class PRDb;

@interface PRHistory : NSObject 
{    
    PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)sqlDb_;

- (void)create;
- (void)initialize;
- (BOOL)validate;

// ========================================
// Accessors

- (void)addFile:(PRFile)file withDate:(NSDate *)date;
- (void)clearHistory;

- (NSArray *)topArtists;
- (NSArray *)topSongs;
- (NSArray *)recentlyAdded;
- (NSArray *)recentlyPlayed;

// ========================================
// Update

- (BOOL)confirmFileDelete_error:(NSError **)error;

@end
