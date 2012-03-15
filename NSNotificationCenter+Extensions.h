#import <Foundation/Foundation.h>
#import "PRPlaylists.h"


extern NSString * const PRCurrentListDidChangeNotification;


@interface NSNotificationCenter (Extensions)
// Db
- (void)postLibraryChanged;
- (void)postFilesChanged:(NSIndexSet *)files;
- (void)postPlaylistsChanged;
- (void)postPlaylistChanged:(PRPlaylist)playlist;
- (void)postPlaylistFilesChanged:(PRPlaylist)playlist;

- (void)observeLibraryChanged:(id)obs sel:(SEL)sel;
- (void)observeFilesChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistsChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistFilesChanged:(id)obs sel:(SEL)sel;

// Library view
- (void)postLibraryViewSelectionChanged;

- (void)observeLibraryViewSelectionChanged:(id)obs sel:(SEL)sel;

// Preferences
- (void)postPreGainChanged;
- (void)postUseAlbumArtistChanged;
- (void)postEQChanged;

- (void)observePreGainChanged:(id)obs sel:(SEL)sel;
- (void)observeUseAlbumArtistChanged:(id)obs sel:(SEL)sel;
- (void)observeEQChanged:(id)obs sel:(SEL)sel;

// Last.fm
- (void)postLastfmStateChanged;

- (void)observeLastfmStateChanged:(id)obs sel:(SEL)sel;

// Playing
- (void)postTimeChanged;
- (void)postPlayingChanged;
- (void)postMovieFinished;
- (void)postMovieAlmostFinished;
- (void)postPlayingFileChanged;
- (void)postShuffleChanged;
- (void)postRepeatChanged;
- (void)postVolumeChanged;

- (void)observeTimeChanged:(id)obs sel:(SEL)sel;
- (void)observePlayingChanged:(id)obs sel:(SEL)sel;
- (void)observeMovieFinished:(id)obs sel:(SEL)sel;
- (void)observeMovieAlmostFinished:(id)obs sel:(SEL)sel;
- (void)observePlayingFileChanged:(id)obs sel:(SEL)sel;
- (void)observeShuffleChanged:(id)obs sel:(SEL)sel;
- (void)observeRepeatChanged:(id)obs sel:(SEL)sel;
- (void)observeVolumeChanged:(id)obs sel:(SEL)sel;
@end
