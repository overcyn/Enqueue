#import "PRTask.h"


@implementation PRTask

@synthesize title;
@synthesize value;
@synthesize shouldCancel;
@synthesize background;

// ========================================
// Initialization
// ========================================

- (id)init
{
    self = [super init];
    if (self) {
        shouldCancel = FALSE;
    }
    return self;
}

- (void)dealloc
{
    [title release];
    [super dealloc];
}

@end
