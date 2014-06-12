#import "PRAlbumTableView.h"


// Tableview that forwards the first responder to a different view.
@interface PRAlbumTableView2 : PRAlbumTableView
@property (readwrite, weak) NSResponder *actualResponder;
@end
