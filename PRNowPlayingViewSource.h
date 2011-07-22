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
- (void)initialize;
- (BOOL)validate;

// ========================================
// Update

- (BOOL)refreshWithPlaylist:(PRPlaylist)playlist 
					   sort:(PRFileAttribute)attribute 
				  ascending:(BOOL)asc 
					 _error:(NSError **)error;

// ========================================
// Accessors

- (BOOL)count:(int *)count _error:(NSError **)error;
- (BOOL)file:(PRFile *)file forRow:(int)row _error:(NSError **)error;

- (BOOL)arrayOfAlbumCounts:(NSArray **)array _error:(NSError **)error;

@end