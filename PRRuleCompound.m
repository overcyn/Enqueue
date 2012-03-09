#import "PRRuleCompound.h"


@implementation PRRuleCompound

- (id)init
{
	if (!(self = [super init])) {return nil;}
    _subRules = [[NSMutableArray array] retain];
	return self;
}

- (void)dealloc
{
    [_subRules release];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:_subRules forKey:@"subRules"]; 
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (!(self = [super init])) {return nil;}
    _subRules = [coder decodeObjectForKey:@"subRules"];
	return self;
}

- (NSString *)whereStatement
{
    return @"";
}

@synthesize subRules = _subRules;

@end
