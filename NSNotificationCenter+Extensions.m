#import "NSNotificationCenter+Extensions.h"
#import "PRPlaylists.h"


NSString * const PRLibraryDidChangeNotification = @"PRLibraryDidChangeNotification";
NSString * const PRTagsDidChangeNotification = @"PRTagsDidChangeNotification";
NSString * const PRPlaylistDidChangeNotification = @"PRPlaylistDidChangeNotification";
NSString * const PRPlaylistsDidChangeNotification = @"PRPlaylistsDidChangeNotification";
NSString * const PRPlaylistFilesChangedNote = @"PRPlaylistFilesChangedNote";

NSString * const PRCurrentListDidChangeNotification = @"PRCurrentListDidChangeNotification";
NSString * const PRLibraryViewSelectionDidChangeNotification = @"PRLibraryViewSelectionDidChangeNotification";

NSString * const PRPreGainDidChangeNotification = @"PRPreGainDidChangeNotification";
NSString * const PRUseAlbumArtistDidChangeNotification = @"PRUseAlbumArtistDidChangeNotification";

NSString * const PRIsPlayingDidChangeNotification = @"PRIsPlayingDidChangeNotification";
NSString * const PRMovieDidFinishNotification = @"PRMovieDidFinishNotification";
NSString * const PRMovieAlmostFinishedNote = @"PRMovieAlmostFinishedNote";

NSString * const PRLastfmStateChangedNote = @"PRLastfmStateChangedNote";

NSString * const PRTimeChangedNote = @"PRTimeChangedNote";
NSString * const PRCurrentFileDidChangeNotification = @"PRCurrentFileDidChangeNotification";
NSString * const PRShuffleDidChangeNotification = @"PRShuffleDidChangeNotification";
NSString * const PRRepeatDidChangeNotification = @"PRRepeatDidChangeNotification";
NSString * const PRVolumeChangedNote = @"PRVolumeChangedNote";
NSString * const PREQChangedNote = @"PREQChangedNote";


@implementation NSNotificationCenter (Extensions)

+ (void)post:(NSString *)name {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
}

+ (void)post:(NSString *)name object:(id)object info:(NSDictionary *)info {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:object userInfo:info];
}

+ (id)observe:(NSString *)name block:(void (^)(NSNotification *))block {
    return [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:nil usingBlock:block];
}

+ (id)observe:(NSString *)name object:(id)object queue:(NSOperationQueue *)queue block:(void (^)(NSNotification *))block {
    return [[NSNotificationCenter defaultCenter] addObserverForName:name object:object queue:queue usingBlock:block];
}

+ (void)removeObserver:(id)observer {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}


// Db notifications

- (void)postLibraryChanged {
    [self postNotificationName:PRLibraryDidChangeNotification object:nil];
}

- (void)postItemsChanged:(NSArray *)items {
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:items, @"files", nil];
    [self postNotificationName:PRTagsDidChangeNotification object:nil userInfo:info];
}

- (void)postListsDidChange {
    [self postNotificationName:PRPlaylistsDidChangeNotification object:nil];
}

- (void)postListDidChange:(NSNumber *)list {
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:list, @"playlist", nil];
    [self postNotificationName:PRPlaylistDidChangeNotification object:nil userInfo:info];
}

- (void)postListItemsDidChange:(NSNumber *)list {
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:list, @"playlist", nil];
    [self postNotificationName:PRPlaylistFilesChangedNote object:nil userInfo:info];
}

- (void)observeLibraryChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRLibraryDidChangeNotification object:nil];
}

- (void)observeItemsChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRTagsDidChangeNotification object:nil];
}

- (void)observePlaylistsChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRPlaylistsDidChangeNotification object:nil];
}

- (void)observePlaylistChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRPlaylistDidChangeNotification object:nil];
}

- (void)observePlaylistFilesChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRPlaylistFilesChangedNote object:nil];
}

// Library View

- (void)postLibraryViewSelectionChanged {
    [self postNotificationName:PRLibraryViewSelectionDidChangeNotification object:nil];
}

- (void)observeLibraryViewSelectionChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRLibraryViewSelectionDidChangeNotification object:nil];
}

// Preferences

- (void)postPreGainChanged {
    [self postNotificationName:PRPreGainDidChangeNotification object:nil];
}

- (void)postUseAlbumArtistChanged {
    [self postNotificationName:PRUseAlbumArtistDidChangeNotification object:nil];
}

- (void)postEQChanged {
    [self postNotificationName:PREQChangedNote object:nil];
}

- (void)observePreGainChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRPreGainDidChangeNotification object:nil];
}

- (void)observeUseAlbumArtistChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRUseAlbumArtistDidChangeNotification object:nil];
}

- (void)observeEQChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PREQChangedNote object:nil];
}

// Lastfm

- (void)postLastfmStateChanged {
    [self postNotificationName:PRLastfmStateChangedNote object:nil];
}

- (void)observeLastfmStateChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRLastfmStateChangedNote object:nil];
}

// Playing 

- (void)postTimeChanged {
    [self postNotificationName:PRTimeChangedNote object:nil];
}

- (void)postPlayingChanged {
    [self postNotificationName:PRIsPlayingDidChangeNotification object:nil];
}

- (void)postMovieFinished {
    [self postNotificationName:PRMovieDidFinishNotification object:nil];
}

- (void)postMovieAlmostFinished {
    [self postNotificationName:PRMovieAlmostFinishedNote object:nil];
}

- (void)postPlayingFileChanged {
    [self postNotificationName:PRCurrentFileDidChangeNotification object:nil];
}

- (void)postShuffleChanged {
    [self postNotificationName:PRShuffleDidChangeNotification object:nil];
}

- (void)postRepeatChanged {
    [self postNotificationName:PRRepeatDidChangeNotification object:nil];
}

- (void)postVolumeChanged {
    [self postNotificationName:PRVolumeChangedNote object:nil];
}

- (void)observeTimeChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRTimeChangedNote object:nil];
}

- (void)observePlayingChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRIsPlayingDidChangeNotification object:nil];
}

- (void)observeMovieFinished:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRMovieDidFinishNotification object:nil];
}

- (void)observeMovieAlmostFinished:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRMovieAlmostFinishedNote object:nil];
}

- (void)observePlayingFileChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRCurrentFileDidChangeNotification object:nil];
}

- (void)observeShuffleChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRShuffleDidChangeNotification object:nil];
}

- (void)observeRepeatChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRRepeatDidChangeNotification object:nil];
}

- (void)observeVolumeChanged:(id)obs sel:(SEL)sel {
    [self addObserver:obs selector:sel name:PRVolumeChangedNote object:nil];
}

@end
