#import "PRPreferencesViewController.h"
#import "NSNotificationCenter+Extensions.h"
#import "PRPlaylists.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PREQ.h"
#import "PRFolderMonitor.h"
#import "PRGradientView.h"
#import "PRHotKeyController.h"
#import "PRLastfm.h"
#import "PRMediaKeyController.h"
#import "PRMovie.h"
#import "PRPlayer.h"
#import "PRScrollView.h"
#import "PRTabButtonCell.h"
#import "PRDefaults.h"
#import "NSColor+Extensions.h"
#import "NSScrollView+Extensions.h"
#import <Carbon/Carbon.h>
#import <ShortcutRecorder/SRRecorderControl.h>

@implementation PRPreferencesViewController {
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
    IBOutlet NSMenu *_outputMenu;
    
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
    
    PRPrefMode _prefMode;
    
    __weak PRCore *core;
    __weak PRDb *db;
    __weak PRPlayer *now;
}

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core_ {
    if (!(self = [super initWithNibName:@"PRPreferencesView" bundle:nil])) {return nil;}
    core = core_;
    db = [core db];
    now = [core now];
    return self;
}

- (void)awakeFromNib {
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, 100)];
    [(PRScrollView *)[self view] setDocumentView:[background superview]];
    [(NSScrollView *)[self view] scrollToTop];
    
    [divider setBotBorder2:[NSColor PRTabBorderColor]];
    [divider setBotBorder:[NSColor PRTabBorderHighlightColor]];
    [divider setColor:[NSColor PRTabBackgroundColor]];
        
    // Album artist
    [folderArtwork setTarget:self];
    [folderArtwork setAction:@selector(toggleFolderArtwork)];
    
    [sortWithAlbumArtist setTarget:self];
    [sortWithAlbumArtist setAction:@selector(toggleUseAlbumArtist)];
    
    [_compilationsButton setTarget:self];
    [_compilationsButton setAction:@selector(toggleCompilations)];

    [mediaKeys setTarget:self];
    [mediaKeys setAction:@selector(toggleMediaKeys)];
    
    [_hogButton setTarget:self];
    [_hogButton setAction:@selector(toggleHogOutput)];
    
    // masterVolume
    [masterVolumePopUpButton setEnabled:NO];
    [masterVolumePopUpButton setTarget:self];
    [masterVolumePopUpButton setAction:@selector(setMasterVolume:)];
    int tag;
    switch ((int)[[PRDefaults sharedDefaults] floatForKey:PRDefaultsPregain]) {
        case -10:
            tag = 1;
            break;
        case 0:
            tag = 2;
            break;
        case 10:
            tag = 3;
            break;
        case 20:
            tag = 4;
            break;
        default:
            tag = 2;
            break;
    }
    [masterVolumePopUpButton selectItemWithTag:tag];
    
    // Hotkeys
    [playPause setDelegate:self];
    [playNext setDelegate:self];
    [playPrevious setDelegate:self];
    [increaseVolume setDelegate:self];
    [decreaseVolume setDelegate:self];
    [rate1Star setDelegate:self];
    [rate2Star setDelegate:self];
    [rate3Star setDelegate:self];
    [rate4Star setDelegate:self];
    [rate5Star setDelegate:self];
    
    // Tabs
    for (NSNumber *i in [self tabInfo]) {
        NSButton *tab = [[[self tabInfo] objectForKey:i] objectAtIndex:0];
        [tab setTarget:self];
        [tab setAction:@selector(tabAction:)];
        [tab setTag:[i intValue]];
    }
    _prefMode = PRGeneralPrefMode;
    [(PRTabButtonCell *)[_generalButton cell] setRounded:YES];
    [(PRTabButtonCell *)[_shortcutsButton cell] setRounded:YES];
    
    // EQ
    [EQButton setTarget:self];
    [EQButton setAction:@selector(EQButtonAction)];
    EQMenu = [[NSMenu alloc] init];
    [EQMenu setDelegate:self];
    [EQMenu setAutoenablesItems:NO];
    [EQPopUp setMenu:EQMenu];
    [[NSNotificationCenter defaultCenter] observeEQChanged:self sel:@selector(EQViewUpdate)];
    
    for (PRGradientView *i in @[_EQDivider1, _EQDivider2, _EQDivider3, _EQDivider4, _EQDivider5, _EQDivider6,
         _EQDivider7, _EQDivider8, _EQDivider9, _generalBorder, _playbackBorder, _shortcutsBorder, _topBorder]) {
        [i setTopBorder:[NSColor PRGridColor]];
        [i setBotBorder:[NSColor PRGridHighlightColor]];
    }
    
    [_topBorder setTopBorder:[NSColor PRGridColor]];
    [_topBorder setBotBorder:[NSColor PRGridHighlightColor]];

    for (NSNumber *i in [[self EQSliders] allKeys]) {
        NSSlider *slider = [[self EQSliders] objectForKey:i];
        [slider setTarget:self];
        [slider setAction:@selector(EQSliderAction:)];
        [slider setTag:[i intValue]];
    }
    
    // Folder Monitoring
    [addFolder setTarget:self];
    [addFolder setAction:@selector(addFolder)];
    [removeFolder setTarget:self];
    [removeFolder setAction:@selector(removeFolder)];
    [rescan setTarget:self];
    [rescan setAction:@selector(rescan)];
    [foldersTableView setDataSource:self];
    
    _outputMenu = [[NSMenu alloc] init];
    [_outputMenu setDelegate:self];
    [_outputMenu setAutoenablesItems:NO];
    [_outputPopUp setMenu:_outputMenu];
    
    [NSNotificationCenter addObserver:self selector:@selector(updateUI) name:PRLastfmStateDidChangeNotification object:nil];
    [NSNotificationCenter addObserver:self selector:@selector(updateDeviceMenu) name:PRDeviceDidChangeNotification object:nil];
    
    [self updateUI];
    [self updateDeviceMenu];
    [self updateHotKeys];

}

