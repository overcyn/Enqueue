#import "NSFileManager+Extensions.h"

@implementation NSFileManager (Extensions)

- (BOOL)itemAtURL:(NSURL *)u1 containsItemAtURL:(NSURL *)u2 {
    FSRef ref, ref2;
    BOOL err = CFURLGetFSRef((CFURLRef)u1, &ref);
    if (!err) {return NO;}
    err = CFURLGetFSRef((CFURLRef)u2, &ref2);
    if (!err) {return NO;}
    
    while (YES) {        
        // Get parent ref
        FSRef parentRef;
        OSErr e = FSGetCatalogInfo(&ref2, kFSCatInfoNone, NULL, NULL, NULL, &parentRef);
        if (e != noErr) {return NO;}
        ref2 = parentRef;
        
        // Check if parent ref is valid
        e = FSGetCatalogInfo(&ref2, kFSCatInfoNone, nil, nil, nil, nil );
        if (e != noErr) {return NO;}
        
        // Compare refs
        if (FSCompareFSRefs(&ref, &ref2) == noErr) {
            return YES;
        }
    }
    return NO;

}

- (BOOL)itemAtURL:(NSURL *)u1 equalsItemAtURL:(NSURL *)u2 {
    NSString *name1 = nil;
    NSString *name2 = nil;
    BOOL err = [u1 getResourceValue:&name1 forKey:NSURLNameKey error:nil];
    BOOL err2 = [u2 getResourceValue:&name2 forKey:NSURLNameKey error:nil];
    if (!err || !err2 || !name1 || !name2) {
        return NO;
    }
    return [name1 isEqualToString:name2];
}

- (NSArray *)subDirsAtURL:(NSURL *)URL error:(NSError **)error {
    NSMutableArray *subdirs = [NSMutableArray array];
    NSArray *contents = [self contentsOfDirectoryAtURL:URL
                            includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                               options:0 
                                                 error:error];
    if (!contents) {return @[];}
    
    for (NSURL *i in contents) {
        NSNumber *isDir = nil;
        BOOL err = [i getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:error];
        if (!err || !isDir) {continue;}
        
        if ([isDir boolValue]) {
            [subdirs addObject:i];
        }
    }
    return subdirs;
}

@end
