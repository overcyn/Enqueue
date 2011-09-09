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

- (void)create;
- (BOOL)initialize;

// ========================================
// Accessors
// ========================================

- (NSArray *)queueArray;
- (void)removePlaylistItem:(PRPlaylistItem)playlistItem;
- (void)appendPlaylistItem:(PRPlaylistItem)playlistItem;
- (void)clear;

@end