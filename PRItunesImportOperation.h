#import <Cocoa/Cocoa.h>
@class PRDb, PRLibrary, PRCore;


@interface PRItunesImportOperation : NSOperation {
	__weak PRCore *_core;
	__weak PRDb *_db;
	
    NSURL *iTunesURL;
    NSMutableDictionary *_fileTrackIdDictionary;
    int _tempFileCount;
}
- (id)initWithURL:(NSURL *)URL_ core:(PRCore *)core;
+ (id)operationWithURL:(NSURL *)URL core:(PRCore *)core;
- (void)addTracks:(NSArray *)tracks;
- (void)addPlaylist:(NSDictionary *)playlist;
@end
