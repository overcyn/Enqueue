#import <Cocoa/Cocoa.h>
@class PRCore, PRDb;


@interface PRFolderMonitor : NSObject {
    __weak PRCore *_core;
    FSEventStreamRef stream;
}
/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Accessors */
@property (readonly) PRCore *core;
@property (readwrite, copy) NSArray *monitoredFolders;
- (void)removeFolder:(NSURL *)URL;
- (void)addFolder:(NSURL *)URL;

/* Action */
- (void)monitor;
- (void)monitor2;
- (void)rescan;
@end

void eventCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents,
                   void *eventPaths, const FSEventStreamEventFlags eventFlags[], 
                   const FSEventStreamEventId eventIds[]);
