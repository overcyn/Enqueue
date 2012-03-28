#import <Cocoa/Cocoa.h>


@class PRDb, PRLibrary, PRCore;

@interface PRItunesImportOperation : NSOperation {
    NSURL *iTunesURL;
    NSMutableDictionary *_fileTrackIdDictionary;
    
    PRCore *_core;
	PRDb *_db;
    
    int _tempFileCount;
}
- (id)initWithURL:(NSURL *)URL_ core:(PRCore *)core;
+ (id)operationWithURL:(NSURL *)URL core:(PRCore *)core;
- (void)addTracks:(NSArray *)tracks;
- (void)addPlaylist:(NSDictionary *)playlist;
@end



@interface NSDictionary (trackSort)
- (int)trackSort:(NSDictionary *)dictionary;
@end

@implementation NSDictionary (trackSort)
- (int)trackSort:(NSDictionary *)dictionary { return [(NSString *)[self objectForKey:@"Location"] compare:[dictionary objectForKey:@"Location"]]; }
@end