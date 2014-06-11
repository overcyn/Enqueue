#import "PRDateFormatter.h"


@implementation PRDateFormatter

- (id)init {
    if (!(self = [super init])) {return nil;}
    [self setDateStyle:NSDateFormatterShortStyle];
    [self setDateFormat:@"M/d/yyyy H:mm a"];
    return self;
}

- (NSString *)stringForObjectValue:(id)object {
    if (![object isKindOfClass:[NSString class]]) {
        return @"Invalid Date";
    }
    NSDate *date = [NSDate dateWithString:object];
    if (!date) {
        return @"Invalid Date";
    }
    return [super stringForObjectValue:date];
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    return NO;
}

@end
