#import <Foundation/Foundation.h>
#import "PRPlaylists.h"

@interface PRChangeSet : NSObject
@property (nonatomic, strong) NSArray *changes;
@end

@interface PRLibraryChange : NSObject
@end

@interface PRItemChange : NSObject
@property (nonatomic, strong) NSArray *items;
@end

@interface PRListsChange : NSObject
@end

@interface PRListChange : NSObject
@property (nonatomic, strong) PRList *list;
@end

@interface PRListItemsChange : NSObject
@property (nonatomic, strong) PRList *list;
@end







extern NSString * const PRCurrentListDidChangeNotification;
extern NSString * const PRLibraryViewSelectionDidChangeNotification;

extern NSString * const PRLastfmStateDidChangeNotification;
extern NSString * const PRDeviceDidChangeNotification;

@interface NSNotificationCenter (Extensions)
+ (void)post:(NSString *)name;
+ (void)post:(NSString *)name object:(id)object info:(NSDictionary *)info;
+ (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;
+ (void)removeObserver:(id)observer;

/* Changeset */
- (void)postBackendChanged:(PRChangeSet *)changeset;
- (void)observeBackendChanged:(id)obs sel:(SEL)sel;

/* Db */
- (void)postLibraryChanged;
- (void)postItemsChanged:(NSArray *)items;
- (void)postListsDidChange;
- (void)postListDidChange:(PRList *)list;
- (void)postListItemsDidChange:(PRList *)list;

- (void)observeLibraryChanged:(id)obs sel:(SEL)sel;
- (void)observeItemsChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistsChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistFilesChanged:(id)obs sel:(SEL)sel;

/* Preferences */
- (void)postPreGainChanged;
- (void)postUseAlbumArtistChanged;
- (void)postEQChanged;

- (void)observePreGainChanged:(id)obs sel:(SEL)sel;
- (void)observeUseAlbumArtistChanged:(id)obs sel:(SEL)sel;
- (void)observeEQChanged:(id)obs sel:(SEL)sel;

/* PRMoviePlayer */
- (void)postTimeChanged;
- (void)postPlayingChanged;
- (void)postMovieFinished;
- (void)postMovieAlmostFinished;

- (void)observeTimeChanged:(id)obs sel:(SEL)sel;
- (void)observePlayingChanged:(id)obs sel:(SEL)sel;
- (void)observeMovieFinished:(id)obs sel:(SEL)sel;
- (void)observeMovieAlmostFinished:(id)obs sel:(SEL)sel;


/* PRNowPlayingController */
- (void)postPlayingFileChanged;
- (void)postShuffleChanged;
- (void)postRepeatChanged;
- (void)postVolumeChanged;

- (void)observePlayingFileChanged:(id)obs sel:(SEL)sel;
- (void)observeShuffleChanged:(id)obs sel:(SEL)sel;
- (void)observeRepeatChanged:(id)obs sel:(SEL)sel;
- (void)observeVolumeChanged:(id)obs sel:(SEL)sel;
@end
