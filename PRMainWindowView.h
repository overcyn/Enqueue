#import <Cocoa/Cocoa.h>

@interface PRMainWindowView : NSView
@property (nonatomic, strong) NSViewController *leftViewController;
@property (nonatomic, strong) NSViewController *centerViewController;
@property (nonatomic, strong) NSView *bottomView;
@end
