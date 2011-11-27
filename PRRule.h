#import <Cocoa/Cocoa.h>
#import "PRLibrary.h"


@class NSMutableArray;

@interface PRRule : NSObject <NSCoding>
{
	BOOL _match;
	BOOL _limit;
	
	BOOL _isCompound;
	NSMutableArray *_subRules;
	
	PRFileAttribute _fileAttribute;
	NSMutableArray *_selectedObjects;
}

// accessors
@property (readwrite) BOOL match;
@property (readwrite) BOOL limit;

@property (readwrite) BOOL isCompound;
@property (readwrite, retain) NSMutableArray *subRules;

@property (readwrite) PRFileAttribute fileAttribute;
@property (readwrite,retain) NSMutableArray *selectedObjects;

@end
