#import "PREngine.h"
#import "PRNowPlayingController.h"
#import "PRConnection.h"
#import "PRDefaults.h"
#import "PRConnection.h"
#import "PRNowPlayingController.h"

@interface PREngine ()
@property (nonatomic, readonly) dispatch_queue_t queue;
@end


@implementation PREngine {
    PRNowPlayingController *_now;
    PRConnection *_conn;
    dispatch_queue_t _queue;
}

@synthesize now = _now;
@synthesize conn = _conn;
@synthesize queue = _queue;

+ (instancetype)engine {
    static PREngine *sEngine = nil;
    static dispatch_once_t sOnce = 0;
    dispatch_once(&sOnce, ^{
        sEngine = [[PREngine alloc] init];
    });
    return sEngine;
}

- (id)init {
    if ((self = [super init])) {
        _conn = [[PRConnection alloc] initWithPath:[[PRDefaults sharedDefaults] libraryPath] type:PRConnectionTypeReadWrite];
        _now = [[PRNowPlayingController alloc] initWithConnection:_conn];
        _queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (void)performAsync:(void (^)(PREngine *))block {
    PREngine *engine = [PREngine engine];
    dispatch_async([engine queue], ^{
        block(engine);
    });
}

+ (void)performSync:(void (^)(PREngine *))block {
    PREngine *engine = [PREngine engine];
    dispatch_sync([engine queue], ^{
        block(engine);
    });
}

@end
