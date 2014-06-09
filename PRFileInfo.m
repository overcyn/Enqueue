#import "PRFileInfo.h"

@implementation PRFileInfo

@synthesize attributes = _attributes;
@synthesize art = _art;
@synthesize tempArt = _tempArt;
@synthesize trackid = _trackid;
@synthesize item = _item;

- (id)init {
    if (!(self = [super init])) {return nil;}
    _attributes = nil;
    _art = nil;
    _tempArt = 0;
    _trackid = 0;
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"attributes:%@ art:%@ tempArt:%d file:%llu",_attributes, _art, _tempArt, [_item unsignedLongLongValue]];
}

+ (PRFileInfo *)fileInfo {
    return [[PRFileInfo alloc] init];
}

@end
