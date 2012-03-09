#import "PRTimeFormatter2.h"


@implementation PRTimeFormatter2

- (NSString *)stringForObjectValue:(id)object {
    if (![object isKindOfClass:[NSNumber class]]) {
        return @"0:00";
    }
    
    long long time = [object longLongValue] / 1000;
	if (time > 60 * 60 * 24) {
		return [NSString stringWithFormat:@"%0.1f days", time / (60. * 60 * 24)];
	} else if (time > 60 * 60) {
		return [NSString stringWithFormat:@"%0.1f hours", time / (60. * 60)];
	} else {
		return [NSString stringWithFormat:@"%d minutes", time / 60];
	}
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    return FALSE;
}

@end
