#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRRecorderControl.h>
#import <Carbon/Carbon.h>
@class PRDb, PRNowPlayingController, PRGradientView, PRCore;


typedef enum {
    PRGeneralPrefMode,
    PRPlaybackPrefMode,
    PRShortcutsPrefMode,
    PRLastfmPrefMode,
} PRPrefMode;


@interface PRPreferencesViewController : NSViewController <NSTableViewDataSource, NSMenuDelegate> {
    IBOutlet NSView *background;
    IBOutlet PRGradientView *divider;
    IBOutlet NSButton *_generalButton;
    IBOutlet NSButton *_playbackButton;
    IBOutlet NSButton *_shortcutsButton;
    IBOutlet NSView *_generalView;
    IBOutlet NSView *_playbackView;
    IBOutlet NSView *_shortcutsView;
    IBOutlet NSView *_contentView;
    
    IBOutlet PRGradientView *_topBorder;
    IBOutlet PRGradientView *_generalBorder;
    IBOutlet PRGradientView *_playbackBorder;
    IBOutlet PRGradientView *_shortcutsBorder;
    
    // General
    IBOutlet NSButton *sortWithAlbumArtist;
    IBOutlet NSButton *folderArtwork;
    IBOutlet NSButton *_compilationsButton;
    
    IBOutlet NSTableView *foldersTableView;
    IBOutlet NSButton *addFolder;
    IBOutlet NSButton *removeFolder;
    IBOutlet NSButton *rescan;
    
    IBOutlet NSButton *_lastfmConnectButton;
    IBOutlet NSTextField *_lastfmConnectField;
    
    // Playback
    IBOutlet NSMenu *EQMenu;
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
    
    IBOutlet NSPopUpButton *masterVolumePopUpButton;
    
    IBOutlet NSButton *_hogButton;
    IBOutlet NSPopUpButton *_outputPopUp;
    
    // Shortcuts
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
    
    __weak PRCore *core;
    __weak PRDb *db;
    __weak PRNowPlayingController *now;
}
/* Accessors */
@property (readonly) PRDb *db;
@property (readonly) PRNowPlayingController *now;

/* Initialization */
- (id)initWithCore:(PRCore *)core;

/* Tabs */
- (NSDictionary *)tabInfo;
- (void)tabAction:(id)sender;

/* Update */
- (void)updateUI;

/* Equalizer */
- (NSDictionary *)EQSliders;
- (void)EQButtonAction;
- (void)EQSliderAction:(id)sender;
- (void)EQViewUpdate;

- (void)EQMenuActionSave:(id)sender;
- (void)EQMenuActionDelete:(id)sender;
- (void)EQMenuActionCustom:(id)sender;
- (void)EQMenuActionDefault:(id)sender;

/* Misc Preference */
- (void)setMasterVolume:(id)sender;
- (void)toggleCompilations;
- (void)toggleUseAlbumArtist;
- (void)toggleMediaKeys;
- (void)toggleFolderArtwork;
- (void)toggleHogOutput;

/* Folder Monitoring */
- (void)addFolder;
- (void)removeFolder;
- (void)rescan;

/* HotKeys */
- (NSDictionary *)hotKeyDictionary;
- (void)updateHotKeys;
@end
