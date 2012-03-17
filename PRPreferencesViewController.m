#import "PRPreferencesViewController.h"
#import <Carbon/Carbon.h>
#import <ShortcutRecorder/SRRecorderControl.h>
#import "PRNowPlayingController.h"
#import "PRDb.h"
#import "PRMoviePlayer.h"
#import "PRFolderMonitor.h"
#import "PRScrollView.h"
#import "NSScrollView+Extensions.h"
#import "PRCore.h"
#import "PRLastfm.h"
#import "PRUserDefaults.h"
#import "PRGradientView.h"
#import "NSColor+Extensions.h"
#import "PREQ.h"
#import "PRTabButtonCell.h"

@implementation PRPreferencesViewController

@synthesize db;
@synthesize now;

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    if (!(self = [super initWithNibName:@"PRPreferencesView" bundle:nil])) {return nil;}
    core = core_;
    db = [core db];
    now = [core now];
    folderMonitor = [core folderMonitor];
    
    // monitoring folders
    
    // hotkeys
    for (NSDictionary *i in [self hotkeyDictionary]) {
        NSDictionary *hotkey = [NSDictionary dictionaryWithObjectsAndKeys:
                                [i objectForKey:@"defaultCode"], @"code",
                                [i objectForKey:@"defaultKeyMask"], @"keyMask", nil];
        NSDictionary *defaults = [NSDictionary dictionaryWithObject:hotkey forKey:[i objectForKey:@"userDefaultsKey"]];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self registerHotkeys];
	return self;
}

- (void)awakeFromNib
{
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
    
    // masterVolume
    [masterVolumePopUpButton setEnabled:FALSE];
    [masterVolumePopUpButton setTarget:self];
    [masterVolumePopUpButton setAction:@selector(setMasterVolume:)];
    int tag;
    switch ((int)[[PRUserDefaults userDefaults] preGain]) {
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
    
    for (PRGradientView *i in [NSArray arrayWithObjects:
                               _EQDivider1, _EQDivider2, _EQDivider3,
                               _EQDivider4, _EQDivider5, _EQDivider6, 
                               _EQDivider7, _EQDivider8, _EQDivider9, nil]) {
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
    
    // last.fm
    [[NSNotificationCenter defaultCenter] observeLastfmStateChanged:self sel:@selector(updateUI)];
    [self updateUI];
}

// ========================================
// Tabs
// ======================================== 

- (NSDictionary *)tabs
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _generalButton, [NSNumber numberWithInt:PRGeneralPrefMode], 
            _playbackButton, [NSNumber numberWithInt:PRPlaybackPrefMode],
            _shortcutsButton, [NSNumber numberWithInt:PRShortcutsPrefMode],
            _lastfmButton, [NSNumber numberWithInt:PRLastfmPrefMode], nil];
}

