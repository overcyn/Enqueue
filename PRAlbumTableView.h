#import <Cocoa/Cocoa.h>
#import "PRTableView.h"


@interface PRAlbumTableView : PRTableView <NSTableViewDelegate, NSTableViewDataSource>
@end


//@protocol PRTableViewDelegate
//
//@optional
//- (BOOL)shouldDrawGridForRow:(int)row tableView:(NSTableView *)tableView;
//
//@required
//- (int)dbRowForTableRow:(int)tableRow;
//
//@end
