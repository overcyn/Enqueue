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
		now = [now_ retain];
		libraryViewController = libraryViewController_;
		db = [db_ retain];
		lib = [[db_ library] retain];
		play = [[db_ playlists] retain];
		libSrc = [[db_ libraryViewSource] retain];
		
		refreshing = TRUE;
		currentPlaylist = -1;
		
		columnInfoPlaylistAttribute = PRListViewColumnInfoPlaylistAttribute;
		sortColumnPlaylistAttribute = PRListViewSortColumnPlaylistAttribute;
		ascendingPlaylistAttribute = PRListViewAscendingPlaylistAttribute;		
	}
	return self;
}

@end