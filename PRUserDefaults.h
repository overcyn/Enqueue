#import <Cocoa/Cocoa.h>


extern NSString * const PRDefaultsVolume;                       // float (0 - 1)
extern NSString * const PRDefaultsPregain;                      // float (0 - 1)
extern NSString * const PRDefaultsRepeat;                       // bool
extern NSString * const PRDefaultsShuffle;                      // bool
extern NSString * const PRDefaultsHogOutput;                    // bool

extern NSString * const PRDefaultsEQCustomArray;                // @[PREQ]
extern NSString * const PRDefaultsEQIsCustom;                   // bool
extern NSString * const PRDefaultsEQIndex;                      // int
extern NSString * const PRDefaultsEQEnabled;                    // bool

extern NSString * const PRDefaultsShowWelcomeSheet;             // bool
extern NSString * const PRDefaultsShowArtwork;                  // bool
extern NSString * const PRDefaultsMiniPlayer;                   // bool
extern NSString * const PRDefaultsMiniPlayerFrame;              // NSRect
extern NSString * const PRDefaultsPlayerFrame;                  // NSRect
extern NSString * const PRDefaultsSidebarWidth;                 // float
extern NSString * const PRDefaultsNowPlayingCollapseState;      // NSIndexSet

extern NSString * const PRDefaultsMediaKeys;                    // bool
extern NSString * const PRDefaultsPostGrowl;                    // bool
extern NSString * const PRDefaultsLastFMUsername;               // NSString
extern NSString * const PRDefaultsUseCompilation;               // bool
extern NSString * const PRDefaultsFolderArtwork;                // bool

extern NSString * const PRDefaultsMonitoredFolders;				// @[NSString]
extern NSString * const PRDefaultsLastEventStreamEventId;		// FSEventStreamEventId




@interface PRUserDefaults : NSObject {
	NSUserDefaults *defaults;
    NSMutableDictionary *_handlers; // @{key:@[PRDefaultsHandlerGet, PRDefaultsHandlerSet], ...}
}
/* Initialization */
+ (PRUserDefaults *)userDefaults;

/* Accessors */
- (id)valueForKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;

/* Accessors */
@property (readwrite) float volume;
@property (readwrite) float preGain;
@property (readwrite) BOOL repeat;
@property (readwrite) BOOL shuffle;
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


@interface PRUserDefaults ()
- (void)setKeyMask:(unsigned int)mask keyCode:(int)code forHotKey:(int)hotKey;
- (void)keyMask:(unsigned int *)mask keyCode:(int *)code forHotKey:(int)hotKey;
@end
