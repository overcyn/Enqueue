#import <Cocoa/Cocoa.h>


@class PRCore, PRTask, PRDb;

@interface PRImportOperation : NSOperation 
{
	NSArray *_URLs;
    NSArray *_removeIfInFolder;
    
    BOOL _removeMissing;
    BOOL background;
    BOOL playWhenDone;
    NSMutableArray *URLsToPlay;
    PRTask *task;
    int _tempFileCount;
    
    NSInvocation *completionInvocation;
    NSInvocation *completionInvocation2;
    
    PRCore *_core;
    PRDb *_db;
}

// ========================================
// Initialization

+ (id)operationWithURLs:(NSArray *)URLs core:(PRCore *)core;
- (id)initWithURLs:(NSArray *)URLs core:(PRCore *)core;

// ========================================
// Accessors

@property (readwrite) BOOL background;
@property (readwrite) BOOL playWhenDone;

@property (readwrite) BOOL removeMissing;

// invoked on main thread if successful completion without cancellation
@property (readwrite, retain) NSInvocation *completionInvocation;
@property (readwrite, retain) NSInvocation *completionInvocation2;

// ========================================
// Action

- (void)addFile:(NSURL *)URL;
- (void)addM3UFile:(NSURL *)URL depth:(int)depth;

@end