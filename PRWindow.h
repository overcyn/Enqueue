#import <Cocoa/Cocoa.h>

@interface PRWindow : NSWindow
@end

@protocol PRWindowDelegate <NSObject>
@optional
- (BOOL)window:(NSWindow *)window keyDown:(NSEvent *)event;
@end
