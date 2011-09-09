#import <Foundation/Foundation.h>

@interface NSString (NSString_Extensions)

+ (NSString *)stringWithNumber:(NSNumber *)number;
+ (NSString *)stringWithInt:(int)integer;
- (NSComparisonResult)noCaseCompare:(NSString *)string;

@end
