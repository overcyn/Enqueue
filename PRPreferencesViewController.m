#import "PRPreferencesViewController.h"
#import "PRCore.h"
#import "PRDb.h"
#import "PREQ.h"
#import "PRFolderMonitor.h"
#import "PRGradientView.h"
#import "PRHotKeyController.h"
#import "PRLastfm.h"
#import "PRMoviePlayer.h"
#import "PRNowPlayingController.h"
#import "PRScrollView.h"
#import "PRTabButtonCell.h"
#import "PRDefaults.h"
#import "NSColor+Extensions.h"
#import "NSScrollView+Extensions.h"
#import <Carbon/Carbon.h>
#import <ShortcutRecorder/SRRecorderControl.h>

@implementation PRPreferencesViewController

@synthesize db;
@synthesize now;

#pragma mark - Initialization

- (id)initWithCore:(PRCore *)core_ {
    if (!(self = [super initWithNibName:@"PRPreferencesView" bundle:nil])) {return nil;}
    core = core_;
    db = [core db];
    now = [core now];
    folderMonitor = [core folderMonitor];

    // hotkeys
    for (NSDictionary *i in [self hotkeyDictionary]) {
        NSDictionary *hotkey = @{@"code":[i objectForKey:@"defaultCode"],@"keyMask":[i objectForKey:@"defaultKeyMask"]};
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{[i objectForKey:@"userDefaultsKey"]:hotkey}];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [masterVolumePopUpButton setEnabled:FALSE];
    [masterVolumePopUpButton setTarget:self];
    [masterVolumePopUpButton setAction:@selector(setMasterVolume:)];
    int tag;
    switch ((int)[[PRDefaults sharedDefaults] floatValueForKey:PRDefaultsPregain]) {
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
    
    // Global Hotkeys
    for (NSDictionary *i in [self hotkeyDictionary]) {
        SRRecorderControl *recorder;
        switch ([[i objectForKey:@"ID"] intValue]) {
            case 1:
                recorder = playPause;
                break;
            case 2:
                recorder = playNext;
                break;
            case 3:
                recorder = playPrevious;
                break;
            case 4:
                recorder = increaseVolume;
                break;
            case 5:
                recorder = decreaseVolume;
                break;
            case 6:
                recorder = rate1Star;
                break;
            case 7:
                recorder = rate2Star;
                break;
            case 8:
                recorder = rate3Star;
                break;
            case 9:
                recorder = rate4Star;
                break;
            case 10:
                recorder = rate5Star;
                break;
            default:
                recorder = nil;
                break;
        }
        
        NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[i objectForKey:@"userDefaultsKey"]];
        KeyCombo keyCombo;
        keyCombo.flags = 0;
        if ([[defaults objectForKey:@"keyMask"] intValue] & cmdKey) {
            keyCombo.flags += NSCommandKeyMask;
        }
        if ([[defaults objectForKey:@"keyMask"] intValue] & optionKey) {
            keyCombo.flags += NSAlternateKeyMask;
        }
        if ([[defaults objectForKey:@"keyMask"] intValue] & controlKey) {
            keyCombo.flags += NSControlKeyMask;
        }
        keyCombo.code = [[defaults objectForKey:@"code"] intValue];
        [recorder setKeyCombo:keyCombo];
    }
    
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
    for (NSNumber *i in [[self tabs] allKeys]) {
        NSButton *tab = [[self tabs] objectForKey:i];
        [tab setTarget:self];
        [tab setAction:@selector(tabAction:)];
        [tab setTag:[i intValue]];
    }
    _prefMode = PRGeneralPrefMode;
    [(PRTabButtonCell *)[_generalButton cell] setRounded:TRUE];
    [(PRTabButtonCell *)[_shortcutsButton cell] setRounded:TRUE];
    
    // EQ
    [EQButton setTarget:self];
    [EQButton setAction:@selector(EQButtonAction)];
    EQMenu = [[NSMenu alloc] init];
    [EQMenu setDelegate:self];
    [EQMenu setAutoenablesItems:FALSE];
    [EQPopUp setMenu:EQMenu];
    [[NSNotificationCenter defaultCenter] observeEQChanged:self sel:@selector(EQViewUpdate)];
    
    for (PRGradientView *i in @[_EQDivider1, _EQDivider2, _EQDivider3,
         _EQDivider4, _EQDivider5, _EQDivider6, 
         _EQDivider7, _EQDivider8, _EQDivider9]) {
        [i setTopBorder:[NSColor PRGridColor]];
        [i setBotBorder:[NSColor PRGridHighlightColor]];
    }
    
    for (PRGradientView *i in [NSArray arrayWithObjects:
                               _generalBorder, _playbackBorder, 
                               _shortcutsBorder, _lastfmBorder, _topBorder, nil]) {
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
    [folderMonitor addObserver:self forKeyPath:@"monitoredFolders" options:0 context:nil];
    
	[NSNotificationCenter addObserver:self selector:@selector(updateUI) name:PRLastfmStateDidChangeNotification object:nil];
    [NSNotificationCenter addObserver:self selector:@selector(updateUI) name:PRHogOutputDidChangeNotification object:nil];
    
    [self updateUI];
}

- (void)dealloc {
	[NSNotificationCenter removeObserver:self];
	[super dealloc];
}

#pragma mark - Tabs

- (NSDictionary *)tabs {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _generalButton, [NSNumber numberWithInt:PRGeneralPrefMode], 
            _playbackButton, [NSNumber numberWithInt:PRPlaybackPrefMode],
            _shortcutsButton, [NSNumber numberWithInt:PRShortcutsPrefMode],
            _lastfmButton, [NSNumber numberWithInt:PRLastfmPrefMode], nil];
}

