#import "PRListViewController.h"
#import "PRTableViewController.h"
#import "PRPlaylists.h"
#import "PRDb.h"
#import "PRCore.h"


@implementation PRListViewController

- (id)initWithCore:(PRCore *)core {
    if (!(self = [super initWithCore:core])) {return nil;}
    _core = core;
    _now = [core now];
    _db = [core db];
    _refreshing = NO;
    _updatingTableViewSelection = YES;
    _currentList = nil;
    return self;
}

- (void)loadView {
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    [scrollView setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setAutohidesScrollers:YES];
    _detailView = scrollView;
    
    _detailTableView = [[PRTableView alloc] initWithFrame:[scrollView bounds]];
    [_detailTableView setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
    [_detailTableView setUsesAlternatingRowBackgroundColors:YES];
    [_detailTableView setFocusRingType:NSFocusRingTypeNone];
    [_detailTableView setTarget:self];
    [_detailTableView setDoubleAction:@selector(play)];
    [_detailTableView registerForDraggedTypes:@[PRFilePboardType]];
    [_detailTableView setVerticalMotionCanBeginDrag:NO];
    [_detailTableView setAllowsMultipleSelection:YES];
    [_detailTableView setDataSource:self];
    [_detailTableView setDelegate:self];
    [scrollView setDocumentView:_detailTableView];
    
    [super loadView];
}

@end