#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"


@class NSMutableArray;

@interface PRRule : NSObject <NSCoding>
{
	BOOL match;
	BOOL limit;
	
	BOOL isCompoundRule;
	NSMutableArray *subRules;
	
	PRFileAttribute fileAttribute;
	NSMutableArray *selectedObjects;
}

// accessors
- (BOOL)match; 
- (void)setMatch:(BOOL)newMatch;

- (BOOL)limit;
- (void)setLimit:(BOOL)newLimit;

- (BOOL)isCompoundRule;
- (void)setIsCompoundRule:(BOOL)newIsCompoundRule;

- (NSMutableArray *)subRules;
- (void)setSubRules:(NSMutableArray *)newSubRules;

- (PRFileAttribute)fileAttribute;
- (void)setFileAttribute:(PRFileAttribute)newFileAttribute;

- (NSMutableArray *)selectedObjects;
- (void)setSelectedObjects:(NSMutableArray *)newSelectedObjects;

@end
