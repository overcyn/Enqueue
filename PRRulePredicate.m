#import "PRRulePredicate.h"


@implementation PRRulePredicate

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

@synthesize fileAttribute = _fileAttribute;
@synthesize values = _values;

+ (NSString *)predicate
{
    return @"";
}

@end
