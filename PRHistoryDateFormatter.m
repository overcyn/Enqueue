#import "PRHistoryDateFormatter.h"


@implementation PRHistoryDateFormatter

- (id)init {
    if (!(self = [super init])) {return nil;}
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMM dd" options:0 locale:[NSLocale currentLocale]]];
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    if ([[_timeFormatter AMSymbol] isEqualToString:@"AM"]) {
        [_timeFormatter setAMSymbol:@"am"];
    }
    if ([[_timeFormatter PMSymbol] isEqualToString:@"PM"]) {
        [_timeFormatter setPMSymbol:@"pm"];
    }
    [_timeFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"h mm a" options:0 locale:[NSLocale currentLocale]]];
    return self;
}

- (NSString *)stringForObjectValue:(id)object {
    if (![object isKindOfClass:[NSDate class]]) {
        return [_dateFormatter stringForObjectValue:[NSDate date]];
    }
    if ([object timeIntervalSinceDate:[NSDate dateWithNaturalLanguageString:@"midnight today"]] > 0) {
        return [_timeFormatter stringForObjectValue:object];
    } else {
        return [_dateFormatter stringForObjectValue:object];
    }
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    return NO;
}

@end
