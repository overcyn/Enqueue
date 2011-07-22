#import "PRFolderMonitor.h"
#include <CoreServices/CoreServices.h>
#import "PRDb.h"
#import "PRCore.h"
#import "PRImportOperation.h"
#import "PRUserDefaults.h"


@implementation PRFolderMonitor

@synthesize core;

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    if ((self = [super init])) {
        core = [core_ retain];
        db = [[core db] retain];
        stream = nil;
        [self monitor];
    }
    return self;
}

- (void)dealloc
{
    [db release];
    [core release];
    [super dealloc];
}

// ========================================
// Accessors
// ========================================

- (NSArray *)monitoredFolders
{
    return [[PRUserDefaults userDefaults] monitoredFolders];
}

- (void)setMonitoredFolders:(NSArray *)folders
{
    [[PRUserDefaults userDefaults] setMonitoredFolders:folders];
    [[PRUserDefaults userDefaults] setLastEventStreamEventId:0];
    [self monitor];
}

- (void)addFolder:(NSURL *)URL
{
    if ([[self monitoredFolders] containsObject:URL]) {
        return;
    }
    NSMutableArray *folders = [NSMutableArray arrayWithArray:[self monitoredFolders]];
    [folders addObject:URL];
    [self setMonitoredFolders:[NSArray arrayWithArray:folders]];
}

- (void)removeFolder:(NSURL *)URL
{
    if ([[self monitoredFolders] containsObject:URL]) {
        NSMutableArray *folders = [NSMutableArray arrayWithArray:[self monitoredFolders]];
        [folders removeObjectAtIndex:[folders indexOfObject:URL]];
        [self setMonitoredFolders:[NSArray arrayWithArray:folders]];        
    }
}

// ========================================
// Action
// ========================================

- (void)monitor
{
    // stop old event monitor
    if (stream) {
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        FSEventStreamRelease(stream);
        stream = nil;
    }
    
    // get new paths
    NSArray *folders = [self monitoredFolders];
    if ([folders count] == 0) {
        return;
    }
    NSMutableArray *mutablePaths = [NSMutableArray array];
    for (NSURL *i in folders) {
        [mutablePaths addObject:[i path]];
    }
    NSArray *paths = [NSArray arrayWithArray:mutablePaths];
    
    FSEventStreamEventId lastEventStreamEventId = [[PRUserDefaults userDefaults] lastEventStreamEventId];
    
    // if no previous monitor. scan entire directory
    if (lastEventStreamEventId == 0) {
        FSEventStreamEventId currentEventStreamEventId = FSEventsGetCurrentEventId();
        NSMethodSignature *methodSignature = [PRUserDefaults instanceMethodSignatureForSelector:@selector(setLastEventStreamEventId:)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation retainArguments];
        [invocation setTarget:[PRUserDefaults userDefaults]];
        [invocation setSelector:@selector(setLastEventStreamEventId:)];
        [invocation setArgument:&currentEventStreamEventId atIndex:2];
        methodSignature = [[self class] instanceMethodSignatureForSelector:@selector(monitor)];
        NSInvocation *invocation2 = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation retainArguments];
        [invocation2 setTarget:self];
        [invocation2 setSelector:@selector(monitor)];
        
        PRImportOperation *op = [[[PRImportOperation alloc] initWithURLs:folders recursive:TRUE core:core] autorelease];
        [op setBackground:FALSE];
        [op setCompletionInvocation:invocation];
        [op setCompletionInvocation2:invocation2];
        [[core opQueue] addOperation:op];
    } else {
        // create and schedule new monitor
        FSEventStreamContext context;
        context.info = self;
        context.version = 0;
        context.retain = NULL;
        context.release = NULL;
        context.copyDescription = NULL;
        stream = FSEventStreamCreate(NULL, &mycallback, &context, (CFArrayRef)paths, 
                                     lastEventStreamEventId, 20.0, kFSEventStreamCreateFlagNone);
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamStart(stream);
    }
}

@end

void mycallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents,
                void *eventPaths, const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    PRFolderMonitor *folderMonitor = (PRFolderMonitor *)clientCallBackInfo;
    char **paths = eventPaths;
    
    for (int i = 0; i < numEvents; i++) {
        /* flags are unsigned long, IDs are uint64_t */
        NSLog(@"Change %llu in %s, flags %lu\n", eventIds[i], paths[i], (unsigned long)eventFlags[i]);
        
        // kFSEventStreamEventFlagHistoryDone: denotes an old event
        if (eventFlags[i] & kFSEventStreamEventFlagHistoryDone) {
            continue;
        }
        
        NSString *path = [NSString stringWithCString:paths[i] encoding:NSUTF8StringEncoding];
        NSURL *URL = [NSURL fileURLWithPath:path];
        
        PRImportOperation *op = [[PRImportOperation alloc] initWithURLs:[NSArray arrayWithObject:URL] 
                                                              recursive:FALSE 
                                                                   core:[folderMonitor core]];
        [op setBackground:TRUE];
        [[[folderMonitor core] opQueue] addOperation:op];
        [op release];
    }
    
    FSEventStreamEventId lastEventId = eventIds[numEvents - 1];
    NSMethodSignature *methodSignature = [PRUserDefaults instanceMethodSignatureForSelector:@selector(setLastEventStreamEventId:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:[PRUserDefaults userDefaults]];
    [invocation setSelector:@selector(setLastEventStreamEventId:)];
    [invocation setArgument:&lastEventId atIndex:2];
    NSInvocationOperation *invocationOp = [[NSInvocationOperation alloc] initWithInvocation:invocation];
    [[[folderMonitor core] opQueue] addOperation:invocationOp];
    [invocationOp release];
}