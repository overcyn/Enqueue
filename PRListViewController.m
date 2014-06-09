#import "PRListViewController.h"
#import "PRTableViewController.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRCore.h"


@implementation PRListViewController

- (id)initWithCore:(PRCore *)core {
	if (!(self = [super initWithNibName:@"PRListView" bundle:nil])) {return nil;}
    _core = core;
    now = [core now];
    db = [core db];
    refreshing = FALSE;
    _updatingTableViewSelection = TRUE;
    _currentList = nil;
	return self;
}

@end