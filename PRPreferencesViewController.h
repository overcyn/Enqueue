#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRRecorderControl.h>
#import <Carbon/Carbon.h>

@class PRDb, PRNowPlayingController, PRFolderMonitor, PRGradientView, PRCore;

@interface PRPreferencesViewController : NSViewController <NSTableViewDataSource>
{
    IBOutlet NSView *background;
    IBOutlet PRGradientView *divider;
    IBOutlet PRGradientView *divider2;
    IBOutlet PRGradientView *divider3;
    IBOutlet PRGradientView *divider4;
    
    IBOutlet NSButton *sortWithAlbumArtist;
    
    IBOutlet NSButton *mediaKeys;
    IBOutlet SRRecorderControl *playPause;
    IBOutlet SRRecorderControl *playNext;
    IBOutlet SRRecorderControl *playPrevious;
    IBOutlet SRRecorderControl *increaseVolume;
    IBOutlet SRRecorderControl *decreaseVolume;
    IBOutlet SRRecorderControl *rate1Star;
    IBOutlet SRRecorderControl *rate2Star;
    IBOutlet SRRecorderControl *rate3Star;
    IBOutlet SRRecorderControl *rate4Star;
    IBOutlet SRRecorderControl *rate5Star;
    
    IBOutlet NSTableView *foldersTableView;
    IBOutlet NSButton *addFolder;
    IBOutlet NSButton *removeFolder;
    
    IBOutlet NSButton *button1;
    IBOutlet NSTextField *textField;
    
    IBOutlet NSPopUpButton *masterVolumePopUpButton;
    
    EventHotKeyRef playPauseHotKeyRef;
    EventHotKeyRef playNextHotKeyRef;
    EventHotKeyRef playPreviousHotKeyRef;
    EventHotKeyRef increaseVolumeHotKeyRef;
    EventHotKeyRef decreaseVolumeHotKeyRef;
    EventHotKeyRef rate1StarHotKeyRef;
    EventHotKeyRef rate2StarHotKeyRef;
    EventHotKeyRef rate3StarHotKeyRef;
    EventHotKeyRef rate4StarHotKeyRef;
    EventHotKeyRef rate5StarHotKeyRef;
    
    PRCore *core;
    PRDb *db;
    PRNowPlayingController *now;
    PRFolderMonitor *folderMonitor;
}

@property (readonly) PRDb *db;
@property (readonly) PRNowPlayingController *now;

// ========================================
// Initialization

- (id)initWithCore:(PRCore *)core;

// ========================================
// Update

- (void)updateUI;

// ========================================
// Misc Preferences

- (void)setMasterVolume:(id)sender;
- (void)toggleUseAlbumArtist;
- (void)toggleMediaKeys;

// ========================================
// Folder Monitoring

- (void)addFolder;
- (void)removeFolder;

// ========================================
// Lastfm

- (void)connect;

// ========================================
// Global Hotkeys

- (NSArray *)hotkeyDictionary;
- (void)registerHotkeys;
- (void)registerHotkey:(EventHotKeyRef *)hotKeyRef withKeyMasks:(int)keymasks code:(int)code ID:(int)id_;
- (void)rateCurrentSong:(int)rating;

@end


OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData);