#import <Cocoa/Cocoa.h>


/* General */
extern NSString * const PRDefaultsUseAlbumArtist;               // bool
extern NSString * const PRDefaultsUseCompilation;               // bool
extern NSString * const PRDefaultsFolderArtwork;                // bool

/* PRFolderMonitor */
extern NSString * const PRDefaultsMonitoredFolders;                // @[NSString, ...]
extern NSString * const PRDefaultsLastEventStreamEventId;        // FSEventStreamEventId

/* PRGrowl */
extern NSString * const PRDefaultsPostGrowl;                    // bool

/* PRLastfm */
extern NSString * const PRDefaultsLastFMUsername;               // NSString

/* PRMainWindowController & friends */
extern NSString * const PRDefaultsShowWelcomeSheet;             // bool
extern NSString * const PRDefaultsShowArtwork;                  // bool
extern NSString * const PRDefaultsMiniPlayer;                   // bool
extern NSString * const PRDefaultsMiniPlayerFrame;              // NSRect
extern NSString * const PRDefaultsPlayerFrame;                  // NSRect
extern NSString * const PRDefaultsSidebarWidth;                 // float
extern NSString * const PRDefaultsNowPlayingCollapseState;      // NSIndexSet

/* PRMediaKeyController & PRHotKeyController */
extern NSString * const PRDefaultsMediaKeys;                    // bool
extern NSString * const PRDefaultsPlayPauseHotKey;              // @[unsigned int(mask), int(code)]
extern NSString * const PRDefaultsNextHotKey;
extern NSString * const PRDefaultsPreviousHotKey;
extern NSString * const PRDefaultsIncreaseVolumeHotKey;
extern NSString * const PRDefaultsDecreaseVolumeHotKey;
extern NSString * const PRDefaultsRate0HotKey;
extern NSString * const PRDefaultsRate1HotKey;
extern NSString * const PRDefaultsRate2HotKey;
extern NSString * const PRDefaultsRate3HotKey;
extern NSString * const PRDefaultsRate4HotKey;
extern NSString * const PRDefaultsRate5HotKey;

/* PRMoviePlayer */
extern NSString * const PRDefaultsVolume;                       // float (0 - 1)
extern NSString * const PRDefaultsPregain;                      // float (0 - 1)
extern NSString * const PRDefaultsHogOutput;                    // bool
extern NSString * const PRDefaultsEQCurrent;                     // PREQ (readonly, fake)
extern NSString * const PRDefaultsOutputDeviceUID;                 // NSString

/* PRNowPlayingController */
extern NSString * const PRDefaultsRepeat;                       // bool
extern NSString * const PRDefaultsShuffle;                      // bool

/* PRPreferenceViewController */
extern NSString * const PRDefaultsEQCustomArray;                // @[PREQ, ...]
extern NSString * const PRDefaultsEQIsCustom;                   // bool
extern NSString * const PRDefaultsEQIndex;                      // int
extern NSString * const PRDefaultsEQEnabled;                    // bool


@interface PRDefaults : NSObject {
    NSUserDefaults *defaults;
    NSDictionary *_handlers; // @{key:@[PRDefaultsGetter, PRDefaultsSetter], ...}
}
/* Initialization */
+ (PRDefaults *)sharedDefaults;

/* Accessors */
- (id)valueForKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (int)intForKey:(NSString *)key;
- (void)setInt:(int)value forKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (void)setFloat:(float)value forKey:(NSString *)key;
- (NSRect)rectForKey:(NSString *)key;
- (void)setRect:(NSRect)value forKey:(NSString *)key;

@property (weak, readonly) NSString *applicationSupportPath;
@property (weak, readonly) NSString *libraryPath;
@property (weak, readonly) NSString *backupPath;
@property (weak, readonly) NSString *cachedAlbumArtPath;
@property (weak, readonly) NSString *downloadedAlbumArtPath;
@property (weak, readonly) NSString *tempArtPath;
@end
