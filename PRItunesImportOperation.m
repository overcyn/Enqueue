#import "PRItunesImportOperation.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRAlbumArtController.h"
#import "NSURL+Extensions.h"
#import "PRTaskManager.h"
#import "PRTask.h"
#import "PRCore.h"
#import "PRTagEditor.h"


@implementation PRItunesImportOperation

- (id)initWithURL:(NSURL *)URL_ core:(PRCore *)core_
{
    self = [super init];
    if (self) {
        core = core_;
        _db = [core_ db2];
        _tempFileCount = 0;
        iTunesURL = [URL_ retain];
    }
    
    return self;
}

- (void)dealloc
{
    [iTunesURL release];
    [super dealloc];
}

- (void)main
{
    NSLog(@"Begin Import Operation");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[_db library] clearTempFiles];
    
    PRTask *task = [[[PRTask alloc] init] autorelease];
    [task setTitle:@"Opening iTunes Library..."];
    [[core taskManager] addTask:task];
    
    NSString *errorDescription;
    NSUInteger format;
    NSData *plistXML = [[[[NSFileManager alloc] init] autorelease] contentsAtPath:[iTunesURL path]];
    NSDictionary *plist = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:plistXML
                                                                           mutabilityOption:NSPropertyListImmutable
                                                                                     format:&format
                                                                           errorDescription:&errorDescription];
    
    NSMutableArray *tracks = [NSMutableArray arrayWithArray:[[plist objectForKey:@"Tracks"] allValues]];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
    for (int i = 0; i < [tracks count]; i++) {
        NSDictionary *track = [tracks objectAtIndex:i];
        if ([[track objectForKey:@"Movie"] boolValue] ||
            [[track objectForKey:@"Podcast"] boolValue] ||
            [[track objectForKey:@"iTunesU"] boolValue] ||
            [[track objectForKey:@"Books"] boolValue] ||
            [[track objectForKey:@"Audiobooks"] boolValue] ||
            [[track objectForKey:@"TV Shows"] boolValue] ||
            ![track objectForKey:@"Location"]) {
            [indexesToRemove addIndex:i];
        }
    }
    [tracks removeObjectsAtIndexes:indexesToRemove];
    [tracks sortUsingSelector:@selector(trackSort:)];
    
    NSDictionary *fileTrackIDDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    for (int i = 0; i < [tracks count]; i++) {
        NSDictionary *track = [tracks objectAtIndex:i];
        NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
        if ([task shouldCancel]) {
            [pool2 drain];
            goto end;
        }
        
        // File Exists
        NSURL *URL = [NSURL URLWithString:[track objectForKey:@"Location"]];
        if (!URL) {
            [pool2 drain];
            continue;
        }
        BOOL isDirectory;
        BOOL fileExists = [[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:[URL path] isDirectory:&isDirectory];
        if (!fileExists || isDirectory) {
            [pool2 drain];
            continue;
        }
        
        // Existing files?
        NSIndexSet *files = [[_db library] filesWithPath:[URL absoluteString] caseSensitive:[URL caseSensitive]];
        if ([files count] > 0) {
            [pool2 drain];
            continue;
        }
        
        // File is Valid?
        PRTagEditor *tagEditor = [[[PRTagEditor alloc] initWithURL:URL db:_db] autorelease];
        if (!tagEditor) {
            [pool2 drain];
            continue;
        }
        
        [task performSelector:@selector(setTitle:) 
                     onThread:[NSThread mainThread]
                   withObject:[NSString stringWithFormat:@"Importing files: %d%%", i * 100 / [tracks count]] 
                waitUntilDone:FALSE];

        id object;
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        if ((object = [track objectForKey:@"Date Added"])) {
            [attributes setObject:[object description] forKey:[NSNumber numberWithInt:PRDateAddedFileAttribute]];
        }
        if ((object = [track objectForKey:@"Play Date UTC"])) {
            [attributes setObject:[object description] forKey:[NSNumber numberWithInt:PRLastPlayedFileAttribute]];
        }
        if ((object = [track objectForKey:@"Play Count"])) {
            [attributes setObject:object forKey:[NSNumber numberWithInt:PRPlayCountFileAttribute]];
        }
        if ((object = [track objectForKey:@"Rating"])) {
            [attributes setObject:object forKey:[NSNumber numberWithInt:PRRatingFileAttribute]];
        }
        
        PRFile tempFile = [[_db library] addTempFileWithPath:[URL absoluteString]];
        [tagEditor setTempFile:TRUE];
        [tagEditor setFile:tempFile];
        [tagEditor updateTags];
        [[_db library] setAttributes:attributes forTempFile:tempFile];
        
        _tempFileCount += 1;
        if (_tempFileCount > 500) {
            [[_db library] mergeTempFilesToLibrary];
            NSNotification *notification = [NSNotification notificationWithName:PRLibraryDidChangeNotification 
                                                                         object:self 
                                                                       userInfo:nil];
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
                                                                   withObject:notification 
                                                                waitUntilDone:TRUE];
            _tempFileCount = 0;
        }
        
        NSString *trackID = [track objectForKey:@"Track ID"];
        if (trackID) {
            [fileTrackIDDictionary setValue:[NSNumber numberWithInt:tempFile] forKey:trackID];
        }
        [pool2 drain];
    }
    [[_db library] mergeTempFilesToLibrary];
    
    // Playlists
    for (NSDictionary *i in [plist objectForKey:@"Playlists"]) {
        if ([task shouldCancel]) {
            goto end;
        }
        if ([[i objectForKey:@"Master"] boolValue] || [i objectForKey:@"Distinguished Kind"]) {
            continue;
        }
        [task performSelector:@selector(setTitle:) 
                     onThread:[NSThread mainThread]
                   withObject:[NSString stringWithFormat:@"Importing Playlist:%@", [i objectForKey:@"Name"]]
                waitUntilDone:FALSE];
        
        int playlist = [[_db playlists] addStaticPlaylist];
        
        if ([i objectForKey:@"Name"]) {
            [[_db playlists] setValue:[i objectForKey:@"Name"] forPlaylist:playlist attribute:PRTitlePlaylistAttribute];
        }
        
        NSMutableIndexSet *files = [NSMutableIndexSet indexSet];
        for (NSDictionary *j in [i objectForKey:@"Playlist Items"]) {
            NSNumber *track = [j objectForKey:@"Track ID"];
            if (track == nil) {
                continue;
            }
            NSNumber *file = [fileTrackIDDictionary objectForKey:track];
            if (file == nil) {
                continue;
            }
            [files addIndex:[file intValue]];
        }
        [[_db playlists] appendFiles:files toPlaylist:playlist];
    }
    
end:;
    [[core taskManager] removeTask:task];
    NSNotification *notification = [NSNotification notificationWithName:PRLibraryDidChangeNotification 
                                                                 object:self 
                                                               userInfo:nil];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
														   withObject:notification 
														waitUntilDone:TRUE];
    notification = [NSNotification notificationWithName:PRPlaylistsDidChangeNotification 
                                                 object:self 
                                               userInfo:nil];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
														   withObject:notification 
														waitUntilDone:TRUE];
    [pool drain];
    NSLog(@"End Import Operation");
}

@end