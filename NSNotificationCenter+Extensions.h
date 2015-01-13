#import <Foundation/Foundation.h>
#import "PRPlaylists.h"

@interface PRChangeSet : NSObject
@property (nonatomic, strong) NSArray *changes;
@end

@interface PRListChange : NSObject
@property (nonatomic, strong) PRListID *list;
@end

@interface PRNowPlayingChange : NSObject
@end

@interface PRMovieChange : NSObject
@property (nonatomic) BOOL progress;
@end

// KD: todo

@interface PRLibraryChange : NSObject
@end

@interface PRItemChange : NSObject
@property (nonatomic, strong) NSArray *items;
@end

@interface PRListsChange : NSObject
@end

@interface PRListItemsChange : NSObject
@property (nonatomic, strong) PRListID *list;
@end

extern NSString * const PRLibraryViewSelectionDidChangeNotification;

extern NSString * const PRLastfmStateDidChangeNotification;
extern NSString * const PRDeviceDidChangeNotification;

@interface NSNotificationCenter (Extensions)
+ (void)post:(NSString *)name;
+ (void)post:(NSString *)name object:(id)object info:(NSDictionary *)info;
+ (void)addObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;
+ (void)removeObserver:(id)observer;

/* Changeset */
- (void)postChanges:(NSArray *)changes;
- (void)observeBackendChanged:(id)obs sel:(SEL)sel;

/* Db */
- (void)postLibraryChanged;
- (void)postItemsChanged:(NSArray *)items;
- (void)postListsDidChange;
- (void)postListItemsDidChange:(PRListID *)list;

- (void)observeLibraryChanged:(id)obs sel:(SEL)sel;
- (void)observeItemsChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistsChanged:(id)obs sel:(SEL)sel;
- (void)observePlaylistFilesChanged:(id)obs sel:(SEL)sel;

/* Preferences */
- (void)postPreGainChanged;
- (void)postUseAlbumArtistChanged;
- (void)postEQChanged;

- (void)observePreGainChanged:(id)obs sel:(SEL)sel;
- (void)observeUseAlbumArtistChanged:(id)obs sel:(SEL)sel;
- (void)observeEQChanged:(id)obs sel:(SEL)sel;

/* PRMovie */
- (void)postMovieFinished;
- (void)postMovieAlmostFinished;

- (void)observeMovieFinished:(id)obs sel:(SEL)sel;
- (void)observeMovieAlmostFinished:(id)obs sel:(SEL)sel;

@end
