#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRRecorderControl.h>
#import <Carbon/Carbon.h>

@class PRDb, PRNowPlayingController, PRFolderMonitor, PRGradientView, PRCore;

typedef enum {
    PRGeneralPrefMode,
    PRPlaybackPrefMode,
    PRShortcutsPrefMode,
    PRLastfmPrefMode,
} PRPrefMode;

@interface PRPreferencesViewController : NSViewController <NSTableViewDataSource, NSMenuDelegate>
{
    IBOutlet NSView *background;
    IBOutlet PRGradientView *divider;
    IBOutlet NSButton *_generalButton;
    IBOutlet NSButton *_playbackButton;
    IBOutlet NSButton *_shortcutsButton;
    IBOutlet NSButton *_lastfmButton;
    IBOutlet NSView *_generalView;
    IBOutlet NSView *_playbackView;
    IBOutlet NSView *_shortcutsView;
    IBOutlet NSView *_lastfmView;
    IBOutlet NSView *_contentView;
    
    IBOutlet PRGradientView *_topBorder;
    IBOutlet PRGradientView *_generalBorder;
    IBOutlet PRGradientView *_playbackBorder;
    IBOutlet PRGradientView *_shortcutsBorder;
    IBOutlet PRGradientView *_lastfmBorder;
    
    IBOutlet NSButton *sortWithAlbumArtist;
    IBOutlet NSButton *folderArtwork;
    IBOutlet NSButton *_compilationsButton;
    
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
    IBOutlet NSButton *rescan;
    
    IBOutlet NSButton *button1;
    IBOutlet NSTextField *textField;
    
    IBOutlet NSPopUpButton *masterVolumePopUpButton;
    
    // EQ
    IBOutlet NSButton *EQButton;
    IBOutlet NSPopUpButton *EQPopUp;
    IBOutlet NSSlider *_EQPreampSlider;
    IBOutlet NSSlider *_EQ32Slider;
    IBOutlet NSSlider *_EQ64Slider;
    IBOutlet NSSlider *_EQ128Slider;
    IBOutlet NSSlider *_EQ256Slider;
    IBOutlet NSSlider *_EQ512Slider;
    IBOutlet NSSlider *_EQ1kSlider;
    IBOutlet NSSlider *_EQ2kSlider;
    IBOutlet NSSlider *_EQ4kSlider;
    IBOutlet NSSlider *_EQ8kSlider;
    IBOutlet NSSlider *_EQ16kSlider;
    IBOutlet NSTextField *_EQSaveTextField;
    
    IBOutlet PRGradientView *_EQDivider1;
    IBOutlet PRGradientView *_EQDivider2;
    IBOutlet PRGradientView *_EQDivider3;
    IBOutlet PRGradientView *_EQDivider4;
    IBOutlet PRGradientView *_EQDivider5;
    IBOutlet PRGradientView *_EQDivider6;
    IBOutlet PRGradientView *_EQDivider7;
    IBOutlet PRGradientView *_EQDivider8;
    IBOutlet PRGradientView *_EQDivider9;
    
    IBOutlet NSMenu *EQMenu;
    
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
    
    PRPrefMode _prefMode;
    
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
// Tabs

- (NSDictionary *)tabs;
- (NSDictionary *)tabInfo;
- (void)tabAction:(id)sender;

// ========================================
// Update

- (void)updateUI;
- (void)importSheetDidEnd:(NSOpenPanel*)openPanel 
			   returnCode:(NSInteger)returnCode 
				  context:(void*)context;

// ========================================
// Equalizer

- (NSDictionary *)EQSliders;
- (void)EQButtonAction;
- (void)EQSliderAction:(id)sender;
- (void)EQViewUpdate;

- (void)EQMenuActionSave:(id)sender;
- (void)EQMenuActionDelete:(id)sender;
- (void)EQMenuActionCustom:(id)sender;
- (void)EQMenuActionDefault:(id)sender;

// ========================================
// Misc Preferences

- (void)setMasterVolume:(id)sender;
- (void)toggleCompilations;
- (void)toggleUseAlbumArtist;
- (void)toggleMediaKeys;
- (void)toggleFolderArtwork;

// ========================================
// Folder Monitoring

- (void)addFolder;
- (void)removeFolder;
- (void)rescan;

// ========================================
// Global Hotkeys

- (NSArray *)hotkeyDictionary;
- (void)registerHotkeys;
- (void)registerHotkey:(EventHotKeyRef *)hotKeyRef withKeyMasks:(int)keymasks code:(int)code ID:(int)id_;
- (void)rateCurrentSong:(int)rating;

@end


OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData);