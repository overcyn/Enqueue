#import <Foundation/Foundation.h>
@class PRTask, PRCore, PRDb;


@interface PRRescanOperation : NSOperation {
    __weak PRCore *_core;
    __weak PRDb *_db;
    
	NSArray *_URLs;
    FSEventStreamEventId _eventId;
    BOOL _monitor;
}

// Initialization
+ (id)operationWithURLs:(NSArray *)URLs core:(PRCore *)core;
- (id)initWithURLs:(NSArray *)URLs core:(PRCore *)core;

// Accessors
@property (readwrite) FSEventStreamEventId eventId;
@property (readwrite) BOOL monitor;

// Action
- (void)filterURLs:(NSArray *)files;
- (void)addURLs:(NSArray *)URLs;
- (void)mergeSimilar:(NSURL *)URL;
- (void)updateFiles:(NSArray *)files;
- (void)removeFiles:(NSArray *)files;

// Misc
- (void)setFileExists:(PRFile)file;
@end
