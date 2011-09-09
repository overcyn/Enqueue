#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRPlaylists.h"

@class PRDb;

@interface PRNowPlayingViewSource : NSObject 
{
	PRDb *db;
}

// ========================================
// Initialization

- (id)initWithDb:(PRDb *)db_;

- (void)create;
- (BOOL)initialize;

// ========================================
// Update

- (BOOL)refreshWithPlaylist:(PRPlaylist)playlist;

// ========================================
// Accessors

- (int)count;
- (PRFile)fileForRow:(int)row;
- (NSArray *)albumCounts;

@end