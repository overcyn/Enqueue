#import "PRListViewController.h"
#import "PRTableViewController.h"
#import "PRPlaylists.h"
#import "PRDb.h"


@implementation PRListViewController

- (id)       initWithDb:(PRDb *)db_ 
   nowPlayingController:(PRNowPlayingController *)now_
  libraryViewController:(PRLibraryViewController *)libraryViewController_
{
    self = [super initWithNibName:@"PRListView" bundle:nil];
	if (self) {
		now = now_;
		libraryViewController = libraryViewController_;
		db = db_;
		refreshing = FALSE;
        monitorSelection = TRUE;
		currentPlaylist = -1;
	}
	return self;
}

@end