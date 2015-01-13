#import <Foundation/Foundation.h>

extern NSString * const PRSQLiteErrorDomain;
extern NSString * const PREnqueueErrorDomain;

@interface PRLog : NSObject
+ (PRLog *)sharedLog;
- (void)presentError:(NSError *)error;
- (void)presentFatalError:(NSError *)error;
@end