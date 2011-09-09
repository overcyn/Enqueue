#import <Cocoa/Cocoa.h>


// ========================================
// Constants 

extern NSString * const PRPreGainDidChangeNotification;
extern NSString * const PRUseAlbumArtistDidChangeNotification;

// ========================================
// PRUserDefaults
// ========================================
@interface PRUserDefaults : NSObject 
{
	NSUserDefaults *defaults;
}

// ========================================
// Initialization

+ (PRUserDefaults *)userDefaults;

// ========================================
// Accessors

@property (readwrite) float volume;
@property (readwrite) BOOL repeat;
@property (readwrite) BOOL shuffle;
@property (readwrite) float preGain;

@property (readwrite) BOOL showWelcomeSheet;
@property (readwrite) BOOL showsArtwork;
@property (readwrite) BOOL useAlbumArtist;
@property (readwrite) BOOL nowPlayingCollapsible;
@property (readwrite) BOOL folderArtwork;

@property (readwrite) BOOL mediaKeys;
@property (readwrite) BOOL postGrowlNotification;
@property (readwrite, retain) NSString *lastFMUsername;

@property (readwrite, retain) NSArray *monitoredFolders;
@property (readwrite) FSEventStreamEventId lastEventStreamEventId;

@property (readonly) NSString *applicationSupportPath;
@property (readonly) NSString *libraryPath;
@property (readonly) NSString *backupPath;
@property (readonly) NSString *cachedAlbumArtPath;
@property (readonly) NSString *downloadedAlbumArtPath;

@end