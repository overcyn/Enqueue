#import <Foundation/Foundation.h>

@interface NSURLConnection (Extensions)

+ (void)send:(NSURLRequest *)request onCompletion:(void (^)(NSURLResponse*, NSData*, NSError*))handler;
+ (void)_send:(NSURLRequest *)request onCompletion:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

@end
