#import <Foundation/Foundation.h>
#import "Growl/Growl.h"

@class PRCore;

@interface PRGrowl : NSObject  <GrowlApplicationBridgeDelegate> 
{
    PRCore *core;
}


- (id)initWithCore:(PRCore *)core_;

- (void)currentFileDidChange:(NSNotification *)notification;

@end