- (void)dealloc {
    [NSNotificationCenter removeObserver:self];
}

#pragma mark - Tabs

- (NSDictionary *)tabInfo {
    return @{
        [NSNumber numberWithInt:PRGeneralPrefMode]:@[_generalButton, _generalView],
        [NSNumber numberWithInt:PRPlaybackPrefMode]:@[_playbackButton, _playbackView],
        [NSNumber numberWithInt:PRShortcutsPrefMode]:@[_shortcutsButton, _shortcutsView]};
}

- (void)tabAction:(id)sender {
    _prefMode = [sender tag];
    [self updateUI];
}

#pragma mark - Update

- (void)updateUI {
    // Tabs
    NSDictionary *tabInfo = [self tabInfo];
    
    for (NSNumber *i in tabInfo) {
        NSButton *tab = [[tabInfo objectForKey:i] objectAtIndex:0];
        NSView *view = [[tabInfo objectForKey:i] objectAtIndex:1];
        if ([i intValue] == _prefMode) {
            [tab setState:NSOnState];
            [_contentView addSubview:view];
            NSRect frame = [view frame];
            frame.origin = NSMakePoint(0, [_contentView frame].size.height - frame.size.height);
            [view setFrame:frame];
        } else {
            [tab setState:NSOffState];
            [view removeFromSuperview];
        }
    }
    
    // Misc preferences
    [_compilationsButton setState:[[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation]];
    [sortWithAlbumArtist setState:[[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist]];
    [mediaKeys setState:[[core keys] isEnabled]];
    [folderArtwork setState:[[PRDefaults sharedDefaults] boolForKey:PRDefaultsFolderArtwork]];
    [_hogButton setState:[[[core now] movie] hogOutput]];
    
    // Folders
    [foldersTableView reloadData];
    
    // EQ
    BOOL EQIsEnabled = [[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQEnabled];
    for (NSNumber *i in [self EQSliders]) {
        NSSlider *slider = [[self EQSliders] objectForKey:i];
        [slider setEnabled:EQIsEnabled];
    }
    [EQPopUp setEnabled:EQIsEnabled];
    [EQButton setState:EQIsEnabled];
    [_EQPreampSlider setEnabled:EQIsEnabled];
    [self EQViewUpdate];

    
    // last.fm
    [_lastfmConnectButton setTarget:[core lastfm]];
    switch ([[core lastfm] lastfmState]) {
        case PRLastfmConnectedState: {;
            NSMutableAttributedString *lastfmString = [[NSMutableAttributedString alloc] initWithString:@"Signed in to Last.fm as ."
                attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:13]}];
            NSAttributedString *username = [[NSAttributedString alloc] initWithString:[[core lastfm] username]
                attributes:@{NSFontAttributeName:[NSFont boldSystemFontOfSize:13]}];
            [lastfmString insertAttributedString:username atIndex:[lastfmString length]-1];
            [_lastfmConnectField setAttributedStringValue:lastfmString];
            [_lastfmConnectButton setTitle:@"Logout"];
            [_lastfmConnectButton setAction:@selector(disconnect)];
            break;
        }
        case PRLastfmDisconnectedState:
            [_lastfmConnectField setStringValue:@"Click below to connect with your Last.fm Account."];
            [_lastfmConnectButton setTitle:@"Sign In"];
            [_lastfmConnectButton setAction:@selector(connect)];
            break;
        case PRLastfmPendingState:
            [_lastfmConnectField setStringValue:@"You will now need to provide authorization in your web browser."];
            [_lastfmConnectButton setTitle:@"Cancel"];
            [_lastfmConnectButton setAction:@selector(disconnect)];
            break;
        case PRLastfmValidatingState:
            [_lastfmConnectField setStringValue:@"Making authorization request..."];
            [_lastfmConnectButton setTitle:@"Cancel"];
            [_lastfmConnectButton setAction:@selector(disconnect)];
            break;
        default:
            break;
    }
}

#pragma mark - Equalizer

- (NSDictionary *)EQSliders {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _EQ32Slider, [NSNumber numberWithInt:PREQFreq32],
            _EQ64Slider, [NSNumber numberWithInt:PREQFreq64],
            _EQ128Slider, [NSNumber numberWithInt:PREQFreq128],
            _EQ256Slider, [NSNumber numberWithInt:PREQFreq256],
            _EQ512Slider, [NSNumber numberWithInt:PREQFreq512],
            _EQ1kSlider, [NSNumber numberWithInt:PREQFreq1k],
            _EQ2kSlider, [NSNumber numberWithInt:PREQFreq2k],
            _EQ4kSlider, [NSNumber numberWithInt:PREQFreq4k],
            _EQ8kSlider, [NSNumber numberWithInt:PREQFreq8k],
            _EQ16kSlider, [NSNumber numberWithInt:PREQFreq16k],
            _EQPreampSlider, [NSNumber numberWithInt:PREQFreqPreamp],
            nil];
}

