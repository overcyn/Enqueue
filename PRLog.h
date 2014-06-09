#import <Foundation/Foundation.h>


extern NSString * const PRSQLiteErrorDomain;
extern NSString * const PREnqueueErrorDomain;


@interface PRLog : NSObject
/* Initialization */
+ (PRLog *)sharedLog;

/* Action */
- (void)presentError:(NSError *)error;
- (void)presentFatalError:(NSError *)error;
@end