#import "PRSizeFormatter.h"


@implementation PRSizeFormatter

- (NSString *)stringForObjectValue:(id)object 
{
    if (![object isKindOfClass:[NSNumber class]]) {
        return @"0 MB";
    }
	
	long long size = [object longLongValue];
	
	if (size > 1000000000) {
		return [NSString stringWithFormat:@"%.1f GB", size / 1000000000.0];
	} else if (size > 1000000) {
		return [NSString stringWithFormat:@"%.1f MB", size / 1000000.0];
	} else if (size > 1000) {
		return [NSString stringWithFormat:@"%.1f kB", size / 1000.0];
	} else {
		return [NSString stringWithFormat:@"%d bytes", size];
	}
}

- (BOOL)getObjectValue:(id *)obj 
			 forString:(NSString *)string
	  errorDescription:(NSString **)error 
{
    return NO;
}

@end
