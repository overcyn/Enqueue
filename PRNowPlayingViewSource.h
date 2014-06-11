#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"
#import "PRPlaylists.h"
@class PRDb;


@interface PRNowPlayingViewSource : NSObject {
    __weak PRDb *_db;
}
/* Initialization */
- (id)initWithDb:(PRDb *)db_;
- (void)create;
- (BOOL)initialize;

/* Update */
- (void)refresh;

/* Accessors */
- (int)count;
- (PRItem *)itemForRow:(int)row;
- (NSArray *)albumCounts;
@end
