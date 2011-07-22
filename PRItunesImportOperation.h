#import <Cocoa/Cocoa.h>


@class PRDb, PRLibrary, PRCore;

@interface PRItunesImportOperation : NSOperation 
{
    NSURL *iTunesURL;
    
    PRCore *core;
	PRDb *_db;
    
    int _tempFileCount;
}

- (id)initWithURL:(NSURL *)URL_ core:(PRCore *)core;

@end



@interface NSDictionary (trackSort)
- (int)trackSort:(NSDictionary *)dictionary;
@end

@implementation NSDictionary (trackSort)
- (int)trackSort:(NSDictionary *)dictionary { return [(NSString *)[self objectForKey:@"Location"] compare:[dictionary objectForKey:@"Location"]]; }
@end