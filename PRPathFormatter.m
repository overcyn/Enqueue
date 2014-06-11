#import "PRPathFormatter.h"


@implementation PRPathFormatter

- (NSString *)stringForObjectValue:(id)object {
    return [[NSURL URLWithString:object] path];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    return NO;
}

@end
