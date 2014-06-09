#import <Cocoa/Cocoa.h>


@interface PRTableView : NSTableView
@end


@protocol PRTableViewDelegate <NSObject>
@optional
- (BOOL)tableView:(PRTableView *)tableView keyDown:(NSEvent *)event;
@end
