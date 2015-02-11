#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRRecorderControl.h>
#import <Carbon/Carbon.h>
@class PRDb, PRPlayer, PRGradientView, PRCore;

typedef enum {
    PRGeneralPrefMode,
    PRPlaybackPrefMode,
    PRShortcutsPrefMode,
    PRLastfmPrefMode,
} PRPrefMode;

@interface PRPreferencesViewController : NSViewController <NSTableViewDataSource, NSMenuDelegate>
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
- (void)EQMenuNeedsUpdate;

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

/* Devices */
- (void)updateDeviceMenu;

/* HotKeys */
- (NSDictionary *)hotKeyDictionary;
- (void)updateHotKeys;
@end
