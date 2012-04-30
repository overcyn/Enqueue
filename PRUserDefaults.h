#import <Cocoa/Cocoa.h>


@interface PRUserDefaults : NSObject {
	NSUserDefaults *defaults;
}
/* Initialization */
+ (PRUserDefaults *)userDefaults;

/* Accessors */
@property (readwrite) float volume;
@property (readwrite) BOOL repeat;
@property (readwrite) BOOL shuffle;
@property (readwrite) float preGain;
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
@property (readwrite) BOOL nowPlayingCollapsible;
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