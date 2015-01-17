#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRDb;
@class PRCore;
@class PRPlaylists;
@class PRMainWindowController;
@class PRGradientView;
@class PRRolloverTableView;
@class PRStringFormatter;

@interface PRPlaylistsViewController : NSViewController
- (id)initWithCore:(PRCore *)core;

- (void)duplicatePlaylist:(PRListID *)playlist;
- (void)newSmartPlaylist;
- (void)newStaticPlaylist;
@end
