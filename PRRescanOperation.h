#import <Foundation/Foundation.h>

@class PRTask, PRCore, PRDb;


@interface PRRescanOperation : NSOperation 
{
	NSArray *_URLs;
    FSEventStreamEventId _eventId;
    BOOL _monitor;
    
    // weak
    PRCore *_core;
    PRDb *_db;
}

// ========================================
// Initialization

+ (id)operationWithURLs:(NSArray *)URLs core:(PRCore *)core;
- (id)initWithURLs:(NSArray *)URLs core:(PRCore *)core;

// ========================================
// Accessors

@property (readwrite) FSEventStreamEventId eventId;
@property (readwrite) BOOL monitor;

// ========================================
// Action

- (void)filterURLs:(NSArray *)files;
- (void)addURLs:(NSArray *)URLs;
- (NSIndexSet *)mergeFiles:(NSArray *)files newURL:(NSURL *)URL;
- (void)updateFiles:(NSArray *)files;
- (void)removeFiles:(NSArray *)files;

// ========================================
// Misc

- (void)setFileExists:(PRFile)file;

@end
