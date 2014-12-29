#import <Foundation/Foundation.h>
#import "PRAction.h"
@class PRCore;

@interface PRActionCenter : NSObject
+ (instancetype)defaultCenter;
@property (nonatomic, weak) PRCore *core;
+ (void)performTask:(PRTask)action;
+ (void)performTaskSync:(PRTask)action;
@end
