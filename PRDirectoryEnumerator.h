#import <Foundation/Foundation.h>


@interface PRDirectoryEnumerator : NSDirectoryEnumerator {
    // progress
    int _subDirsSeen;
    NSMutableArray *_subDirs;
    
    NSEnumerator *_URLEnumerator;
    NSDirectoryEnumerator *_dirEnumerator;
    NSFileManager *_fileManager;
}
// Initialization
- (id)initWithURLs:(NSArray *)URLs;
+ (PRDirectoryEnumerator *)enumeratorWithURLs:(NSArray *)URLs;

// Accessors
- (id)nextObject;
- (float)progress;
@end