- (NSDictionary *)tabInfo
{
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

- (void)tabAction:(id)sender
{
    _prefMode = [sender tag];
    [self updateUI];
}

// ========================================
// Update
// ======================================== 

- (void)updateUI 
{
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
    [_compilationsButton setState:[[PRUserDefaults userDefaults] useCompilation]];
    [sortWithAlbumArtist setState:[[PRUserDefaults userDefaults] useAlbumArtist]];
    [mediaKeys setState:[[PRUserDefaults userDefaults] mediaKeys]];
    [folderArtwork setState:[[PRUserDefaults userDefaults] folderArtwork]];
    
    // Folders
    [foldersTableView reloadData];
    
    // EQ
    BOOL EQIsEnabled = [[PRUserDefaults userDefaults] EQIsEnabled];
    for (NSNumber *i in [self EQSliders]) {
        NSSlider *slider = [[self EQSliders] objectForKey:i];
        [slider setEnabled:EQIsEnabled];
    }
    [EQPopUp setEnabled:EQIsEnabled];
    [EQButton setState:EQIsEnabled];
    [_EQPreampSlider setEnabled:EQIsEnabled];
    [self EQViewUpdate];

    
    // last.fm
    [button1 setTarget:[core lastfm]];
    switch ([[core lastfm] lastfmState]) {
        case PRLastfmConnectedState:;
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSFont systemFontOfSize:13], NSFontAttributeName, nil];
            NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSFont boldSystemFontOfSize:13], NSFontAttributeName, nil];
            NSMutableAttributedString *lastfmString = [[[NSMutableAttributedString alloc] initWithString:@"Signed in to Last.fm as " 
                                                                                              attributes:attributes] autorelease];
            NSAttributedString *username = [[[NSAttributedString alloc] initWithString:[[PRUserDefaults userDefaults] lastFMUsername]
                                                                            attributes:attributes2] autorelease];
            NSAttributedString *closing = [[[NSAttributedString alloc] initWithString:@"."
                                                                        attributes:attributes] autorelease];
            [lastfmString appendAttributedString:username];
            [lastfmString appendAttributedString:closing];
            [textField setAttributedStringValue:lastfmString];
            [button1 setTitle:@"Logout"];
            [button1 setAction:@selector(disconnect)];
            break;
        case PRLastfmDisconnectedState:
            [textField setStringValue:@"Click below to connect with your Last.fm Account."];
            [button1 setTitle:@"Sign In"];
            [button1 setAction:@selector(connect)];
            break;
        case PRLastfmPendingState:
            [textField setStringValue:@"You will now need to provide authorization in your web browser."];
            [button1 setTitle:@"Cancel"];
            [button1 setAction:@selector(disconnect)];
            break;
        case PRLastfmValidatingState:
            [textField setStringValue:@"Making authorization request..."];
            [button1 setTitle:@"Cancel"];
            [button1 setAction:@selector(disconnect)];
            break;
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if (object == folderMonitor && [keyPath isEqualToString:@"monitoredFolders"]) {
        [self updateUI];
    }
}

// ========================================
// Equalizer
// ========================================

- (NSDictionary *)EQSliders
{
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

- (void)EQButtonAction
{
    [[PRUserDefaults userDefaults] setEQIsEnabled:([EQButton state] == NSOnState)];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQSliderAction:(id)sender
{
    float amp = [(NSSlider *)sender floatValue];
    PREQFreq freq = [[[[self EQSliders] allKeysForObject:sender] objectAtIndex:0] intValue];
    int EQIndex = [[PRUserDefaults userDefaults] EQIndex];
    BOOL isCustom = [[PRUserDefaults userDefaults] isCustomEQ];
    NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRUserDefaults userDefaults] customEQs]];
    
    PREQ *EQ;
    if (isCustom) {
        EQ = [customEQs objectAtIndex:EQIndex];
        [EQ setAmp:amp forFreq:freq];
        [[PRUserDefaults userDefaults] setCustomEQs:customEQs];
    } else {
        EQ = [[PREQ defaultEQs] objectAtIndex:EQIndex];
        [EQ setAmp:amp forFreq:freq];
        [EQ setTitle:@"Custom"];
        [customEQs replaceObjectAtIndex:0 withObject:EQ];
        [[PRUserDefaults userDefaults] setCustomEQs:customEQs];
        [[PRUserDefaults userDefaults] setIsCustomEQ:TRUE];
        [[PRUserDefaults userDefaults] setEQIndex:0];
    }
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionSave:(id)sender
{    
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
         int EQIndex = [[PRUserDefaults userDefaults] EQIndex];
         BOOL isCustom = [[PRUserDefaults userDefaults] isCustomEQ];
         NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRUserDefaults userDefaults] customEQs]];
         
         PREQ *newEQ;
         if (isCustom) {
             newEQ = [PREQ EQWithEQ:[customEQs objectAtIndex:EQIndex]];
         } else {
             newEQ = [PREQ EQWithEQ:[[PREQ defaultEQs] objectAtIndex:EQIndex]];
         }
         [newEQ setTitle:[_EQSaveTextField stringValue]];
         [customEQs addObject:newEQ];
         [[PRUserDefaults userDefaults] setCustomEQs:customEQs];
         [[PRUserDefaults userDefaults] setEQIndex:[customEQs count]-1];
         [[PRUserDefaults userDefaults] setIsCustomEQ:TRUE];
         [[NSNotificationCenter defaultCenter] postEQChanged];

     } else if ( result == NSAlertSecondButtonReturn ) {  // Accessory view: handle user-specified data
         // "Cancel"
         [self EQViewUpdate];
     }
     [alert release];
}

