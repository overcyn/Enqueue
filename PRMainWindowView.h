#import <Cocoa/Cocoa.h>

@interface PRMainWindowView : NSView
@property (nonatomic, strong) NSView *sidebarView;
@property (nonatomic, strong) NSView *centerView;
@property (nonatomic, strong) NSView *bottomView;
@property (nonatomic) BOOL sidebarVisible;
@end
