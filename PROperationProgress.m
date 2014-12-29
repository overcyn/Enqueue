#import "PROperationProgress.h"


@implementation PROperationProgress

#pragma mark - Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    _shouldCancel = NO;
    _background = YES;
    return self;
}

+ (PROperationProgress *)task {
    return [[PROperationProgress alloc] init];
}


#pragma mark - Accessors

@synthesize title = _title,
percent = _percent,
shouldCancel = _shouldCancel,
background = _background;

@end
