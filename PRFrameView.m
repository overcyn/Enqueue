#import "PRFrameView.h"
#import <objc/runtime.h>
#import "PRWindow.h"

@implementation PRFrameView

+ (void)swizzle
{
    Class grayFrameClass = NSClassFromString(@"NSGrayFrame");
    if (!grayFrameClass) return;
    
    // Exchange draw rect
    Method m0 = class_getInstanceMethod([self class], @selector(_mouseInGroup:));
    if (m0) {
        class_addMethod(grayFrameClass,
                        @selector(_mouseInGroup:),
                        method_getImplementation(m0),
                        method_getTypeEncoding(m0));
    }
//    m0 = class_getInstanceMethod([self class], @selector(updateTrackingAreas));
//    if (m0) {
//        class_addMethod(grayFrameClass,
//                        @selector(updateTrackingAreas),
//                        method_getImplementation(m0),
//                        method_getTypeEncoding(m0));
//    }
}

- (BOOL)_mouseInGroup:(id)sender
{
    return [(PRWindow *)[self window] mouseInGroup:sender];
}

//- (void)updateTrackingAreas {
//    [(PRWindow *)[self window] updateTrackingAreas];
//}

@end
