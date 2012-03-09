#import "PRDirectoryEnumerator.h"
#import "NSFileManager+Extensions.h"

@implementation PRDirectoryEnumerator

- (id)initWithURLs:(NSArray *)URLs
{
    if (!(self = [super init])) {return nil;}
    // remove all subfolders
    NSMutableArray *topDirs = [NSMutableArray array];
    int count = [URLs count];
    for (int i = 0; i < count; i++) {
        BOOL isTop = TRUE;
        for (int j = 0; j < count; j++) {
            if (i == j) {
                continue;
            }
            if ([[[[NSFileManager alloc] init] autorelease] itemAtURL:[URLs objectAtIndex:j] containsItemAtURL:[URLs objectAtIndex:i]]) {
                isTop = FALSE;
                break;
            }
        }
        if (isTop) {
            [topDirs addObject:[URLs objectAtIndex:i]];
        }
    }
    
    _subDirs = [[NSMutableArray alloc] init];
    _URLEnumerator = [[topDirs objectEnumerator] retain];
    _dirEnumerator = nil;
    _fileManager = [[NSFileManager alloc] init];
    
    // get subdirectories
    NSArray *scanDirs = topDirs;
    int l = 0;
    while ([_subDirs count] < 100 && l < 3) {
        NSMutableArray *subDirs = [NSMutableArray array];
        for (NSURL *i in scanDirs) {
            [subDirs addObjectsFromArray:[_fileManager subDirsAtURL:i error:nil]];
        }
        scanDirs = subDirs;
        [_subDirs addObjectsFromArray:subDirs];
        l++;
    }    
    return self;
}

+ (PRDirectoryEnumerator *)enumeratorWithURLs:(NSArray *)URLs
{
    return [[[PRDirectoryEnumerator alloc] initWithURLs:URLs] autorelease];
}

- (void)dealloc
{
    [_subDirs release];
    [_URLEnumerator release];
    [_dirEnumerator release];
    [_fileManager release];
    [super dealloc];
}

- (id)nextObject
{
    // if directory enumerator return next file that isnt a directory
    if (_dirEnumerator) {
        NSURL *URL;
        while ((URL = [_dirEnumerator nextObject])) {
            if ([_subDirs containsObject:URL]) {
                _subDirsSeen += 1;
            }
            NSURL *volume = nil;
            NSNumber *regular = nil;
            NSDate *last = nil;
            NSNumber *size = nil;
            NSNumber *caseSensitive = nil;
            BOOL err1, err2, err3, err4, err5;
            err1 = [URL getResourceValue:&volume forKey:NSURLVolumeURLKey error:nil];
            err2 = [URL getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
            err3 = [URL getResourceValue:&last forKey:NSURLContentModificationDateKey error:nil];
            err4 = [URL getResourceValue:&size forKey:NSURLFileAllocatedSizeKey error:nil];
            err5 = [volume getResourceValue:&caseSensitive forKey:NSURLVolumeSupportsCaseSensitiveNamesKey error:nil];
            if ([regular boolValue] && err1 && err2 && err3 && err4 && err5 && volume && regular && last && size && caseSensitive) {
                return [NSDictionary dictionaryWithObjectsAndKeys:
                        URL, @"URL", 
                        last, @"lastModified", 
                        size, @"size", 
                        caseSensitive, @"case", nil];
            } 
        }
    }
    [_dirEnumerator release];
    _dirEnumerator = nil;
    
    // if no directory enumerator, or ran out of items.
    NSURL *URL;
    while ((URL = [_URLEnumerator nextObject])) {
        BOOL dir;
        BOOL exists = [_fileManager fileExistsAtPath:[URL path] isDirectory:&dir];
        if (!exists) {
            continue;
        }
        if (dir) {
            _dirEnumerator = [[_fileManager enumeratorAtURL:URL 
                                 includingPropertiesForKeys:[NSArray arrayWithObjects:
                                                             NSURLIsRegularFileKey,
                                                             NSURLFileAllocatedSizeKey,
                                                             NSURLContentModificationDateKey, 
                                                             NSURLVolumeURLKey, nil] 
                                                    options:0 
                                               errorHandler:nil] retain];
            return [self nextObject];
        } else {
            NSURL *volume = nil;
            NSNumber *regular = nil;
            NSDate *last = nil;
            NSNumber *size = nil;
            NSNumber *caseSensitive = nil;
            BOOL err1, err2, err3, err4, err5;
            err1 = [URL getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
            err2 = [URL getResourceValue:&last forKey:NSURLContentModificationDateKey error:nil];
            err3 = [URL getResourceValue:&size forKey:NSURLFileAllocatedSizeKey error:nil];
            err4 = [URL getResourceValue:&volume forKey:NSURLVolumeURLKey error:nil];
            err5 = [volume getResourceValue:&caseSensitive forKey:NSURLVolumeSupportsCaseSensitiveNamesKey error:nil];
            if ([regular boolValue]  && err1 && err2 && err3 && err4 && err5 && volume && regular && last && size && caseSensitive) {
                return [NSDictionary dictionaryWithObjectsAndKeys:
                        URL, @"URL", 
                        last, @"lastModified", 
                        size, @"size", 
                        caseSensitive, @"case", nil];
            }
        }
    }
    return nil;
}

- (float)progress
{
    float progress = (float)_subDirsSeen / (float)[_subDirs count];
    if (progress < 0) {
        return 0;
    } else if (progress > 1) {
        return 1;
    }
    return progress;
}

@end
