#import "PRTitleBarGradientView.h"


@implementation PRTitleBarGradientView

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect frame = [self frame];
    float cornerRadius = 4;
    [[NSBezierPath bezierPathWithRoundedRect:frame xRadius:cornerRadius yRadius:cornerRadius] addClip];
    [super drawRect:dirtyRect];
}

//- (void)mouseUp:(NSEvent *)event
//{    
//    if ([event clickCount] == 2) {
//        // Gets settings from "System Preferences" >  "Appearance" > "Double-click on windows title bar to minimize"
//        NSString * const MDAppleMiniaturizeOnDoubleClickKey = @"AppleMiniaturizeOnDoubleClick";
//        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//        [userDefaults addSuiteNamed:NSGlobalDomain];
//        BOOL shouldMiniaturize = [[userDefaults objectForKey:MDAppleMiniaturizeOnDoubleClickKey] boolValue];
//        if (shouldMiniaturize) {
//            [[self window] miniaturize:self];
//        }
//    }
//}

@end