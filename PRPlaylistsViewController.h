#import <Cocoa/Cocoa.h>
#import "PRPlaylists.h"
@class PRBridge;

@interface PRPlaylistsViewController : NSViewController
- (id)initWithBridge:(PRBridge *)bridge;
- (void)duplicatePlaylist:(PRListID *)playlist;
- (void)newSmartPlaylist;
- (void)newStaticPlaylist;
@end
