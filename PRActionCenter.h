#import <Foundation/Foundation.h>

@class PRAction;
@class PRCore;


@interface PRActionCenter : NSObject
+ (instancetype)defaultCenter;
@property (nonatomic, weak) PRCore *core;

+ (void)performAction:(PRAction *)action;
- (void)performAction:(PRAction *)action;
@end
