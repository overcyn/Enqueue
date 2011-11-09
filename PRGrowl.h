#import <Foundation/Foundation.h>
#import "Growl/Growl.h"

@class PRCore;

@interface PRGrowl : NSObject  <GrowlApplicationBridgeDelegate> 
{
    PRCore *core;
}


- (id)initWithCore:(PRCore *)core_;
//- (void)playingChanged:(NSNotification *)notification;
- (void)currentFileDidChange:(NSNotification *)notification;

@end
