#import "PRStringFormatter.h"


@implementation PRStringFormatter

// ========================================
// Initialization
// ========================================

- (id)init
{
    if (!(self = [super init])) {return nil;}
    _maxLength = 255;
    return self;
}

@synthesize maxLength = _maxLength;

- (NSString *)stringForObjectValue:(id)object 
{
    if ([object isKindOfClass:[NSString class]]) {
        return (NSString *)object;
    }
    return [object description];
}

- (BOOL)getObjectValue:(id *)object 
             forString:(NSString *)string 
      errorDescription:(NSString **)error 
{
    *object = string;
    return TRUE;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr
       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
              originalString:(NSString *)origString
       originalSelectedRange:(NSRange)origSelRange
            errorDescription:(NSString **)error
{
    if ([*partialStringPtr length] > _maxLength) {
        return FALSE;
    }
    return TRUE;
}

@end