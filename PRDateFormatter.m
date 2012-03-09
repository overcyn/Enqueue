#import "PRDateFormatter.h"


@implementation PRDateFormatter

// ========================================
// Initialization
// ========================================

- (id)init
{
    if (!(self = [super init])) {return nil;}
    _formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateStyle:NSDateFormatterShortStyle];
    [_formatter setDateFormat:@"M/d/yyyy H:mm a"];
    return self;
}

- (void)dealloc
{
    [_formatter release];
    [super dealloc];
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
    return [_formatter stringForObjectValue:date];
}

- (BOOL)getObjectValue:(id *)obj 
			 forString:(NSString *)string
	  errorDescription:(NSString **)error 
{
    return NO;
}

@end
