#import "NSString+Extensions.h"
#import "PRDb.h"

@implementation NSString (NSString_Extensions)

+ (NSString *)stringWithNumber:(NSNumber *)number
{
    return [NSString stringWithFormat:@"%@",number];
}

+ (NSString *)stringWithInt:(int)integer
{
    return [NSString stringWithFormat:@"%d",integer];
}

- (NSComparisonResult)noCaseCompare:(NSString *)string
{
    return no_case(nil, [self lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [self cStringUsingEncoding:NSUTF16StringEncoding], 
                   [string lengthOfBytesUsingEncoding:NSUTF16StringEncoding], [string cStringUsingEncoding:NSUTF16StringEncoding]);
}

@end
