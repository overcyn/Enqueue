#import <Foundation/Foundation.h>
#import "Growl/Growl.h"
@class PRCore, PRDb;


@interface PRGrowl : NSObject  <GrowlApplicationBridgeDelegate> {
    __weak PRCore *_core;
    __weak PRDb *_db;
}
- (id)initWithCore:(PRCore *)core;
@end
