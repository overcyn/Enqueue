#import <Foundation/Foundation.h>
@class PRConnection;
@class PRNowPlayingController;


@interface PREngine : NSObject
@property (nonatomic, readonly) PRNowPlayingController *now;
@property (nonatomic, readonly) PRConnection *conn;
+ (instancetype)engine;
+ (void)performAsync:(void (^)(PREngine *))block;
+ (void)performSync:(void (^)(PREngine *))block;
@end
