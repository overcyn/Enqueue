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

- (BOOL)create_error:(NSError **)error;
- (BOOL)initialize_error:(NSError **)error;
- (BOOL)validate_error:(NSError **)error;

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