- (NSDictionary *)tabInfo {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDictionary dictionaryWithObjectsAndKeys:
             _generalButton, @"tab", 
             _generalView, @"view",
             [NSNumber numberWithFloat:231], @"height", nil], [NSNumber numberWithInt:PRGeneralPrefMode], 
            [NSDictionary dictionaryWithObjectsAndKeys:
             _playbackButton, @"tab", 
             _playbackView, @"view",
             [NSNumber numberWithFloat:269], @"height", nil], [NSNumber numberWithInt:PRPlaybackPrefMode], 
            [NSDictionary dictionaryWithObjectsAndKeys:
             _shortcutsButton, @"tab", 
             _shortcutsView, @"view",
             [NSNumber numberWithFloat:183], @"height", nil], [NSNumber numberWithInt:PRShortcutsPrefMode], 
            [NSDictionary dictionaryWithObjectsAndKeys:
             _lastfmButton, @"tab", 
             _lastfmView, @"view",
             [NSNumber numberWithFloat:84], @"height", nil], [NSNumber numberWithInt:PRLastfmPrefMode], 
            nil];
}

- (void)tabAction:(id)sender {
    _prefMode = [sender tag];
    [self updateUI];
}

#pragma mark - Update

- (void)updateUI {
    // Tabs
    for (NSNumber *i in [[self tabs] allKeys]) {
        NSButton *tab = [[self tabs] objectForKey:i];
        NSView *view = [[[self tabInfo] objectForKey:i] objectForKey:@"view"];
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
    [_compilationsButton setState:[[PRDefaults sharedDefaults] useCompilation]];
    [sortWithAlbumArtist setState:[[PRDefaults sharedDefaults] useAlbumArtist]];
    [mediaKeys setState:[[PRDefaults sharedDefaults] mediaKeys]];
    [folderArtwork setState:[[PRDefaults sharedDefaults] folderArtwork]];
    [_hogButton setState:[[PRDefaults sharedDefaults] hogOutput]];
    
    // Folders
    [foldersTableView reloadData];
    
    // EQ
    BOOL EQIsEnabled = [[PRDefaults sharedDefaults] EQIsEnabled];
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
        case PRLastfmConnectedState:;
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSFont systemFontOfSize:13], NSFontAttributeName, nil];
            NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSFont boldSystemFontOfSize:13], NSFontAttributeName, nil];
            NSMutableAttributedString *lastfmString = [[[NSMutableAttributedString alloc] initWithString:@"Signed in to Last.fm as " 
                                                                                              attributes:attributes] autorelease];
            NSAttributedString *username = [[[NSAttributedString alloc] initWithString:[[PRDefaults sharedDefaults] lastFMUsername]
                                                                            attributes:attributes2] autorelease];
            NSAttributedString *closing = [[[NSAttributedString alloc] initWithString:@"."
                                                                        attributes:attributes] autorelease];
            [lastfmString appendAttributedString:username];
            [lastfmString appendAttributedString:closing];
            [_lastfmConnectField setAttributedStringValue:lastfmString];
            [_lastfmConnectButton setTitle:@"Logout"];
            [_lastfmConnectButton setAction:@selector(disconnect)];
            break;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == folderMonitor && [keyPath isEqualToString:@"monitoredFolders"]) {
        [self updateUI];
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
    [[PRDefaults sharedDefaults] setEQIsEnabled:([EQButton state] == NSOnState)];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQSliderAction:(id)sender {
    float amp = [(NSSlider *)sender floatValue];
    PREQFreq freq = [[[[self EQSliders] allKeysForObject:sender] objectAtIndex:0] intValue];
    int EQIndex = [[PRDefaults sharedDefaults] EQIndex];
    BOOL isCustom = [[PRDefaults sharedDefaults] isCustomEQ];
    NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRDefaults sharedDefaults] customEQs]];
    
    PREQ *EQ;
    if (isCustom) {
        EQ = [customEQs objectAtIndex:EQIndex];
        [EQ setAmp:amp forFreq:freq];
        [[PRDefaults sharedDefaults] setCustomEQs:customEQs];
    } else {
        EQ = [[PREQ defaultEQs] objectAtIndex:EQIndex];
        [EQ setAmp:amp forFreq:freq];
        [EQ setTitle:@"Custom"];
        [customEQs replaceObjectAtIndex:0 withObject:EQ];
        [[PRDefaults sharedDefaults] setCustomEQs:customEQs];
        [[PRDefaults sharedDefaults] setIsCustomEQ:TRUE];
        [[PRDefaults sharedDefaults] setEQIndex:0];
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
         int EQIndex = [[PRDefaults sharedDefaults] EQIndex];
         BOOL isCustom = [[PRDefaults sharedDefaults] isCustomEQ];
         NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRDefaults sharedDefaults] customEQs]];
         
         PREQ *newEQ;
         if (isCustom) {
             newEQ = [PREQ EQWithEQ:[customEQs objectAtIndex:EQIndex]];
         } else {
             newEQ = [PREQ EQWithEQ:[[PREQ defaultEQs] objectAtIndex:EQIndex]];
         }
         [newEQ setTitle:[_EQSaveTextField stringValue]];
         [customEQs addObject:newEQ];
         [[PRDefaults sharedDefaults] setCustomEQs:customEQs];
         [[PRDefaults sharedDefaults] setEQIndex:[customEQs count]-1];
         [[PRDefaults sharedDefaults] setIsCustomEQ:TRUE];
         [[NSNotificationCenter defaultCenter] postEQChanged];

     } else if ( result == NSAlertSecondButtonReturn ) {  // Accessory view: handle user-specified data
         // "Cancel"
         [self EQViewUpdate];
     }
     [alert release];
}

