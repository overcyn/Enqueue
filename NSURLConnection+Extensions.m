#import "NSURLConnection+Extensions.h"

@implementation NSURLConnection (Extensions)

+ (void)send:(NSURLRequest *)request onCompletion:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    [[NSOperationQueue backgroundQueue] addBlock:^{
        [NSURLConnection _send:request onCompletion:handler];
    }];
}

+ (void)_send:(NSURLRequest *)request onCompletion:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [[NSOperationQueue mainQueue] addBlock:^{
        handler(response,data,error);
    }];
}

@end
