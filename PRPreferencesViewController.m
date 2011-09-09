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


@implementation PRPreferencesViewController

@synthesize db;
@synthesize now;

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    self = [super initWithNibName:@"PRPreferencesView" bundle:nil];
	if (self) {
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
	}
	return self;
}

- (void)awakeFromNib
{
    [(PRScrollView *)[self view] setMinimumSize:NSMakeSize(650, 804)];
    [(PRScrollView *)[self view] setDocumentView:[background superview]];
    [(NSScrollView *)[self view] scrollToTop];
    
    [divider setColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    [divider2 setColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    [divider3 setColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    [divider4 setColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
    
    // Album artist
    [folderArtwork setTarget:self];
    [folderArtwork setAction:@selector(toggleFolderArtwork)];
    
    [sortWithAlbumArtist setTarget:self];
    [sortWithAlbumArtist setAction:@selector(toggleUseAlbumArtist)];

    [mediaKeys setTarget:self];
    [mediaKeys setAction:@selector(toggleMediaKeys)];
    
    // masterVolume
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
    
    // Folder Monitoring
    [addFolder setTarget:self];
    [addFolder setAction:@selector(addFolder)];
    [removeFolder setTarget:self];
    [removeFolder setAction:@selector(removeFolder)];
    [foldersTableView setDataSource:self];
    [folderMonitor addObserver:self forKeyPath:@"monitoredFolders" options:0 context:nil];
    
    // last.fm
    [[core lastfm] addObserver:self forKeyPath:@"lastfmState" options:0 context:nil];
    [button1 setTarget:self];
    [button1 setAction:@selector(connect)];
    [self updateUI];
}

// ========================================
// Update
// ========================================

- (void)updateUI 
{
    // Misc preferences
    [sortWithAlbumArtist setState:[[PRUserDefaults userDefaults] useAlbumArtist]];
    [mediaKeys setState:[[PRUserDefaults userDefaults] mediaKeys]];
    [folderArtwork setState:[[PRUserDefaults userDefaults] folderArtwork]];
    
    // Folders
    [foldersTableView reloadData];
    
    // last.fm
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
            break;
        case PRLastfmDisconnectedState:
            [textField setStringValue:@"Click below to connect with your Last.fm Account."];
            [button1 setTitle:@"Sign In"];
            break;
        case PRLastfmPendingState:
            [textField setStringValue:@"You will now need to provide authorization in your web browser."];
            [button1 setTitle:@"Cancel"];
            break;
        case PRLastfmValidatingState:
            [textField setStringValue:@"Making authorization request..."];
            [button1 setTitle:@"Cancel"];
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
    } else if (object == [core lastfm] && [keyPath isEqualToString:@"lastfmState"]) {
        [self updateUI];
    }
}

// ========================================
// Misc Preferences
// ========================================

- (void)toggleUseAlbumArtist
{
    [[PRUserDefaults userDefaults] setUseAlbumArtist:![[PRUserDefaults userDefaults] useAlbumArtist]];
    [self updateUI];    
    [[NSNotificationCenter defaultCenter] postNotificationName:PRUseAlbumArtistDidChangeNotification object:nil];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:PRPreGainDidChangeNotification object:nil];
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
	[panel beginSheetForDirectory:nil
							 file:nil 
				   modalForWindow:[[self view] window]
					modalDelegate:self 
				   didEndSelector:@selector(importSheetDidEnd:returnCode:context:)
					  contextInfo:nil];
}

- (void)removeFolder
{
    if ([foldersTableView selectedRow] == -1) {
        return;
    }
    [folderMonitor removeFolder:[[folderMonitor monitoredFolders] objectAtIndex:[foldersTableView selectedRow]]];
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
// Last.fm
// ========================================

- (void)connect
{
    switch ([[core lastfm] lastfmState]) {
        case PRLastfmConnectedState:
            [[core lastfm] disconnect];
            break;
        case PRLastfmDisconnectedState:
            [[core lastfm] connect];
            break;
        case PRLastfmPendingState:
            [[core lastfm] disconnect];
            break;
        case PRLastfmValidatingState:
            [[core lastfm] disconnect];
            break;
        default:
            break;
    }
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
    if (rating < 0 || rating > 100 || [now currentFile] == 0) {
        return;
    }
    [[db library] setValue:[NSNumber numberWithInt:rating] forFile:[now currentFile] attribute:PRRatingFileAttribute];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSArray arrayWithObject:[NSNumber numberWithInt:[now currentFile]]]
                                                         forKey:@"files"];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRTagsDidChangeNotification 
                                                        object:userInfo];
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