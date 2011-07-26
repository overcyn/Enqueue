#import "PRRule.h"


@implementation PRRule

// initialization

- (id)init
{
    self = [super init];
	if (self) {
		limit = FALSE;
		match = FALSE;
		fileAttribute = 2;
		selectedObjects = [[NSMutableArray alloc] init];
		subRules = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeBool:limit forKey:@"limit"];	
	[coder encodeBool:match forKey:@"match"];	
	[coder encodeObject:subRules forKey:@"subRules"]; 
	[coder encodeBool:isCompoundRule forKey:@"isCompoundRule"];
	[coder encodeInt:fileAttribute forKey:@"fileAttribute"];
	[coder encodeObject:selectedObjects forKey:@"selectedObjects"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
	if (self) {
		limit = [coder decodeBoolForKey:@"limit"];
		match = [coder decodeBoolForKey:@"match"];
		subRules = [coder decodeObjectForKey:@"subRules"];
		isCompoundRule = [coder decodeBoolForKey:@"isCompoundRule"];
		fileAttribute = [coder decodeIntForKey:@"fileAttribute"];
		selectedObjects = [coder decodeObjectForKey:@"selectedObjects"];
	}
	return self;
}

// accessors

- (BOOL)match
{
	return match;
}

- (void)setMatch:(BOOL)newMatch
{
	match = newMatch;
}

- (BOOL)limit
{
	return limit;
}

- (void)setLimit:(BOOL)newLimit
{
	limit = newLimit;
}

- (BOOL)isCompoundRule
{
	return isCompoundRule;
}

- (void)setIsCompoundRule:(BOOL)newIsCompoundRule
{
	isCompoundRule = newIsCompoundRule;
}

- (NSMutableArray *)subRules
{
	return subRules;
}

- (void)setSubRules:(NSMutableArray *)newSubRules
{
	subRules = newSubRules;
}

- (PRFileAttribute)fileAttribute
{
	return fileAttribute;
}

- (void)setFileAttribute:(PRFileAttribute)newFileAttribute
{
	fileAttribute = newFileAttribute;
}

- (NSMutableArray *)selectedObjects
{
	return selectedObjects;
}

- (void)setSelectedObjects:(NSMutableArray *)newSelectedObjects
{
	selectedObjects = newSelectedObjects;
}

@end
