#import "PRTimeFormatter.h"

@implementation PRTimeFormatter

- (NSString *)stringForObjectValue:(id)object 
{
    if (![object isKindOfClass:[NSNumber class]]) {
        return @"0:00";
    }
	
	long long time = [object longLongValue] / 1000;
	if (time > 60 * 60 * 24) {
		return [NSString stringWithFormat:@"%i:%02i:%02i:%02i", (int)(time / (60 * 60 * 24)), (int)(time / (60 * 60) % 24), (int)(time / 60 % 60), (int)(time % 60)];
	} else if (time > 60 * 60) {
		return [NSString stringWithFormat:@"%i:%02i:%02i", (int)(time / (60 * 60)), (int)(time / 60 % 60), (int)(time % 60)];
	} else {
		return [NSString stringWithFormat:@"%i:%02i", (int)(time / 60), (int)(time % 60)];
	}
}

- (BOOL)getObjectValue:(id *)obj 
			 forString:(NSString *)string
	  errorDescription:(NSString **)error 
{
    return NO;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
								 withDefaultAttributes:(NSDictionary *)attributes
{
	return nil;
}

@end