- (void)EQMenuActionDelete:(id)sender
{
    int EQIndex = [[PRUserDefaults userDefaults] EQIndex];
    BOOL isCustom = [[PRUserDefaults userDefaults] isCustomEQ];
    NSMutableArray *customEQs = [NSMutableArray arrayWithArray:[[PRUserDefaults userDefaults] customEQs]];
    
    if (!isCustom || EQIndex == 0) {
        return;
    }
    
    [customEQs removeObjectAtIndex:EQIndex];
    [[PRUserDefaults userDefaults] setCustomEQs:customEQs];
    [[PRUserDefaults userDefaults] setEQIndex:0];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionCustom:(id)sender
{
    [[PRUserDefaults userDefaults] setIsCustomEQ:TRUE];
    [[PRUserDefaults userDefaults] setEQIndex:[sender tag]];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQMenuActionDefault:(id)sender
{
    [[PRUserDefaults userDefaults] setIsCustomEQ:FALSE];
    [[PRUserDefaults userDefaults] setEQIndex:[sender tag]];
    [[NSNotificationCenter defaultCenter] postEQChanged];
}

- (void)EQViewUpdate
{
    int EQIndex = [[PRUserDefaults userDefaults] EQIndex];
    BOOL isCustom = [[PRUserDefaults userDefaults] isCustomEQ];
    PREQ *EQ;
    if (isCustom) {
        EQ = [[[PRUserDefaults userDefaults] customEQs] objectAtIndex:EQIndex];
    } else {
        EQ = [[PREQ defaultEQs] objectAtIndex:EQIndex];
    }
    for (NSNumber *i in [self EQSliders]) {
        NSSlider *slider = [[self EQSliders] objectForKey:i];
        [slider setFloatValue:[EQ ampForFreq:[i intValue]]];
    }
    [self menuNeedsUpdate:EQMenu];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    // clear menu
	for (NSMenuItem *i in [menu itemArray]) {
		[menu removeItem:i];
	}
    
    int EQIndex = [[PRUserDefaults userDefaults] EQIndex];
    BOOL isCustom = [[PRUserDefaults userDefaults] isCustomEQ];
    
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Save..." action:@selector(EQMenuActionSave:) keyEquivalent:@""] autorelease];
    [EQMenu addItem:item];

    item = [[[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(EQMenuActionDelete:) keyEquivalent:@""] autorelease];
    [item setEnabled:(isCustom && EQIndex != 0)];
    [EQMenu addItem:item];
    
    NSMenuItem *selectedItem;
    [EQMenu addItem:[NSMenuItem separatorItem]];
    
    NSArray *customEQs = [[PRUserDefaults userDefaults] customEQs];
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

// ========================================
// Misc Preferences
// ========================================

- (void)toggleUseAlbumArtist
{
    [[PRUserDefaults userDefaults] setUseAlbumArtist:![[PRUserDefaults userDefaults] useAlbumArtist]];
    [self updateUI];    
    [[NSNotificationCenter defaultCenter] postUseAlbumArtistChanged];
}

- (void)toggleCompilations
{
    [[PRUserDefaults userDefaults] setUseCompilation:![[PRUserDefaults userDefaults] useCompilation]];
    [self updateUI];
    [[NSNotificationCenter defaultCenter] postUseAlbumArtistChanged];
}

- (void)toggleMediaKeys
{
    [[PRUserDefaults userDefaults] setMediaKeys:![[PRUserDefaults userDefaults] mediaKeys]];
    [self updateUI];
}

- (void)toggleFolderArtwork
{
    [[PRUserDefaults userDefaults] setFolderArtwork:![[PRUserDefaults userDefaults] folderArtwork]];
    [self updateUI];
}

- (void)setMasterVolume:(id)sender
{
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
    [[PRUserDefaults userDefaults] setPreGain:preGain];
    [[NSNotificationCenter defaultCenter] postPreGainChanged];
}

// ========================================
// Folder Monitoring
// ========================================

- (void)addFolder
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanCreateDirectories:NO];
	[panel setTreatsFilePackagesAsDirectories:NO];
	[panel setAllowsMultipleSelection:YES];
    [panel beginSheetModalForWindow:[[self view] window]
                  completionHandler:^(NSInteger result){[self importSheetDidEnd:panel returnCode:result context:nil];}];
}

- (void)removeFolder
{
    if ([foldersTableView selectedRow] == -1) {
        return;
    }
    [folderMonitor removeFolder:[[folderMonitor monitoredFolders] objectAtIndex:[foldersTableView selectedRow]]];
}

- (void)rescan
{
    [folderMonitor rescan];
}

- (void)importSheetDidEnd:(NSOpenPanel*)openPanel 
			   returnCode:(NSInteger)returnCode 
				  context:(void*)context
{
	if (returnCode == NSCancelButton) {
		return;
	}
    for (NSURL *i in [openPanel URLs]) {
        [folderMonitor addFolder:i];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[folderMonitor monitoredFolders] count];
}

- (id)            tableView:(NSTableView *)tableView 
  objectValueForTableColumn:(NSTableColumn *)tableColumn 
                        row:(NSInteger)rowIndex
{
    return [[[folderMonitor monitoredFolders] objectAtIndex:rowIndex] path];
}

// ========================================
// Global Hotkeys
// ========================================

- (NSArray *)hotkeyDictionary
{
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&playPauseHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:1], @"ID",
             [NSNumber numberWithInt:49], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"playPauseHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&playNextHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:2], @"ID",
             [NSNumber numberWithInt:124], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"playNextHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&playPreviousHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:3], @"ID",
             [NSNumber numberWithInt:123], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"playPreviousHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&increaseVolumeHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:4], @"ID",
             [NSNumber numberWithInt:126], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"increaseVolumeHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&decreaseVolumeHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:5], @"ID",
             [NSNumber numberWithInt:125], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"decreaseVolumeHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&rate1StarHotKeyRef], @"hotKeyRef",
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
             [NSValue valueWithPointer:&rate3StarHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:8], @"ID",
             [NSNumber numberWithInt:20], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate3StarHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&rate4StarHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:9], @"ID",
             [NSNumber numberWithInt:21], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate4StarHotKey", @"userDefaultsKey",
             nil],
            
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSValue valueWithPointer:&rate5StarHotKeyRef], @"hotKeyRef",
             [NSNumber numberWithInt:10], @"ID",
             [NSNumber numberWithInt:23], @"defaultCode",
             [NSNumber numberWithInt:cmdKey+optionKey+controlKey], @"defaultKeyMask",
             @"rate5StarHotKey", @"userDefaultsKey",
             nil],
            
            nil];
}

