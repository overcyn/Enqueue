#import "PRTask.h"


@implementation PRTask

// ========================================
// Initialization

- (id)init {
    if (!(self = [super init])) {return nil;}
    _shouldCancel = FALSE;
    _background = TRUE;
    return self;
}

+ (PRTask *)task {
    return [[[PRTask alloc] init] autorelease];
}

- (void)dealloc {
    [_title release];
    [super dealloc];
}

// ========================================
// Accessors

@synthesize title = _title, percent = _percent, shouldCancel = _shouldCancel, background = _background;

@end
