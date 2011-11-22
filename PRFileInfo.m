#import "PRFileInfo.h"

@implementation PRFileInfo

@synthesize attributes = _attributes;
@synthesize art = _art;
@synthesize tempArt = _tempArt;
@synthesize file = _file;

- (id)init 
{
    if (!(self = [super init])) {return nil;}
    _attributes = nil;
    _art = nil;
    _tempArt = 0;
    _file = 0;
    return self;
}

+ (PRFileInfo *)fileInfo
{
    return [[[PRFileInfo alloc] init] autorelease];
}

@end