- (void)EQButtonAction {
    [[PRDefaults sharedDefaults] setBool:([EQButton state] == NSOnState) forKey:PRDefaultsEQEnabled];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQSliderAction:(id)sender {
    float amp = [(NSSlider *)sender floatValue];
    PREQFreq freq = [[[[self EQSliders] allKeysForObject:sender] objectAtIndex:0] intValue];
    int EQIndex = [[PRDefaults sharedDefaults] intForKey:PRDefaultsEQIndex];
    BOOL isCustom = [[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQIsCustom];
    NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCustomArray]];
    
    PREQ *EQ;
    if (isCustom) {
        EQ = [customEQs objectAtIndex:EQIndex];
        [EQ setAmp:amp forFreq:freq];
        [[PRDefaults sharedDefaults] setValue:customEQs forKey:PRDefaultsEQCustomArray];
    } else {
        EQ = [[PREQ defaultEQs] objectAtIndex:EQIndex];
        [EQ setAmp:amp forFreq:freq];
        [EQ setTitle:@"Custom"];
        [customEQs replaceObjectAtIndex:0 withObject:EQ];
        [[PRDefaults sharedDefaults] setValue:customEQs forKey:PRDefaultsEQCustomArray];
        [[PRDefaults sharedDefaults] setBool:YES forKey:PRDefaultsEQIsCustom];
        [[PRDefaults sharedDefaults] setInt:0 forKey:PRDefaultsEQIndex];
    }
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionSave:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"New equalizer name?"];
    [alert setInformativeText:@"Choose wisely."];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setAccessoryView:_EQSaveTextField];  // Accessory view: "my" accessed via an outlet connection
    [alert layout];
    NSRect frame = [_EQSaveTextField frame];
    [_EQSaveTextField setFrame:frame];

    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        // "Save"
        int EQIndex = [[PRDefaults sharedDefaults] intForKey:PRDefaultsEQIndex];
        BOOL isCustom = [[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQIsCustom];
        NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCustomArray]];

        PREQ *newEQ = isCustom ? [PREQ EQWithEQ:[customEQs objectAtIndex:EQIndex]] : [PREQ EQWithEQ:[[PREQ defaultEQs] objectAtIndex:EQIndex]];
        [newEQ setTitle:[_EQSaveTextField stringValue]];
        [customEQs addObject:newEQ];
        [[PRDefaults sharedDefaults] setValue:customEQs forKey:PRDefaultsEQCustomArray];
        [[PRDefaults sharedDefaults] setInt:[customEQs count]-1 forKey:PRDefaultsEQIndex];
        [[PRDefaults sharedDefaults] setBool:YES forKey:PRDefaultsEQIsCustom];
        [[NSNotificationCenter defaultCenter] postEQChanged];
    }
}

