#import "PRMainWindowController.h"
#import "PRDb.h"
#import "PRNowPlayingController.h"
#import "PRControlsViewController.h"
#import "PRPlaylists.h"
#import "PRTaskManagerViewController.h"
#import "PRNowPlayingViewController.h"
#import "PRLibraryViewController.h"
#import "PRPreferencesViewController.h"
#import "PRPlaylistsViewController.h"
#import "PRHistoryViewController.h"
#import "PRCore.h"
#import "PRPlaylists+Extensions.h"
#import "PRTaskManager.h"
#import "PRGradientView.h"
#import "PRWelcomeSheetController.h"
#import "PRMainMenuController.h"
#import "PRUserDefaults.h"
#import "PRTimeFormatter2.h"
#import "PRSizeFormatter.h"
#import "YRKSpinningProgressIndicator.h"
#import "PRTableViewController.h"
#import "PRStringFormatter.h"
#import <Quartz/Quartz.h>
#import "NSWindow+Extensions.h"


@interface NSWindow (hush)
- (void)setBottomCornerRounded:(BOOL)rounded;
@end


@implementation PRMainWindowController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core
{
	if (!(self = [super initWithWindowNibName:@"PRMainWindow"])) {return nil;}
    _core = core;
    _db = [core db];
    currentMode = PRLibraryMode;
    currentPlaylist = 0;
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
     
    [mainMenuController release];
    [libraryViewController release];
    [preferencesViewController release];
    [playlistsViewController release];
    [historyViewController release];
    [nowPlayingViewController release];
    [controlsViewController release];
    [super dealloc];
}

