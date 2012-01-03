#import "PRListViewController.h"
#import "PRTableViewController.h"
#import "PRPlaylists.h"
#import "PRDb.h"


@implementation PRListViewController

- (id)       initWithDb:(PRDb *)db_ 
   nowPlayingController:(PRNowPlayingController *)now_
  libraryViewController:(PRLibraryViewController *)libraryViewController_
{
    
	if (!(self = [super initWithNibName:@"PRListView" bundle:nil])) {return nil;}
    now = now_;
    libraryViewController = libraryViewController_;
    db = db_;
    refreshing = FALSE;
    monitorSelection = TRUE;
    currentPlaylist = -1;
	return self;
}

@end