#import <Cocoa/Cocoa.h>


/* General */
extern NSString * const PRDefaultsUseCompilation;               // bool
extern NSString * const PRDefaultsFolderArtwork;                // bool

/* PRFolderMonitor */
extern NSString * const PRDefaultsMonitoredFolders;				// @[NSString]
extern NSString * const PRDefaultsLastEventStreamEventId;		// FSEventStreamEventId

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

/* PRMediaKeyController */
extern NSString * const PRDefaultsMediaKeys;                    // bool

/* PRMoviePlayer */
extern NSString * const PRDefaultsVolume;                       // float (0 - 1)
extern NSString * const PRDefaultsPregain;                      // float (0 - 1)
extern NSString * const PRDefaultsHogOutput;                    // bool
extern NSString * const PRDefaultsEQCurrent; 					// PREQ (readonly, fake)

/* PRNowPlayingController */
extern NSString * const PRDefaultsRepeat;                       // bool
extern NSString * const PRDefaultsShuffle;                      // bool

/* PRPreferenceViewController */
extern NSString * const PRDefaultsEQCustomArray;                // @[PREQ]
extern NSString * const PRDefaultsEQIsCustom;                   // bool
extern NSString * const PRDefaultsEQIndex;                      // int
extern NSString * const PRDefaultsEQEnabled;                    // bool


@interface PRDefaults : NSObject {
	NSUserDefaults *defaults;
    NSMutableDictionary *_handlers; // @{key:@[PRDefaultsGetter, PRDefaultsSetter], ...}
}
/* Initialization */
+ (PRDefaults *)sharedDefaults;

/* Accessors */
- (id)valueForKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;

- (BOOL)boolValueForKey:(NSString *)key;
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key;
- (int)intValueForKey:(NSString *)key;
- (void)setIntValue:(int)value forKey:(NSString *)key;
- (float)floatValueForKey:(NSString *)key;
- (void)setFloatValue:(float)value forKey:(NSString *)key;

/* Accessors */
// @property (readwrite) BOOL repeat;
// @property (readwrite) BOOL shuffle;
@property (readwrite) BOOL hogOutput;

@property (readwrite, copy) NSArray *customEQs;
@property (readwrite) BOOL isCustomEQ;
@property (readwrite) int EQIndex;
@property (readwrite) BOOL EQIsEnabled;

@property (readwrite) BOOL showWelcomeSheet;
@property (readwrite) BOOL miniPlayer;
@property (readwrite) NSRect miniPlayerFrame;
@property (readwrite) NSRect playerFrame;
@property (readwrite) float sidebarWidth;
@property (readwrite, copy) NSIndexSet *nowPlayingCollapseState;

@property (readwrite) BOOL mediaKeys;
@property (readwrite) BOOL postGrowlNotification;
@property (readwrite, retain) NSString *lastFMUsername;
@property (readwrite) BOOL showsArtwork;
@property (readwrite) BOOL useAlbumArtist;
@property (readwrite) BOOL useCompilation;
@property (readwrite) BOOL nowPlayingCollapsible; // remove not used
@property (readwrite) BOOL folderArtwork;

@property (readwrite, retain) NSArray *monitoredFolders;
@property (readwrite) FSEventStreamEventId lastEventStreamEventId;

@property (readonly) NSString *applicationSupportPath;
@property (readonly) NSString *libraryPath;
@property (readonly) NSString *backupPath;
@property (readonly) NSString *cachedAlbumArtPath;
@property (readonly) NSString *downloadedAlbumArtPath;
@property (readonly) NSString *tempArtPath;
@end


@interface PRDefaults ()
- (void)setKeyMask:(unsigned int)mask keyCode:(int)code forHotKey:(int)hotKey;
- (void)keyMask:(unsigned int *)mask keyCode:(int *)code forHotKey:(int)hotKey;
@end
