#import "PRBitRateFormatter.h"


@implementation PRBitRateFormatter

- (NSString *)stringForObjectValue:(id)object {
    if (![object isKindOfClass:[NSNumber class]]) {
        return @"0 kbps";
    }
    return [NSString stringWithFormat:@"%d kbps", [object intValue]];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    return NO;
}

@end
