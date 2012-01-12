#import "PRRuleStringIs.h"

@implementation PRRuleStringIs

- (id)init
{
	if (!(self = [super init])) {return nil;}
    _values = [[NSMutableArray alloc] init];
    [_values addObject:@""];
    _fileAttribute = 0;
	return self;
}

- (void)dealloc
{
    [_values release];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (!(self = [super init])) {return nil;}
    _values = [[coder decodeObjectForKey:@"values"] retain];
    _fileAttribute = [coder decodeIntForKey:@"fileAttribute"];
    
    if (![_values isKindOfClass:[NSArray class]]) {
        goto reset;
    }
    for (id i in _values) {
        if (![i isKindOfClass:[NSString class]]) {
            goto reset;
        }
    }
    return self;
reset:
    [_values release];
    _values = [[NSMutableArray alloc] init];
    [_values addObject:@""];
    _fileAttribute = 0;
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:_values forKey:@"values"]; 
    [coder encodeInt:_fileAttribute forKey:@"fileAttribute"];
}

- (NSString *)whereStatement
{
    NSMutableString *stm = [NSMutableString stringWithFormat:@"%@ IN ("];
    for (NSString *i in _values) {
        [stm appendFormat:@"%@, ", i];
    }
    [stm deleteCharactersInRange:NSMakeRange([stm length] - 2, 2)];
    [stm appendString:@") COLLATE NOCASE "];
    return stm;
}

+ (NSString *)predicate
{
    return PRPredicateStringIs;
}

@end
