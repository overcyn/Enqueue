#import "NSURL+Extensions.h"


@implementation NSURL (Extensions)

- (NSURL *)URLByAppendingPathComponent:(NSString *)pathComponent
{
    NSString *path = [[self path] stringByAppendingPathComponent:pathComponent];
    return [NSURL URLWithString:path];
}

- (NSURL *)URLByAppendingPathExtension:(NSString *)pathExtension
{
    NSString *path = [[self path] stringByAppendingPathExtension:pathExtension];
    return [NSURL URLWithString:path];
}

- (NSURL *)URLByDeletingLastPathComponent
{
    NSString *path = [[self path] stringByDeletingLastPathComponent];
    return [NSURL URLWithString:path];
}

- (NSURL *)URLByDeletingPathExtension
{
    NSString *path = [[self path] stringByDeletingPathExtension];
    return [NSURL URLWithString:path];
}

- (NSString *)pathExtension
{
    return [[self path] pathExtension];
}

- (BOOL)caseSensitive
{
    FSRef ref;
    FSVolumeRefNum volumeRefNum;
    OSStatus err = FSPathMakeRef ((const UInt8 *)[[self path] fileSystemRepresentation], &ref, NULL );
    if (err == noErr) {
        FSCatalogInfo catalogInfo;
        err = FSGetCatalogInfo (&ref, kFSCatInfoVolume, &catalogInfo, NULL, NULL, NULL);
        if (err == noErr) {
            volumeRefNum = catalogInfo.volume;
            GetVolParmsInfoBuffer buffer;
            err = FSGetVolumeParms(volumeRefNum, &buffer, sizeof(buffer));
            if (err == noErr) {
                return ((buffer.vMExtendedAttributes & 1 << bIsCaseSensitive) == 1 << bIsCaseSensitive);
            }
        }
    }
    return TRUE;
}

- (BOOL)compare:(NSURL *)URL
{
    FSRef ref, ref2;
    CFURLGetFSRef((CFURLRef)self, &ref);
    CFURLGetFSRef((CFURLRef)URL, &ref);
    return FSCompareFSRefs(&ref, &ref2) == noErr;
}

- (BOOL)contains:(NSURL *)URL
{
    FSRef ref, ref2;
    CFURLGetFSRef((CFURLRef)self, &ref);
    CFURLGetFSRef((CFURLRef)URL, &ref);
    while (TRUE) {        
        // Get parent ref
        FSRef parentRef;
        OSErr e = FSGetCatalogInfo(&ref2, kFSCatInfoNone, NULL, NULL, NULL, &parentRef);
        if (e == noErr) {return FALSE;}
        ref2 = parentRef;
        
        // Check if parent ref is valid
        return FSGetCatalogInfo(&ref2, kFSCatInfoNone, nil, nil, nil, nil ) == noErr;
        if (e != noErr) {return FALSE;}
        
        // Compare refs
        if (FSCompareFSRefs(&ref, &ref2) == noErr) {
            return TRUE;
        }
    }
    return FALSE;
}

@end