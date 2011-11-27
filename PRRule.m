#import "PRRule.h"


@implementation PRRule

// initialization

- (id)init
{
	if (!(self = [super init])) {return nil;}
    _match = FALSE;
    _limit = FALSE;
    _isCompound = FALSE;
    _subRules = [[NSMutableArray alloc] init];
    _fileAttribute = 2;
    _selectedObjects = [[NSMutableArray alloc] init];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:_match forKey:@"match"];
	[coder encodeBool:_limit forKey:@"limit"];
    [coder encodeBool:_isCompound forKey:@"isCompound"];
	[coder encodeObject:_subRules forKey:@"subRules"]; 
	[coder encodeInt:_fileAttribute forKey:@"fileAttribute"];
	[coder encodeObject:_selectedObjects forKey:@"selectedObjects"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (!(self = [super init])) {return nil;}
    _match = [coder decodeBoolForKey:@"match"];
    _limit = [coder decodeBoolForKey:@"limit"];
    _isCompound = [coder decodeBoolForKey:@"isCompound"];
    _subRules = [coder decodeObjectForKey:@"subRules"];
    _fileAttribute = [coder decodeIntForKey:@"fileAttribute"];
    _selectedObjects = [coder decodeObjectForKey:@"selectedObjects"];
	return self;
}

// accessors

@synthesize match = _match;
@synthesize limit = _limit;
@synthesize isCompound = _isCompound;
@synthesize subRules = _subRules;
@synthesize fileAttribute = _fileAttribute;
@synthesize selectedObjects = _selectedObjects;

@end