- (void)registerHotkeys
{
    for (NSDictionary *i in [self hotkeyDictionary]) {
        NSDictionary *defaults = 
          [[NSUserDefaults standardUserDefaults] dictionaryForKey:[i objectForKey:@"userDefaultsKey"]];
        [self registerHotkey:[[i objectForKey:@"hotKeyRef"] pointerValue]
                withKeyMasks:[[defaults objectForKey:@"keyMask"] intValue] 
                        code:[[defaults objectForKey:@"code"] intValue] 
                          ID:[[i objectForKey:@"ID"] intValue]];
    }
}

- (void)registerHotkey:(EventHotKeyRef *)hotKeyRef withKeyMasks:(int)keymasks code:(int)code ID:(int)id_ 
{
    UnregisterEventHotKey(*hotKeyRef);
    if (code == -1) {
        return;
    }
    
    //Register the Hotkeys
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(&MyHotKeyHandler, 1, &eventType, self, NULL);
    
    EventHotKeyID hotKeyID;
    hotKeyID.signature = 's';
    hotKeyID.id = id_;
        
    RegisterEventHotKey(code, // keyboard reference number
                        keymasks, // modifier keys: cmdKey, shiftKey, optionKey, controlKey
                        hotKeyID, GetApplicationEventTarget(), 0, hotKeyRef);
}