- (void)EQMenuActionDelete:(id)sender {
    int EQIndex = [[PRDefaults sharedDefaults] EQIndex];
    BOOL isCustom = [[PRDefaults sharedDefaults] isCustomEQ];
    NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRDefaults sharedDefaults] customEQs]];
    
    if (!isCustom || EQIndex == 0) {
        return;
    }
    
    [customEQs removeObjectAtIndex:EQIndex];
    [[PRDefaults sharedDefaults] setCustomEQs:customEQs];
    [[PRDefaults sharedDefaults] setEQIndex:0];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionCustom:(id)sender {
    [[PRDefaults sharedDefaults] setIsCustomEQ:TRUE];
    [[PRDefaults sharedDefaults] setEQIndex:[sender tag]];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionDefault:(id)sender {
    [[PRDefaults sharedDefaults] setIsCustomEQ:FALSE];
    [[PRDefaults sharedDefaults] setEQIndex:[sender tag]];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQViewUpdate {
    int EQIndex = [[PRDefaults sharedDefaults] EQIndex];
    BOOL isCustom = [[PRDefaults sharedDefaults] isCustomEQ];
    PREQ *EQ;
    if (isCustom) {
        EQ = [[[PRDefaults sharedDefaults] customEQs] objectAtIndex:EQIndex];
    } else {
        EQ = [[PREQ defaultEQs] objectAtIndex:EQIndex];
    }
    for (NSNumber *i in [self EQSliders]) {
        NSSlider *slider = [[self EQSliders] objectForKey:i];
        [slider setFloatValue:[EQ ampForFreq:[i intValue]]];
    }
    [self menuNeedsUpdate:EQMenu];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    // clear menu
	for (NSMenuItem *i in [menu itemArray]) {
		[menu removeItem:i];
	}
    
    int EQIndex = [[PRDefaults sharedDefaults] EQIndex];
    BOOL isCustom = [[PRDefaults sharedDefaults] isCustomEQ];
    
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Save..." action:@selector(EQMenuActionSave:) keyEquivalent:@""] autorelease];
    [EQMenu addItem:item];

    item = [[[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(EQMenuActionDelete:) keyEquivalent:@""] autorelease];
    [item setEnabled:(isCustom && EQIndex != 0)];
    [EQMenu addItem:item];
    
    NSMenuItem *selectedItem;
    [EQMenu addItem:[NSMenuItem separatorItem]];
    
    NSArray *customEQs = [[PRDefaults sharedDefaults] customEQs];
    for (int i = 0; i < [customEQs count]; i++) {
        PREQ *EQ = [customEQs objectAtIndex:i];
        item = [[[NSMenuItem alloc] initWithTitle:[EQ title] action:@selector(EQMenuActionCustom:) keyEquivalent:@""] autorelease];
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
        item = [[[NSMenuItem alloc] initWithTitle:[EQ title] action:@selector(EQMenuActionDefault:) keyEquivalent:@""] autorelease];
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
    [[PRDefaults sharedDefaults] setHogOutput:![[PRDefaults sharedDefaults] hogOutput]];
    [NSNotificationCenter post:PRHogOutputDidChangeNotification];
}

- (void)toggleUseAlbumArtist {
    [[PRDefaults sharedDefaults] setUseAlbumArtist:![[PRDefaults sharedDefaults] useAlbumArtist]];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postUseAlbumArtistChanged];
}

- (void)toggleCompilations {
    [[PRDefaults sharedDefaults] setUseCompilation:![[PRDefaults sharedDefaults] useCompilation]];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postUseAlbumArtistChanged];
}

- (void)toggleMediaKeys {
    [[PRDefaults sharedDefaults] setMediaKeys:![[PRDefaults sharedDefaults] mediaKeys]];
    [self updateUI];
}

- (void)toggleFolderArtwork {
    [[PRDefaults sharedDefaults] setFolderArtwork:![[PRDefaults sharedDefaults] folderArtwork]];
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
    [[PRDefaults sharedDefaults] setFloatValue:preGain forKey:PRDefaultsPregain];
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
    [panel beginSheetModalForWindow:[[self view] window]
                  completionHandler:^(NSInteger result){[self importSheetDidEnd:panel returnCode:result context:nil];}];
}

- (void)removeFolder {
    if ([foldersTableView selectedRow] == -1) {
        return;
    }
    [folderMonitor removeFolder:[[folderMonitor monitoredFolders] objectAtIndex:[foldersTableView selectedRow]]];
}

- (void)rescan {
    [folderMonitor rescan];
}

- (void)importSheetDidEnd:(NSOpenPanel*)openPanel returnCode:(NSInteger)returnCode context:(void*)context {
	if (returnCode == NSCancelButton) {
		return;
	}
    for (NSURL *i in [openPanel URLs]) {
        [folderMonitor addFolder:i];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[folderMonitor monitoredFolders] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
    return [[[folderMonitor monitoredFolders] objectAtIndex:rowIndex] path];
}

#pragma mark - Global Hotkeys

#define HOTKEYREFKEY        @"hotKeyRef"
#define IDKEY               @"ID"
#define DEFAULTCODEKEY      @"defaultCode"
#define DEFAULTKEYMASKKEY   @"defaultKeyMask"
#define USERDEFAULTSKEY     @"userDefaultsKey"

- (NSArray *)hotkeyDictionary {
    return @[[NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:1], @"ID",
             [NSNumber numberWithInt:49], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"playPauseHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:2], @"ID",
             [NSNumber numberWithInt:124], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"playNextHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:3], @"ID",
             [NSNumber numberWithInt:123], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"playPreviousHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:4], @"ID",
             [NSNumber numberWithInt:126], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"increaseVolumeHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:5], @"ID",
             [NSNumber numberWithInt:125], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"decreaseVolumeHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:6], @"ID",
             [NSNumber numberWithInt:18], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate1StarHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&rate2StarHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:7], @"ID",
             [NSNumber numberWithInt:19], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate2StarHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:8], @"ID",
             [NSNumber numberWithInt:20], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate3StarHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:9], @"ID",
             [NSNumber numberWithInt:21], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate4StarHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithInt:10], @"ID",
             [NSNumber numberWithInt:23], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate5StarHotKey", @"userDefaultsKey",
             nil]
    ];
}