- (void)awakeFromNib
{   
    // Main Menu
    mainMenuController = [[PRMainMenuController alloc] initWithCore:_core];
    
	// Window
    [[self window] setDelegate:self];
    [[self window] setBottomCornerRounded:NO];
    
    // Toolbar View
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithCalibratedWhite:0.92 alpha:1.0], 0.0,
                             [NSColor colorWithCalibratedWhite:0.82 alpha:1.0], 0.5,
                             [NSColor colorWithCalibratedWhite:0.77 alpha:1.0], 0.8,
                             [NSColor colorWithCalibratedWhite:0.73 alpha:1.0], 1.0,
                             nil] autorelease];
    [toolbarView setVerticalGradient:gradient];
    gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                 [NSColor colorWithCalibratedWhite:0.99 alpha:1.0], 0.0,
                 [NSColor colorWithCalibratedWhite:0.90 alpha:1.0], 0.5,
                 [NSColor colorWithCalibratedWhite:0.85 alpha:1.0], 1.0,
                 nil] autorelease];
    [toolbarView setAltVerticalGradient:gradient];
    [toolbarView setTopBorder:[NSColor colorWithCalibratedWhite:1.0 alpha:0.42]];
    [toolbarView setBotBorder:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    [toolbarView setFrame:NSMakeRect(185, [[self window] frame].size.height - [toolbarView frame].size.height, 
                                     [[self window] frame].size.width - 185, [toolbarView frame].size.height)];
    [[[[self window] contentView] superview] addSubview:toolbarView];
    
    [mainDivider setColor:[NSColor colorWithCalibratedWhite:0.55 alpha:1.0]];
    [toolbarView setLeftBorder:[NSColor colorWithCalibratedWhite:0.55 alpha:1.0]];
    
    [divider setHidden:TRUE];
    [divider setColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
    [divider setBotBorder:[NSColor colorWithCalibratedWhite:1.0 alpha:0.8]];
    [divider5 setTopBorder:[NSColor colorWithCalibratedWhite:0.0 alpha:0.3]];
    [divider5 setBotBorder:[NSColor colorWithCalibratedWhite:1.0 alpha:0.3]];
    	
    // ViewControllers
    libraryViewController = [[PRLibraryViewController alloc] initWithCore:_core];
    preferencesViewController = [[PRPreferencesViewController alloc] initWithCore:_core];
	playlistsViewController = [[PRPlaylistsViewController alloc] initWithCore:_core];
    historyViewController = [[PRHistoryViewController alloc] initWithDb:_db mainWindowController:self];
    taskManagerViewController = [[PRTaskManagerViewController alloc] initWithTaskManager:[_core taskManager] core:(PRCore *)_core];
    
    nowPlayingViewController = [[PRNowPlayingViewController alloc] initWithDb:_db 
                                                         nowPlayingController:[_core now] 
                                                         mainWindowController:self];
    [[nowPlayingViewController view] setFrame:[nowPlayingSuperview bounds]];
    [nowPlayingSuperview addSubview:[nowPlayingViewController view]];
	
    controlsViewController = [[PRControlsViewController alloc] initWithCore:_core];
    [[controlsViewController view] setFrame:[controlsSuperview bounds]];
    [controlsSuperview addSubview:[controlsViewController view]];
    
    [self setShowsArtwork:[[PRUserDefaults userDefaults] showsArtwork]];
	
    // Initialize currentViewController
    [[libraryViewController view] setFrame:[centerSuperview bounds]];
    [centerSuperview addSubview:[libraryViewController view]];
	currentViewController = libraryViewController;
    [self setCurrentPlaylist:[[_db playlists] libraryPlaylist]];
    [self setCurrentMode:PRLibraryMode];
		
    // Progress Indicator
    [cancelButton setTarget:taskManagerViewController];
    [cancelButton setAction:@selector(cancelTask)];
    [self setProgressHidden:TRUE];
    [self setProgressTitle:@"Scanning for Updates..."];
    
	// Search Field
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"", NSNullPlaceholderBindingOption, nil];
    PRStringFormatter *stringFormatter = [[[PRStringFormatter alloc] init] autorelease];
    [stringFormatter setMaxLength:80];
	[searchField bind:@"value" toObject:self withKeyPath:@"search" options:options];
    [searchField setFormatter:stringFormatter];
    
    // Info button
    [infoButton setTarget:libraryViewController];
    [infoButton setAction:@selector(infoViewToggle)];
    
    // Library view mode buttons
    [libraryModeButton setTarget:self];
    [libraryModeButton setAction:@selector(libraryModeButtonAction)];
	
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
        [[self window] setCollectionBehavior:[[self window] collectionBehavior] | NSWindowCollectionBehaviorFullScreenPrimary];
    }
    
	// Buttons
    NSArray *buttons = [NSArray arrayWithObjects:
                        [NSDictionary dictionaryWithObjectsAndKeys:libraryButton, @"button", [NSNumber numberWithInt:PRLibraryMode], @"tag", nil], 
                        [NSDictionary dictionaryWithObjectsAndKeys:playlistsButton, @"button", [NSNumber numberWithInt:PRPlaylistsMode], @"tag", nil], 
                        [NSDictionary dictionaryWithObjectsAndKeys:historyButton, @"button", [NSNumber numberWithInt:PRHistoryMode], @"tag", nil], 
                        [NSDictionary dictionaryWithObjectsAndKeys:preferencesButton, @"button", [NSNumber numberWithInt:PRPreferencesMode], @"tag", nil], 
                        nil];
    
    for (NSDictionary *i in buttons) {
        NSButton *button = [i objectForKey:@"button"];
        int tag = [[i objectForKey:@"tag"] intValue];
        
        [button setAction:@selector(headerButtonAction:)];
        [button setTarget:self];
        [button setTag:tag];
        [[button cell] setShowsStateBy:NSNoCellMask];
        [[button cell] setHighlightsBy:NSContentsCellMask];
    }
    
	// Update
    [[NSNotificationCenter defaultCenter] observePlaylistChanged:self sel:@selector(playlistDidChange:)];
    [[NSNotificationCenter defaultCenter] observePlaylistsChanged:self sel:@selector(playlistsDidChange:)];
    [[NSNotificationCenter defaultCenter] observeLibraryViewChanged:self sel:@selector(libraryViewDidChange:)];
    [[NSNotificationCenter defaultCenter] observeInfoViewVisibleChanged:self sel:@selector(updateUI)];
    
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(windowWillEnterFullScreen:) 
                                                     name:NSWindowWillEnterFullScreenNotification 
                                                   object:[self window]];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(windowWillExitFullScreen:) 
                                                     name:NSWindowWillExitFullScreenNotification 
                                                   object:[self window]];
    }
}

