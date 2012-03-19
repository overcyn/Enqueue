#import "PRException.h"


NSString * const PRDbInconsistencyException = @"PRDbInconsistencyException";


@implementation PRException

- (void)raise {
    [self performSelectorInBackground:@selector(raise_) withObject:nil];
    while (TRUE) {
        sleep(1000);
    }
}

- (void)raise_ {
    [super raise];
}

+ (void)raise:(NSString *)name format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
    [[PRException exceptionWithName:name 
                             reason:reason 
                           userInfo:nil] raise];
    va_end(args);
}

@end