- (void)EQMenuActionDelete:(id)sender {
    int EQIndex = [[PRDefaults sharedDefaults] intForKey:PRDefaultsEQIndex];
    BOOL isCustom = [[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQIsCustom];
    if (!isCustom || EQIndex == 0) {
        return;
    }
    
    NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCustomArray]];
    [customEQs removeObjectAtIndex:EQIndex];
    [[PRDefaults sharedDefaults] setValue:customEQs forKey:PRDefaultsEQCustomArray];
    [[PRDefaults sharedDefaults] setInt:0 forKey:PRDefaultsEQIndex];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionCustom:(id)sender {
    [[PRDefaults sharedDefaults] setBool:YES forKey:PRDefaultsEQIsCustom];
    [[PRDefaults sharedDefaults] setInt:[sender tag] forKey:PRDefaultsEQIndex];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionDefault:(id)sender {
    [[PRDefaults sharedDefaults] setBool:NO forKey:PRDefaultsEQIsCustom];
    [[PRDefaults sharedDefaults] setInt:[sender tag] forKey:PRDefaultsEQIndex];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQViewUpdate {
    int EQIndex = [[PRDefaults sharedDefaults] intForKey:PRDefaultsEQIndex];
    PREQ *EQ;
    if ([[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQIsCustom]) {
        EQ = [[[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCustomArray] objectAtIndex:EQIndex];
    } else {
        EQ = [[PREQ defaultEQs] objectAtIndex:EQIndex];
    }
    for (NSNumber *i in [self EQSliders]) {
        [[[self EQSliders] objectForKey:i] setFloatValue:[EQ ampForFreq:[i intValue]]];
    }
    [self menuNeedsUpdate:EQMenu];
}

- (void)EQMenuNeedsUpdate {
    for (NSMenuItem *i in [EQMenu itemArray]) {
        [EQMenu removeItem:i];
    }
    
    int EQIndex = [[PRDefaults sharedDefaults] intForKey:PRDefaultsEQIndex];
    BOOL isCustom = [[PRDefaults sharedDefaults] boolForKey:PRDefaultsEQIsCustom];
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Save..." action:@selector(EQMenuActionSave:) keyEquivalent:@""];
    [EQMenu addItem:item];

    item = [[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(EQMenuActionDelete:) keyEquivalent:@""];
    [item setEnabled:(isCustom && EQIndex != 0)];
    [EQMenu addItem:item];
    [EQMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *selectedItem = nil;
    NSArray *customEQs = [[PRDefaults sharedDefaults] valueForKey:PRDefaultsEQCustomArray];
    for (int i = 0; i < [customEQs count]; i++) {
        PREQ *EQ = [customEQs objectAtIndex:i];
        item = [[NSMenuItem alloc] initWithTitle:[EQ title] action:@selector(EQMenuActionCustom:) keyEquivalent:@""];
        [item setTag:i];
        [EQMenu addItem:item];
        if (isCustom && i == EQIndex) {
            selectedItem = item;
        }
    }
    [EQMenu addItem:[NSMenuItem separatorItem]];
    
    NSArray *defaultEQs = [PREQ defaultEQs];
    for (int i = 0; i < [defaultEQs count]; i++) {
        PREQ *EQ = [defaultEQs objectAtIndex:i];
        item = [[NSMenuItem alloc] initWithTitle:[EQ title] action:@selector(EQMenuActionDefault:) keyEquivalent:@""];
        [item setTag:i];
        [EQMenu addItem:item];
        if (!isCustom && i == EQIndex) {
            selectedItem = item;
        }
    }
    for (NSMenuItem *i in [EQMenu itemArray]) {
        [i setTarget:self];
    }
    [EQPopUp selectItem:selectedItem];
}

#pragma mark - Misc Preferences

- (void)toggleHogOutput {
    [[[core now] movie] setHogOutput:![[[core now] movie] hogOutput]];
    [self updateUI];
}

- (void)toggleUseAlbumArtist {
    [[PRDefaults sharedDefaults] setBool:![[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseAlbumArtist] forKey:PRDefaultsUseAlbumArtist];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postUseAlbumArtistChanged];
}

- (void)toggleCompilations {
    [[PRDefaults sharedDefaults] setBool:![[PRDefaults sharedDefaults] boolForKey:PRDefaultsUseCompilation] forKey:PRDefaultsUseCompilation];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postUseAlbumArtistChanged];
}

- (void)toggleMediaKeys {
    [[core keys] setEnabled:![[core keys] isEnabled]];
    [self updateUI];
}

- (void)toggleFolderArtwork {
    [[PRDefaults sharedDefaults] setBool:![[PRDefaults sharedDefaults] boolForKey:PRDefaultsFolderArtwork]
                                       forKey:PRDefaultsFolderArtwork];
    [self updateUI];
}

- (void)setMasterVolume:(id)sender {
    float preGain;
    switch ([[sender selectedItem] tag]) {
        case 1:
            preGain = -10;
            break;
        case 2:
            preGain = 0;
            break;
        case 3:
            preGain = 10;
            break;
        case 4:
            preGain = 20;
            break;
        default:
            preGain = 0;
            break;
    }
    [[PRDefaults sharedDefaults] setFloat:preGain forKey:PRDefaultsPregain];
    [[NSNotificationCenter defaultCenter] postPreGainChanged];
}

#pragma mark - Folder Monitoring

- (void)addFolder {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:NO];
    [panel setTreatsFilePackagesAsDirectories:NO];
    [panel setAllowsMultipleSelection:YES];
    [panel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result){
        if (result == NSCancelButton) {
            return;
        }
        for (NSURL *i in [panel URLs]) {
            [[core folderMonitor] addFolder:i];
        }
        [self updateUI];
    }];
}

- (void)removeFolder {
    if ([foldersTableView selectedRow] == -1) {
        return;
    }
    [[core folderMonitor] removeFolder:[[[core folderMonitor] monitoredFolders] objectAtIndex:[foldersTableView selectedRow]]];
    [self updateUI];
}

- (void)rescan {
    [[core folderMonitor] rescan];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[[core folderMonitor] monitoredFolders] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    return [[[[core folderMonitor] monitoredFolders] objectAtIndex:rowIndex] path];
}

#pragma mark - Devices

- (void)updateDeviceMenu {
    for (NSMenuItem *i in [_outputMenu itemArray]) {
        [_outputMenu removeItem:i];
    }
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"System Default" action:@selector(setDevice:) keyEquivalent:@""];
    NSMenuItem *selectedItem = item;
    [item setRepresentedObject:nil];
    [_outputMenu addItem:item];
    [_outputMenu addItem:[NSMenuItem separatorItem]];
    
    NSString *currentDevice = [[[core now] movie] currentDevice];
    for (NSDictionary *i in [[[core now] movie] devices]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[i objectForKey:PRDeviceKeyName] action:@selector(setDevice:) keyEquivalent:@""];
        [item setRepresentedObject:[i objectForKey:PRDeviceKeyUID]];
        [_outputMenu addItem:item];
        if ([[i objectForKey:PRDeviceKeyUID] isEqualToString:currentDevice]) {
            selectedItem = item;
        }
    }
    
    for (NSMenuItem *i in [_outputMenu itemArray]) {
        [i setTarget:self];
    }
    [_outputPopUp selectItem:selectedItem];
}

- (void)setDevice:(id)sender {
    [[[core now] movie] setCurrentDevice:[sender representedObject]];
}

#pragma mark - HotKeys

- (NSDictionary *)hotKeyDictionary {
    return @{
        [NSNumber numberWithInt:PRPlayPauseHotKey]:playPause,
        [NSNumber numberWithInt:PRNextHotKey]:playNext,
        [NSNumber numberWithInt:PRPreviousHotKey]:playPrevious,
        [NSNumber numberWithInt:PRIncreaseVolumeHotKey]:increaseVolume,
        [NSNumber numberWithInt:PRDecreaseVolumeHotKey]:decreaseVolume,
        [NSNumber numberWithInt:PRRate1HotKey]:rate1Star,
        [NSNumber numberWithInt:PRRate2HotKey]:rate2Star,
        [NSNumber numberWithInt:PRRate3HotKey]:rate3Star,
        [NSNumber numberWithInt:PRRate4HotKey]:rate4Star,
        [NSNumber numberWithInt:PRRate5HotKey]:rate5Star};
}

- (void)updateHotKeys {
    NSDictionary *dict = [self hotKeyDictionary];
    for (NSNumber *i in dict) {
        unsigned int mask;
        int code;
        [[core hotKeys] mask:&mask code:&code forHotKey:[i intValue]];
        
        KeyCombo keyCombo;
        keyCombo.flags = 0;
        keyCombo.code = code;
        if (mask & cmdKey) {
            keyCombo.flags += NSCommandKeyMask;
        }
        if (mask & optionKey) {
            keyCombo.flags += NSAlternateKeyMask;
        }
        if (mask & controlKey) {
            keyCombo.flags += NSControlKeyMask;
        }
        if (mask & shiftKey) {
            keyCombo.flags += NSShiftKeyMask;
        }
        [[dict objectForKey:i] setKeyCombo:keyCombo];
    }
}

#pragma mark - SRRecorderControl Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {
    int mask = 0;
    if (newKeyCombo.flags & NSCommandKeyMask) {
        mask += cmdKey;
    }
    if (newKeyCombo.flags & NSAlternateKeyMask) {
        mask += optionKey;
    }
    if (newKeyCombo.flags & NSControlKeyMask) {
        mask += controlKey;
    }
    if (newKeyCombo.flags & NSShiftKeyMask) {
        mask += shiftKey;
    }
    
    NSDictionary *dict = [self hotKeyDictionary];
    for (NSNumber *i in dict) {
        if ([dict objectForKey:i] == recorder) {
            [[core hotKeys] setMask:mask code:newKeyCombo.code forHotKey:[i intValue]];
        }
    }
}

#pragma mark - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == EQMenu) {
        [self EQMenuNeedsUpdate];
    } else if (menu == _outputMenu) {
        [self updateDeviceMenu];
    }
}

@end