// SRRecorderControl Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo
{    
    int keymasks = 0;
    if (newKeyCombo.flags & NSCommandKeyMask) {
        keymasks += cmdKey;
    }
    if (newKeyCombo.flags & NSAlternateKeyMask) {
        keymasks += optionKey;
    }
    if (newKeyCombo.flags & NSControlKeyMask) {
        keymasks += controlKey;
    }
    if (newKeyCombo.flags & NSShiftKeyMask) {
        keymasks += shiftKey;
    }
    
    int ID_;
    if (recorder == playPause) {
        ID_ = 1;
    } else if (recorder == playNext) {
        ID_ = 2;
    } else if (recorder == playPrevious) {
        ID_ = 3;
    } else if (recorder == increaseVolume) {
        ID_ = 4;
    } else if (recorder == decreaseVolume) {
        ID_ = 5;
    } else if (recorder == rate1Star) {
        ID_ = 6;
    } else if (recorder == rate2Star) {
        ID_ = 7;
    } else if (recorder == rate3Star) {
        ID_ = 8;
    } else if (recorder == rate4Star) {
        ID_ = 9;
    } else if (recorder == rate5Star) {
        ID_ = 10;
    } else {
        return;
    }
    for (NSDictionary *i in [self hotkeyDictionary]) {
        if ([[i objectForKey:@"ID"] intValue] == ID_) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              [NSNumber numberWithInt:newKeyCombo.code], @"code",
                                                              [NSNumber numberWithInt:keymasks], @"keyMask", nil]
                                                      forKey:[i objectForKey:@"userDefaultsKey"]];
            continue;
        }
    }
    
    [self registerHotkeys];
}

- (void)rateCurrentSong:(int)rating
{
    if (rating < 0 || rating > 100 || ![now currentItem]) {
        return;
    }
    [[db library] setValue:[NSNumber numberWithInt:rating] forItem:[now currentItem] attr:PRItemAttrRating];
    [[NSNotificationCenter defaultCenter] postItemsChanged:[NSArray arrayWithObject:[now currentItem]]];
}

@end

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData)
{
    PRPreferencesViewController *self_ = userData;
    PRNowPlayingController *now = [self_ now];
    EventHotKeyID hkCom;
    GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
                      sizeof(hkCom),NULL,&hkCom);
    switch (hkCom.id) {
        case 1:
            [now playPause];
            break;
        case 2:
            [now playNext];
            break;
        case 3:
            [now playPrevious];
            break;
        case 4:
            [[now mov] increaseVolume];
            break;
        case 5:
            [[now mov] decreaseVolume];
            break;
        case 6:
            [self_ rateCurrentSong:20];
            break;
        case 7:
            [self_ rateCurrentSong:40];
            break;
        case 8:
            [self_ rateCurrentSong:60];
            break;
        case 9:
            [self_ rateCurrentSong:80];
            break;
        case 10:
            [self_ rateCurrentSong:100];
            break;
    }
    return noErr;
}