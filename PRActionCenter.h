#import <Foundation/Foundation.h>
#import "PRAction.h"
@class PRAction2;
@class PRCore;


@interface PRActionCenter : NSObject
+ (instancetype)defaultCenter;
@property (nonatomic, weak) PRCore *core;

+ (void)performAction:(PRAction2 *)action;
- (void)performAction:(PRAction2 *)action;

+ (void)performTask:(PRAction)action;
@end
