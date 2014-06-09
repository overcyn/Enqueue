#import "PRTitleBarGradientView.h"


@implementation PRTitleBarGradientView

- (void)drawRect:(NSRect)dirtyRect {
    [[NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:4.0 yRadius:4.0] addClip];
    [super drawRect:dirtyRect];
}

- (void)mouseUp:(NSEvent *)event {
    if ([event clickCount] == 2) {
        // Gets settings from "System Preferences" >  "Appearance" > "Double-click on windows title bar to minimize"
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults addSuiteNamed:NSGlobalDomain];
        if ([[userDefaults objectForKey:@"AppleMiniaturizeOnDoubleClick"] boolValue]) {
            [[self window] miniaturize:self];
        }
    }
}

@end