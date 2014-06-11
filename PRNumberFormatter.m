#import "PRNumberFormatter.h"


@implementation PRNumberFormatter

- (NSString *)stringForObjectValue:(id)object {
    if ([object isKindOfClass:[NSNumber class]] && [object intValue] == 0) {
        return @"";
    } else {
        return [super stringForObjectValue:object];
    }
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr 
       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr 
              originalString:(NSString *)origString
       originalSelectedRange:(NSRange)origSelRange
            errorDescription:(NSString **)error {
    NSCharacterSet *decimalCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    BOOL nonNumericCharacter = FALSE;
    for (int i = 0; i < [*partialStringPtr length]; i++) {
        if (![decimalCharacterSet characterIsMember:[*partialStringPtr characterAtIndex:i]]) {
            nonNumericCharacter = TRUE;
            break;
        }
    }
    
    if (!nonNumericCharacter && [*partialStringPtr length] <= 4) {
        return TRUE;
    } else {
        *partialStringPtr = [NSString stringWithString:origString];
        *proposedSelRangePtr = origSelRange;
        return FALSE;
    }
}

@end