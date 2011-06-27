#import "PRDateFormatter.h"


@implementation PRDateFormatter

- (id)init
{
    if ((self = [super init])) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setDateFormat:@"M/d/yyyy H:mm a"];
    }
    return self;
}

- (NSString *)stringForObjectValue:(id)object 
{
    if (![object isKindOfClass:[NSString class]]) {
        return @"Invalid Date";
    }
    NSDate *date = [NSDate dateWithString:object];
    if (!date) {
        return @"Invalid Date";
    }
    return [formatter stringForObjectValue:date];
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
