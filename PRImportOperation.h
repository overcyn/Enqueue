#import <Cocoa/Cocoa.h>


@class PRCore, PRTask, PRDb;

@interface PRImportOperation : NSOperation 
{
	NSArray *URLs;
    BOOL background;
    BOOL playWhenDone;
    PRTask *task;
    NSMutableArray *URLsToPlay;
    int _tempFileCount;
    PRDb *_db;
    
    NSInvocation *completionInvocation;
    NSInvocation *completionInvocation2;
    
    PRCore *core;
}

// ========================================
// Initialization

- (id)initWithURLs:(NSArray *)URLs_ recursive:(BOOL)recursive_ core:(PRCore *)core_;

// ========================================
// Accessors

@property (readwrite) BOOL background;
@property (readwrite) BOOL playWhenDone;

// invoked on main thread if successful completion without cancellation
@property (readwrite, retain) NSInvocation *completionInvocation;
@property (readwrite, retain) NSInvocation *completionInvocation2;

// ========================================
// Action

- (void)addFile:(NSURL *)URL;
- (void)addM3UFile:(NSURL *)URL depth:(int)depth;

@end