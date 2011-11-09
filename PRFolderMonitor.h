#import <Cocoa/Cocoa.h>


@class PRCore, PRDb;

@interface PRFolderMonitor : NSObject 
{
    PRDb *db;
    PRCore *core;
    FSEventStreamRef stream;
}

@property (readonly) PRCore *core;

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core;

// ========================================
// Accessors

// returns the array of monitored URLs
- (NSArray *)monitoredFolders;
- (void)setMonitoredFolders:(NSArray *)folders;
- (void)removeFolder:(NSURL *)URL;
- (void)addFolder:(NSURL *)URL;

// ========================================
// Action

- (void)monitor;
- (void)rescan;

@end

void eventCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents,
                   void *eventPaths, const FSEventStreamEventFlags eventFlags[], 
                   const FSEventStreamEventId eventIds[]);