#pragma mark - SRRecorderControl Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo {    
    int keymask = 0;
    if (newKeyCombo.flags & NSCommandKeyMask) {
        keymask += cmdKey;
    }
    if (newKeyCombo.flags & NSAlternateKeyMask) {
        keymask += optionKey;
    }
    if (newKeyCombo.flags & NSControlKeyMask) {
        keymask += controlKey;
    }
    if (newKeyCombo.flags & NSShiftKeyMask) {
        keymask += shiftKey;
    }
    
    PRHotKey hotKey;
    if (recorder == playPause) {
        hotKey = PRPlayPauseHotKey;
    } else if (recorder == playNext) {
        hotKey = PRNextHotKey;
    } else if (recorder == playPrevious) {
        hotKey = PRPreviousHotKey;
    } else if (recorder == increaseVolume) {
        hotKey = PRIncreaseVolumeHotKey;
    } else if (recorder == decreaseVolume) {
        hotKey = PRDecreaseVolumetHotKey;
    } else if (recorder == rate1Star) {
        hotKey = PRRate1HotKey;
    } else if (recorder == rate2Star) {
        hotKey = PRRate2HotKey;
    } else if (recorder == rate3Star) {
        hotKey = PRRate3HotKey;
    } else if (recorder == rate4Star) {
        hotKey = PRRate4HotKey;
    } else if (recorder == rate5Star) {
        hotKey = PRRate5HotKey;
    } else {
        return;
    }
    [[core hotKeys] setKeymask:keymask code:newKeyCombo.code forHotKey:hotKey];
}

@end
