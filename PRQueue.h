#import <Foundation/Foundation.h>
#import "PRPlaylists.h"

@class PRDb;


@interface PRQueue : NSObject 
{
    PRDb *db;
}

// ========================================
// Initialization
// ========================================

- (id)initWithDb:(PRDb *)db_;

- (BOOL)create_error:(NSError **)error;
- (BOOL)initialize_error:(NSError **)error;
- (BOOL)validate_error:(NSError **)error;

// ========================================
// Accessors
// ========================================

- (BOOL)queueArray:(NSArray **)array _error:(NSError **)error;
- (BOOL)removePlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error;
- (BOOL)appendPlaylistItem:(PRPlaylistItem)playlistItem _error:(NSError **)error;
- (BOOL)clearQueue;

@end