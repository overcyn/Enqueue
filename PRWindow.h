#import <Foundation/Foundation.h>

@interface PRWindow : NSWindow
@end

@protocol PRWindowDelegate <NSObject>
@optional
- (BOOL)window:(NSWindow *)window keyDown:(NSEvent *)event;
@end