// ========================================
// Accessors
// ========================================

@synthesize mainMenuController;
@synthesize taskManagerViewController;
@synthesize libraryViewController;
@synthesize historyViewController;
@synthesize playlistsViewController;
@synthesize preferencesViewController;
@synthesize nowPlayingViewController;
@synthesize controlsViewController;

@dynamic currentMode;
@dynamic currentPlaylist;
@dynamic showsArtwork;

- (PRMode)currentMode
{
    return currentMode;
}

- (void)setCurrentMode:(PRMode)mode_
{
    if (currentMode == mode_) {
        return;
    }
    currentMode = mode_;
    id newViewController;
	switch (currentMode) {
		case PRLibraryMode:
			newViewController = libraryViewController;
			break;
		case PRPlaylistsMode:
			newViewController = playlistsViewController;
			break;
		case PRHistoryMode:
			newViewController = historyViewController;
			[historyViewController update];
			break;
		case PRPreferencesMode:
			newViewController = preferencesViewController;
			break;
		default:
            [PRException raise:NSInternalInconsistencyException format:@"Invalid Mode"];return;
			break;
	}
    [[newViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview replaceSubview:[currentViewController view] with:[newViewController view]];
	currentViewController = newViewController;
    [self updateUI];
	[self willChangeValueForKey:@"search"];
	[self didChangeValueForKey:@"search"];
}

- (PRPlaylist)currentPlaylist
{
    return currentPlaylist;
}

- (void)setCurrentPlaylist:(PRPlaylist)playlist_
{
    currentPlaylist = playlist_;
    [libraryViewController setPlaylist:currentPlaylist];
    
    [self updateUI];
    
	[self willChangeValueForKey:@"search"];
	[self didChangeValueForKey:@"search"];
}

- (BOOL)showsArtwork
{
    if ([controlsSuperview frame].size.height == 275 || [controlsSuperview frame].size.height == 286) {
        return TRUE;
    } else {
        return FALSE;
    }
}

- (void)setShowsArtwork:(BOOL)showsArtwork
{
    [[PRUserDefaults userDefaults] setShowsArtwork:showsArtwork];
    if (showsArtwork) {
        NSRect frame = [controlsSuperview frame];
        frame.origin.y = [[self window] frame].size.height - 275 - 22;
        frame.size.height = 275;
        [controlsSuperview setFrame:frame];
        
        frame = [nowPlayingSuperview frame];
        frame.size.height = [[self window] frame].size.height - 275 - 22;
        [nowPlayingSuperview setFrame:frame];
    } else {
        NSRect frame = [controlsSuperview frame];
        frame.origin.y = [[self window] frame].size.height - 105 - 22;
        frame.size.height = 105;
        [controlsSuperview setFrame:frame];
        
        frame = [nowPlayingSuperview frame];
        frame.size.height = [[self window] frame].size.height - 105 - 22;
        [nowPlayingSuperview setFrame:frame];
    }
    [controlsViewController setShowsArtwork:showsArtwork];
}

@dynamic progressHidden;
@dynamic progressTitle;

- (BOOL)progressHidden
{
    return [divider isHidden];
}

- (void)setProgressHidden:(BOOL)progressHidden
{
    [divider setHidden:progressHidden];
    [cancelButton setHidden:progressHidden];
    [progressTextField setHidden:progressHidden];
//    [progressIndicator setHidden:progressHidden];
//    if (progressHidden) {
//        [progressIndicator stopAnimation:nil];
//    } else {
//        [progressIndicator startAnimation:nil];
//    }
}

- (NSString *)progressTitle
{
    return [progressTextField stringValue];
}

- (void)setProgressTitle:(NSString *)progressTitle
{
    NSShadow *shadow2 = [[[NSShadow alloc] init] autorelease];
	[shadow2 setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
	[shadow2 setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSMutableParagraphStyle *centerAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[centerAlign setAlignment:NSLeftTextAlignment];
    [centerAlign setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont systemFontOfSize:11], NSFontAttributeName,
                                 [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                 centerAlign, NSParagraphStyleAttributeName,				  
                                 shadow2, NSShadowAttributeName,
                                 nil];
	NSAttributedString *attributedString = [[[NSAttributedString alloc] initWithString:progressTitle attributes:attributes2] autorelease];
	[progressTextField setAttributedStringValue:attributedString];
}

// ========================================
// UI
// ========================================

- (void)updateUI
{
    // Header buttons
    [libraryButton setImage:[NSImage imageNamed:@"Library"]];
    [playlistsButton setImage:[NSImage imageNamed:@"Playlists"]];
    [historyButton setImage:[NSImage imageNamed:@"History"]];
    [preferencesButton setImage:[NSImage imageNamed:@"Preferences"]];
    [searchField setEnabled:currentMode == PRLibraryMode];
    switch (currentMode) {
		case PRLibraryMode:
            if ([self currentPlaylist] == [[_db playlists] libraryPlaylist]) {
                [libraryButton setImage:[NSImage imageNamed:@"LibraryAlt"]];
            } else {
                [playlistsButton setImage:[NSImage imageNamed:@"PlaylistsAlt"]];
            }
			break;
		case PRPlaylistsMode:
            [playlistsButton setImage:[NSImage imageNamed:@"PlaylistsAlt"]];
			break;
		case PRHistoryMode:
            [historyButton setImage:[NSImage imageNamed:@"HistoryAlt"]];
			break;
		case PRPreferencesMode:
            [preferencesButton setImage:[NSImage imageNamed:@"PreferencesAlt"]];
			break;
		default:
			break;
	}
    
    // Library view mode buttons
    switch ([self libraryViewMode]) {
        case PRListMode:
            [libraryModeButton setSelectedSegment:0];
            break;
        case PRAlbumListMode:
            [libraryModeButton setSelectedSegment:1];
            break;
        default:
            break;
    }
    [infoButton setHidden:(currentMode != PRLibraryMode)];
    [libraryModeButton setHidden:(currentMode != PRLibraryMode)];
    
    if ([libraryViewController infoViewVisible]) {
        [infoButton setImage:[NSImage imageNamed:@"InfoAlt"]];
    } else {
        [infoButton setImage:[NSImage imageNamed:@"Info"]];
    }
    
    // Playlist title
    [playlistTitle setHidden:!(currentMode == PRLibraryMode)];
    if (currentMode != PRLibraryMode) {
        return;
    }
    NSString *title;
    PRPlaylistType type = [[_db playlists] typeForPlaylist:currentPlaylist];
    if (type == PRLibraryPlaylistType) {
        title = @" ";
    } else {
        title = [[_db playlists] titleForPlaylist:currentPlaylist];
        title = [NSString stringWithFormat:@"%@ : ", title];
    }
        
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
	[shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSMutableParagraphStyle *centerAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[centerAlign setAlignment:NSCenterTextAlignment];
    [centerAlign setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont boldSystemFontOfSize:12.5], NSFontAttributeName,
                                [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                centerAlign, NSParagraphStyleAttributeName,
                                shadow, NSShadowAttributeName,
                                nil];
	NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:title attributes:attributes] autorelease];
    
    // other
    PRTimeFormatter2 *timeFormatter2 = [[[PRTimeFormatter2 alloc] init] autorelease];
	PRSizeFormatter *sizeFormatter = [[[PRSizeFormatter alloc] init] autorelease];
	NSDictionary *userInfo = [(PRTableViewController *)[libraryViewController currentViewController] info];
	NSString *formattedString = [NSString stringWithFormat:@"%@ songs, %@, %@", 
                                 [userInfo valueForKey:@"count"], 
                                 [timeFormatter2 stringForObjectValue:[userInfo valueForKey:@"time"]], 
                                 [sizeFormatter stringForObjectValue:[userInfo valueForKey:@"size"]]];
	
	NSMutableDictionary *attributes2 = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         [NSFont systemFontOfSize:11], NSFontAttributeName,
                                         [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
                                         shadow, NSShadowAttributeName,
                                         centerAlign, NSParagraphStyleAttributeName,				  
                                         nil] autorelease];
	[attributedString appendAttributedString:[[[NSAttributedString alloc] initWithString:formattedString attributes:attributes2] autorelease]];
    [attributedString addAttributes:[NSDictionary dictionaryWithObject:centerAlign forKey:NSParagraphStyleAttributeName]
                              range:NSMakeRange(0, [attributedString length])];
	
	[playlistTitle setAttributedStringValue:attributedString];
}

- (void)find
{
    [[searchField window] makeFirstResponder:searchField];
}

// ========================================
// Update
// ========================================

// Private Methods

- (void)playlistDidChange:(NSNotification *)notification
{
	[self willChangeValueForKey:@"search"];
	[self didChangeValueForKey:@"search"];
    [self updateUI];
}

- (void)libraryViewDidChange:(NSNotification *)notification
{
    [self updateUI];
}

- (void)playlistsDidChange:(NSNotification *)notification
{
    [self updateUI];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
    NSRect frame = [centerSuperview frame];
    frame.size.height -= 11;
    [centerSuperview setFrame:frame];
    frame = [controlsSuperview frame];
    frame.origin.y -= 11;
    [controlsSuperview setFrame:frame];
    frame = [nowPlayingSuperview frame];
    frame.size.height -= 11;
    [nowPlayingSuperview setFrame:frame];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification
{
    NSRect frame = [centerSuperview frame];
    frame.size.height += 11;
    [centerSuperview setFrame:frame];
    frame = [controlsSuperview frame];
    frame.origin.y += 11;
    [controlsSuperview setFrame:frame];
    frame = [nowPlayingSuperview frame];
    frame.size.height += 11;
    [nowPlayingSuperview setFrame:frame];
}

- (NSString *)search
{
	if (currentMode != PRLibraryMode) {
		return nil;
	}
	return [[_db playlists] searchForPlaylist:currentPlaylist];
}

- (void)setSearch:(NSString *)search
{	
	if (currentMode != PRLibraryMode) {
		return;
	}
	if (!search) {
		search = @"";
	}
	[[_db playlists] setValue:search forPlaylist:currentPlaylist attribute:PRSearchPlaylistAttribute];
    [[NSNotificationCenter defaultCenter] postPlaylistChanged:currentPlaylist];
}

- (void)libraryModeButtonAction
{
    [self setLibraryViewMode:[libraryModeButton selectedSegment]];
}

- (int)libraryViewMode
{
	if (currentMode != PRLibraryMode) {
		return -1;
	} else {
		return [libraryViewController libraryViewMode];
	}
}

- (void)setLibraryViewMode:(int)libraryViewMode
{
	if (currentMode != PRLibraryMode) {
		return;
	}
	[libraryViewController setLibraryViewMode:libraryViewMode];
}

- (void)headerButtonAction:(id)sender
{
    if ([sender tag] == PRLibraryMode) {
        [self setCurrentPlaylist:[[_db playlists] libraryPlaylist]];
    }
    [self setCurrentMode:[sender tag]];
}


// ========================================
// Window Delegate
// ========================================

- (BOOL)windowShouldClose:(id)sender
{
    if (sender == [self window]) {
        [[self window] orderOut:self];
        [NSApp addWindowsItem:[self window] title:@"Lyre" filename:FALSE];
        return FALSE;
    }
    return TRUE;
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect
{
    rect.origin.y -= 43;
    rect.origin.x += 185/2;
    return rect;
}

@end