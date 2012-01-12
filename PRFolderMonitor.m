#import "PRFolderMonitor.h"
#include <CoreServices/CoreServices.h>
#import "PRDb.h"
#import "PRCore.h"
#import "PRImportOperation.h"
#import "PRRescanOperation.h"
#import "PRUserDefaults.h"
#import "NSFileManager+Extensions.h"


@implementation PRFolderMonitor

@synthesize core;

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    if (!(self = [super init])) {return nil;}
    core = [core_ retain];
    db = [[core db] retain];
    stream = nil;
    [self monitor];
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
    if ([[self monitoredFolders] count] == 0) {
        return;
    }
    NSMutableArray *paths = [NSMutableArray array];
    for (NSURL *i in [self monitoredFolders]) {
        [paths addObject:[i path]];
    }
    // if no event id. add URLs and re-monitor
    if ([[PRUserDefaults userDefaults] lastEventStreamEventId] == 0) {
        PRRescanOperation *op = [PRRescanOperation operationWithURLs:[self monitoredFolders] core:core];
        [op setEventId:FSEventsGetCurrentEventId()];
        [op setMonitor:TRUE];
        [[core opQueue] addOperation:op];
        return;
    }
    // create and schedule new monitor
    FSEventStreamContext context;
    context.info = self;
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    stream = FSEventStreamCreate(NULL, &eventCallback, &context, (CFArrayRef)paths, 
                                 [[PRUserDefaults userDefaults] lastEventStreamEventId], 5.0, kFSEventStreamCreateFlagNone);
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
}

- (void)monitor2
{
    // stop old event monitor
    if (stream) {
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        FSEventStreamRelease(stream);
        stream = nil;
    }
    
    // get new paths
    if ([[self monitoredFolders] count] == 0) {
        return;
    }
    NSMutableArray *paths = [NSMutableArray array];
    for (NSURL *i in [self monitoredFolders]) {
        [paths addObject:[i path]];
    }
    // if no event id. add URLs and re-monitor
    if ([[PRUserDefaults userDefaults] lastEventStreamEventId] == 0) {
        [[PRUserDefaults userDefaults] setLastEventStreamEventId:FSEventsGetCurrentEventId()];
    }
    // create and schedule new monitor
    FSEventStreamContext context;
    context.info = self;
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    stream = FSEventStreamCreate(NULL, &eventCallback, &context, (CFArrayRef)paths, 
                                 [[PRUserDefaults userDefaults] lastEventStreamEventId], 5.0, kFSEventStreamCreateFlagNone);
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
}

- (void)rescan
{
    PRRescanOperation *op = [PRRescanOperation operationWithURLs:[self monitoredFolders] core:core];
    [op setEventId:FSEventsGetCurrentEventId()];
    [[core opQueue] addOperation:op];
}

@end

void eventCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents,
                   void *eventPaths, const FSEventStreamEventFlags eventFlags[],
                   const FSEventStreamEventId eventIds[])
{
    PRFolderMonitor *folderMonitor = (PRFolderMonitor *)clientCallBackInfo;
    PRCore *core = [folderMonitor core];
    NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
    char **paths = eventPaths;
    NSLog(@"-");
    NSMutableArray *URLs = [NSMutableArray array];
    for (int i = 0; i < numEvents; i++) {
        NSURL *URL = [NSURL fileURLWithPath:[NSString stringWithCString:paths[i] encoding:NSUTF8StringEncoding]];
        NSLog(@"Change %llu in %s, flags %lu\n", eventIds[i], paths[i], (unsigned long)eventFlags[i]);
        
        // if old event
        if ((eventFlags[i] & kFSEventStreamEventFlagHistoryDone) != 0) { 
            continue;
        }
        
        // if not in monitored folders
        BOOL valid = FALSE;
        for (NSURL *j in [folderMonitor monitoredFolders]) {
            if ([fm itemAtURL:j containsItemAtURL:URL] || [fm itemAtURL:j equalsItemAtURL:URL]) {
                valid = TRUE;
            }
        }
        if (!valid) {continue;}
        
        [URLs addObject:URL];
    }
    PRRescanOperation *op = [PRRescanOperation operationWithURLs:URLs core:core];
    [op setEventId:eventIds[numEvents - 1]];
    [[core opQueue] addOperation:op];
}
