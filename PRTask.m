#import "PRTask.h"


@implementation PRTask

// ========================================
// Initialization
// ========================================

- (id)init
{
    if (!(self = [super init])) {return nil;}
    shouldCancel = FALSE;
    background = TRUE;
    percent = 0;
    return self;
}

+ (PRTask *)task
{
    return [[[PRTask alloc] init] autorelease];
}

- (void)dealloc
{
    [title release];
    [super dealloc];
}

// ========================================
// Accessors
// ========================================

@synthesize title;
@synthesize percent;
@synthesize shouldCancel;
@synthesize background;

@end
