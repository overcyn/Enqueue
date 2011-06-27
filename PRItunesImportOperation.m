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
#import "PRLog.h"


@implementation PRItunesImportOperation

- (id)initWithURL:(NSURL *)URL_ core:(PRCore *)core_
{
    self = [super init];
    if (self) {
        core = core_;
        db = [core_ db];
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
    for (NSDictionary *i in tracks) {
        NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
        if ([task shouldCancel]) {
            [pool2 drain];
            goto end;
        }
        
        // File Exists
        NSURL *URL = [NSURL URLWithString:[i objectForKey:@"Location"]];
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
        NSIndexSet *files;
        [[[core db] library] files:&files withPath:[URL absoluteString] caseSensitive:[URL caseSensitive] _error:nil];
        if ([files count] > 0) {
            [pool2 drain];
            continue;
        }
        
        // File is Valid?
        PRTagEditor *tagEditor = [[[PRTagEditor alloc] initWithURL:URL db:[core db]] autorelease];
        if (!tagEditor) {
            [pool2 drain];
            continue;
        }
        
        [task performSelector:@selector(setTitle:) 
                     onThread:[NSThread mainThread]
                   withObject:[NSString stringWithFormat:@"Importing File: %@", [[URL path] lastPathComponent]] 
                waitUntilDone:FALSE];

        id object;
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        if ((object = [i objectForKey:@"Date Added"])) {
            [attributes setObject:[object description] forKey:[NSNumber numberWithInt:PRDateAddedFileAttribute]];
        }
        if ((object = [i objectForKey:@"Play Date UTC"])) {
            [attributes setObject:[object description] forKey:[NSNumber numberWithInt:PRLastPlayedFileAttribute]];
        }
        if ((object = [i objectForKey:@"Play Count"])) {
            [attributes setObject:object forKey:[NSNumber numberWithInt:PRPlayCountFileAttribute]];
        }
        if ((object = [i objectForKey:@"Rating"])) {
            [attributes setObject:object forKey:[NSNumber numberWithInt:PRRatingFileAttribute]];
        }

        PRFile file;
        [tagEditor addFile:&file withAttributes:attributes];
        
        NSString *trackID = [i objectForKey:@"Track ID"];
        if (trackID) {
            [fileTrackIDDictionary setValue:[NSNumber numberWithInt:file] forKey:trackID];
        }

        [pool2 drain];
    }
    
    [task performSelector:@selector(setTitle:) 
                 onThread:[NSThread mainThread]
               withObject:[NSString stringWithFormat:@"Importing Playlists"] 
            waitUntilDone:FALSE];
    
    for (NSDictionary *i in [plist objectForKey:@"Playlists"]) {
        if ([task shouldCancel]) {
            goto end;
        }
        if ([[i objectForKey:@"Master"] boolValue] || 
            [i objectForKey:@"Distinguished Kind"]) {
            continue;
        }
        int playlist;
        if (![[db playlists] addStaticPlaylist:&playlist _error:nil]) {
            continue;
        }

        if ([i objectForKey:@"Name"]) {
            [[db playlists] setValue:[i objectForKey:@"Name"] 
                         forPlaylist:playlist 
                           attribute:PRTitlePlaylistAttribute 
                              _error:nil];
        }
        
        for (NSDictionary *j in [i objectForKey:@"Playlist Items"]) {
            NSNumber *fileID = [j objectForKey:@"Track ID"];
            if (fileID == nil) {
                continue;
            }
            NSNumber *playlistItem = [fileTrackIDDictionary objectForKey:fileID];
            if (playlistItem == nil) {
                continue;
            }
            [[db playlists] appendFile:[playlistItem intValue] toPlaylist:playlist _error:nil];
        }
    }
    
end:;
    [[core taskManager] removeTask:task];
    NSNotification *notification = [NSNotification notificationWithName:PRLibraryDidChangeNotification 
                                                                 object:self 
                                                               userInfo:nil];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
														   withObject:notification 
														waitUntilDone:TRUE];
    [pool drain];
    NSLog(@"End Import Operation");
}

@end