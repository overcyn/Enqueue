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
#import "PRSongViewController.h"
#import "PRCore.h"
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


@interface NSWindow (hush)
- (void)setBottomCornerRounded:(BOOL)rounded;
@end


@implementation PRMainWindowController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    self = [super initWithWindowNibName:@"PRMainWindow"];
	if (self) {
        core = [core_ retain];
		db = [[core_ db] retain];
		now = [[core_ now] retain];
        folderMonitor = [[core_ folderMonitor] retain];
        stringFormatter = [[PRStringFormatter alloc] init];
        [stringFormatter setMaxLength:80];
		currentMode = PRLibraryMode;
		currentPlaylist = 0;
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PRLibraryViewModeDidChangeNotification
                                                  object:nil];
    
    [mainMenuController release];
    [libraryViewController release];
    [preferencesViewController release];
    [playlistsViewController release];
    [historyViewController release];
    [songViewController release];
    [nowPlayingViewController release];
    [controlsViewController release];
    [db release];
    [now release];
    [folderMonitor release];
    [super dealloc];
}

- (void)awakeFromNib
{    
    // Main Menu
    mainMenuController = [[PRMainMenuController alloc] initWithCore:core];
    
	// Window
    [[self window] setDelegate:self];
    [[self window] setBottomCornerRounded:NO];
    
    // Toolbar View
    float x = 0.02;
    NSGradient *gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                             [NSColor colorWithCalibratedWhite:0.98-x alpha:1.0], 0.0,
                             [NSColor colorWithCalibratedWhite:0.97-x alpha:1.0], 0.2,
                             [NSColor colorWithCalibratedWhite:0.94-x alpha:1.0], 0.5,
                             [NSColor colorWithCalibratedWhite:0.90-x alpha:1.0], 1.0,
                             nil] autorelease];
    [toolbarView setVerticalGradient:gradient];
    x = 0.01;
    gradient = [[[NSGradient alloc] initWithColorsAndLocations:
                 [NSColor colorWithCalibratedWhite:0.98-x alpha:1.0], 0.0,
                 [NSColor colorWithCalibratedWhite:0.97-x alpha:1.0], 0.2,
                 [NSColor colorWithCalibratedWhite:0.95-x alpha:1.0], 0.5,
                 [NSColor colorWithCalibratedWhite:0.94-x alpha:1.0], 1.0,
                 nil] autorelease];
    [toolbarView setAlternateVerticalGradient:gradient];
    [toolbarView setTopBorder:[NSColor colorWithCalibratedWhite:1.0 alpha:0.42]];
    [toolbarView setBotBorder:[NSColor colorWithCalibratedWhite:0.15 alpha:1.0]];
    [toolbarView setFrame:NSMakeRect(185, [[self window] frame].size.height - [toolbarView frame].size.height, 
                                     [[self window] frame].size.width - 185, [toolbarView frame].size.height)];
    [[[[self window] contentView] superview] addSubview:toolbarView];
    
    [mainDivider setColor:[NSColor colorWithCalibratedWhite:0.55 alpha:1.0]];
    [toolbarView setLeftBorder:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]];
    
    [divider5 setTopBorder:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]];
    [divider5 setBotBorder:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
    
    [divider setColor:[NSColor colorWithCalibratedWhite:0.98 alpha:1.0]];
    [divider2 setColor:[NSColor colorWithCalibratedWhite:0.98 alpha:1.0]];
    [divider setLeftBorder:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    [divider2 setLeftBorder:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    
    // task window
    NSPoint p = [progressIndicator frame].origin;
    p = [[progressIndicator superview] convertPointToBase:p];
    p.x += 8;
    p.y += 2;
	
    // ViewControllers
    libraryViewController = [[PRLibraryViewController alloc] initWithCore:core];
    preferencesViewController = [[PRPreferencesViewController alloc] initWithCore:core];
	playlistsViewController = [[PRPlaylistsViewController alloc] initWithDb:db mainWindowController:self];
    historyViewController = [[PRHistoryViewController alloc] initWithDb:db mainWindowController:self];
    songViewController = [[PRSongViewController alloc] init];
    taskManagerViewController = [[PRTaskManagerViewController alloc] initWithTaskManager:[core taskManager] core:(PRCore *)core];
    
    nowPlayingViewController = [[PRNowPlayingViewController alloc] initWithDb:db 
                                                         nowPlayingController:now 
                                                         mainWindowController:self];
    [[nowPlayingViewController view] setFrame:[nowPlayingSuperview bounds]];
    [nowPlayingSuperview addSubview:[nowPlayingViewController view]];
	
    controlsViewController = [[PRControlsViewController alloc] initWithCore:core];
    [[controlsViewController view] setFrame:[controlsSuperview bounds]];
    [controlsSuperview addSubview:[controlsViewController view]];
    
    [self setShowsArtwork:[[PRUserDefaults sharedUserDefaults] showsArtwork]];
	
    // Initialize currentViewController
    [[libraryViewController view] setFrame:[centerSuperview bounds]];
    [centerSuperview addSubview:[libraryViewController view]];
	currentViewController = libraryViewController;
    [self setCurrentMode:PRLibraryMode];
    [self setCurrentPlaylist:[[db playlists] libraryPlaylist]];
		
    // Progress Indicator
    [progressIndicator setUsesThreadedAnimation:TRUE];
    [progressIndicator setMaxValue:1];
    [progressIndicator setDisplayedWhenStopped:FALSE];
    [self setProgressHidden:TRUE];
    [self setProgressTitle:@"Scanning for Updates..."];
    
	// Search Field
	[searchField bind:@"value" toObject:self withKeyPath:@"search" options:nil];
    [searchField setFormatter:stringFormatter];
    
    // Info button
    [infoButton setTarget:libraryViewController];
    [infoButton setAction:@selector(infoViewToggle)];
    [[infoButton cell] setShowsStateBy:NSContentsCellMask];
    [[infoButton cell] setHighlightsBy:NSContentsCellMask];
    
    // Library view mode buttons
    [listModeButton setTarget:libraryViewController];
    [listModeButton setAction:@selector(setListMode)];
    [[listModeButton cell] setHighlightsBy:NSContentsCellMask];
    [[listModeButton cell] setShowsStateBy:NSContentsCellMask];
    [albumListModeButton setTarget:libraryViewController];
    [albumListModeButton setAction:@selector(setAlbumListMode)];
    [[albumListModeButton cell] setHighlightsBy:NSContentsCellMask];
    [[albumListModeButton cell] setShowsStateBy:NSContentsCellMask];
	
	// Buttons
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.50]];
	[shadow setShadowOffset:NSMakeSize(1.0, -1.05)];	
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	NSDictionary *attributes = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSFont fontWithName:@"HelveticaNeue-Medium" size:19], NSFontAttributeName,
         [NSColor colorWithCalibratedWhite:0.55 alpha:1.0], NSForegroundColorAttributeName,
         paragraphStyle, NSParagraphStyleAttributeName,
         shadow, NSShadowAttributeName,
         nil];
    NSDictionary *alternateAttributes = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSFont fontWithName:@"HelveticaNeue-Medium" size:19], NSFontAttributeName,
         [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
         paragraphStyle, NSParagraphStyleAttributeName,
         shadow, NSShadowAttributeName,
         nil];
	
    NSAttributedString *attributedTitle;
    NSAttributedString *attributedAlternateTitle;
    attributedTitle = 
        [[[NSAttributedString alloc] initWithString:@"Library" attributes:attributes] autorelease];
    attributedAlternateTitle = 
        [[[NSAttributedString alloc] initWithString:@"Library" attributes:alternateAttributes] autorelease];
    [libraryButton setAction:@selector(headerButtonAction:)];
    [libraryButton setTarget:self];
    [libraryButton setTag:PRLibraryMode];
    [libraryButton setAttributedTitle:attributedTitle];
    [libraryButton setAttributedAlternateTitle:attributedAlternateTitle];
    [libraryButton setShowsBorderOnlyWhileMouseInside:TRUE];
    [[libraryButton cell] setShowsStateBy:NSContentsCellMask];
    [[libraryButton cell] setHighlightsBy:NSContentsCellMask];
    
    attributedTitle = 
        [[[NSAttributedString alloc] initWithString:@"Playlists" attributes:attributes] autorelease];
    attributedAlternateTitle = 
        [[[NSAttributedString alloc] initWithString:@"Playlists" attributes:alternateAttributes] autorelease];
    [playlistsButton setAction:@selector(headerButtonAction:)];
    [playlistsButton setTarget:self];
    [playlistsButton setTag:PRPlaylistsMode];
    [playlistsButton setAttributedTitle:attributedTitle];
    [playlistsButton setAttributedAlternateTitle:attributedAlternateTitle];
    [playlistsButton setShowsBorderOnlyWhileMouseInside:TRUE];
    [[playlistsButton cell] setShowsStateBy:NSContentsCellMask];
    [[playlistsButton cell] setHighlightsBy:NSContentsCellMask];
	
    attributedTitle = 
        [[[NSAttributedString alloc] initWithString:@"History" attributes:attributes] autorelease];
    attributedAlternateTitle = 
        [[[NSAttributedString alloc] initWithString:@"History" attributes:alternateAttributes] autorelease];
    [historyButton setAction:@selector(headerButtonAction:)];
    [historyButton setTarget:self];
    [historyButton setTag:PRHistoryMode];
    [historyButton setAttributedTitle:attributedTitle];
    [historyButton setAttributedAlternateTitle:attributedAlternateTitle];
    [historyButton setShowsBorderOnlyWhileMouseInside:TRUE];
    [[historyButton cell] setShowsStateBy:NSContentsCellMask];
    [[historyButton cell] setHighlightsBy:NSContentsCellMask];
	
    attributedTitle = 
        [[[NSAttributedString alloc] initWithString:@"Preferences" attributes:attributes] autorelease];
    attributedAlternateTitle = 
        [[[NSAttributedString alloc] initWithString:@"Preferences" attributes:alternateAttributes] autorelease];
    [preferencesButton setAction:@selector(headerButtonAction:)];
    [preferencesButton setTarget:self];
    [preferencesButton setTag:PRPreferencesMode];
    [preferencesButton setAttributedTitle:attributedTitle];
    [preferencesButton setAttributedAlternateTitle:attributedAlternateTitle];
    [preferencesButton setShowsBorderOnlyWhileMouseInside:TRUE];
    [[preferencesButton cell] setShowsStateBy:NSContentsCellMask];
    [[preferencesButton cell] setHighlightsBy:NSContentsCellMask];
	
    [songButton setAction:@selector(headerButtonAction:)];
    [songButton	setTarget:self];
    [songButton setTag:PRSongMode];	
    [songButton setImage:[NSImage imageNamed:@"PRDarkIcon"]];
    [songButton setAlternateImage:[NSImage imageNamed:@"PRIcon"]];
    [[songButton cell] setShowsStateBy:NSContentsCellMask];
    [[songButton cell] setHighlightsBy:NSContentsCellMask];
    [[libraryButton cell] setBackgroundStyle:NSBackgroundStyleRaised];
    
    [libraryViewController addObserver:self forKeyPath:@"infoViewVisible" options:0 context:nil];
    
	// Update
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(libraryViewModeDidChange:)
                                                 name:PRLibraryViewModeDidChangeNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(playlistDidChange:)
                                                 name:PRPlaylistDidChangeNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(playlistsDidChange:)
                                                 name:PRPlaylistsDidChangeNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(libraryViewDidChange:) 
												 name:PRLibraryViewDidChangeNotification 
											   object:nil];
    [self libraryViewDidChange:nil];
}

// ========================================
// Accessors
// ========================================

@synthesize taskManagerViewController;
@synthesize songViewController;
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
		case PRSongMode:
			newViewController = songViewController;
			break;
		default:
			break;
	}
    [[newViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview replaceSubview:[currentViewController view] with:[newViewController view]];
	currentViewController = newViewController;
    
    [self updateUI];
    
    [self willChangeValueForKey:@"libraryViewMode"];
	[self didChangeValueForKey:@"libraryViewMode"];
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
    [libraryViewController setCurrentPlaylist:currentPlaylist];
    
    [self updateUI];
    
    [self willChangeValueForKey:@"libraryViewMode"];
	[self didChangeValueForKey:@"libraryViewMode"];
	[self willChangeValueForKey:@"search"];
	[self didChangeValueForKey:@"search"];
}

- (BOOL)showsArtwork
{
    if ([controlsSuperview frame].size.height == 280) {
        return TRUE;
    } else {
        return FALSE;
    }
}

- (void)setShowsArtwork:(BOOL)showsArtwork
{
    [[PRUserDefaults sharedUserDefaults] setShowsArtwork:showsArtwork];

    if (showsArtwork) {
        NSRect frame = [controlsSuperview frame];
        frame.origin.y = [[self window] frame].size.height - 280 - 22;
        frame.size.height = 280;
        [controlsSuperview setFrame:frame];
        
        frame = [nowPlayingSuperview frame];
        frame.size.height = [[self window] frame].size.height - 280 - 22;
        [nowPlayingSuperview setFrame:frame];
    } else {
        NSRect frame = [controlsSuperview frame];
        frame.origin.y = [[self window] frame].size.height - 110 - 22;
        frame.size.height = 115;
        [controlsSuperview setFrame:frame];
        
        frame = [nowPlayingSuperview frame];
        frame.size.height = [[self window] frame].size.height - 110 - 22;
        [nowPlayingSuperview setFrame:frame];
    }
    [controlsViewController setShowsArtwork:showsArtwork];
}

@dynamic progressHidden;
@dynamic progressTitle;
@dynamic progressValue;

- (BOOL)progressHidden
{
    return TRUE;
}

- (void)setProgressHidden:(BOOL)progressHidden
{
    [progressTextField setHidden:progressHidden];
    if (progressHidden) {
        [progressIndicator stopAnimation:nil];
    } else {
        [progressIndicator startAnimation:nil];
    }
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
	NSDictionary *attributes2 = 
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSFont systemFontOfSize:11], NSFontAttributeName,
     [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
     centerAlign, NSParagraphStyleAttributeName,				  
     shadow2, NSShadowAttributeName,
     nil];
	NSMutableAttributedString *attributedString = 
        [[[NSMutableAttributedString alloc] initWithString:progressTitle attributes:attributes2] autorelease];
	[progressTextField setAttributedStringValue:attributedString];
}

- (float)progressValue
{
    return [progressIndicator doubleValue];
}

- (void)setProgressValue:(float)progressValue
{
//    [progressIndicator setDoubleValue:progressValue];
}

// ========================================
// UI
// ========================================

- (void)updateUI
{
    // Header buttons
    [libraryButton setState:NSOffState];
    [playlistsButton setState:NSOffState];
	[historyButton setState:NSOffState];
	[preferencesButton setState:NSOffState];

    switch (currentMode) {
		case PRLibraryMode:
            if ([self currentPlaylist] == [[db playlists] libraryPlaylist]) {
                [libraryButton setState:NSOnState];
            } else {
                [playlistsButton setState:NSOnState];
            }
			break;
		case PRPlaylistsMode:
			[playlistsButton setState:NSOnState];
			break;
		case PRHistoryMode:
			[historyButton setState:NSOnState];			
			break;
		case PRPreferencesMode:
			[preferencesButton setState:NSOnState];
			break;
		default:
			break;
	}
    
    // Library view mode buttons
    [listModeButton setState:NSOnState];
    [listModeButton setEnabled:TRUE];
    [albumListModeButton setState:NSOnState];
    [albumListModeButton setEnabled:TRUE];
    switch ([self libraryViewMode]) {
        case PRListMode:
            [listModeButton setState:NSOffState];
            [listModeButton setEnabled:FALSE];
            break;
        case PRAlbumListMode:
            [albumListModeButton setState:NSOffState];
            [albumListModeButton setEnabled:FALSE];
            break;
        default:
            break;
    }
    [listModeButton setHidden:(currentMode != PRLibraryMode)];
    [albumListModeButton setHidden:(currentMode != PRLibraryMode)];
    [infoButton setHidden:(currentMode != PRLibraryMode)];
    [divider setHidden:(currentMode != PRLibraryMode)];
    [divider2 setHidden:(currentMode != PRLibraryMode)];
    
    // Search field
    [searchField setEnabled:(currentMode == PRLibraryMode)];
    if ([libraryViewController infoViewVisible]) {
        [infoButton setImage:[NSImage imageNamed:@"PRInfoOffIcon.png"]];
    } else {
        [infoButton setImage:[NSImage imageNamed:@"PRInfoIconTemplate"]];
    }
    
    // Playlist title
    [playlistTitle setHidden:!(currentMode == PRLibraryMode)];
    NSString *title;
    
    NSNumber *type = nil;
    [[db playlists] value:&type forPlaylist:currentPlaylist attribute:PRTypePlaylistAttribute _error:nil];
    if ([type intValue] == PRLibraryPlaylistType) {
        title = @" ";
    } else {
        [[db playlists] value:&title forPlaylist:currentPlaylist attribute:PRTitlePlaylistAttribute _error:nil];
        title = [NSString stringWithFormat:@"%@ : ", title]; //  ▾☰♪
    }
    
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.5]];
	[shadow setShadowOffset:NSMakeSize(1.1, -1.3)];
    NSMutableParagraphStyle *centerAlign = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[centerAlign setAlignment:NSCenterTextAlignment];
    [centerAlign setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *attributes = 
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSFont boldSystemFontOfSize:12.5], NSFontAttributeName,
     [NSColor colorWithDeviceWhite:0.3 alpha:1.0], NSForegroundColorAttributeName,
     centerAlign, NSParagraphStyleAttributeName,				  
     shadow, NSShadowAttributeName,
     nil];
	NSMutableAttributedString *attributedString = 
    [[[NSMutableAttributedString alloc] initWithString:title attributes:attributes] autorelease];
	[playlistTitle setAttributedStringValue:attributedString];
    
    // other
    PRTimeFormatter2 *timeFormatter2 = [[[PRTimeFormatter2 alloc] init] autorelease];
	PRSizeFormatter *sizeFormatter = [[[PRSizeFormatter alloc] init] autorelease];
	NSDictionary *userInfo = [(PRTableViewController *)[libraryViewController currentViewController] info];
	NSNumber *count = [userInfo valueForKey:@"count"];
	NSNumber *time = [userInfo valueForKey:@"time"];
	NSNumber *size = [userInfo valueForKey:@"size"];
	NSString *formattedString = 
    [NSString stringWithFormat:@"%@ songs, %@, %@", 
     count, [timeFormatter2 stringForObjectValue:time], [sizeFormatter stringForObjectValue:size]];
	
	NSMutableDictionary *attributes2 = 
    [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
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

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if (object == libraryViewController && [keyPath isEqualToString:@"infoViewVisible"]) {
        [self updateUI];
    }
}

// Private Methods

- (void)playlistDidChange:(NSNotification *)notification
{
	[self willChangeValueForKey:@"search"];
	[self didChangeValueForKey:@"search"];
    [self updateUI];
}

- (void)libraryViewModeDidChange:(NSNotification *)notification
{
    [self updateUI];
	[self willChangeValueForKey:@"libraryViewMode"];
	[self didChangeValueForKey:@"libraryViewMode"];
}

- (void)libraryViewDidChange:(NSNotification *)notification
{
    [self updateUI];
}

- (void)playlistsDidChange:(NSNotification *)notification
{
    [self updateUI];
}

- (NSString *)search
{
	if (currentMode != PRLibraryMode) {
		return nil;
	}
	
	NSString *search;
	[[db playlists] value:&search 
			  forPlaylist:currentPlaylist 
				attribute:PRSearchPlaylistAttribute 
				   _error:nil];
	return search;
}

- (void)setSearch:(NSString *)search
{	
	if (currentMode != PRLibraryMode) {
		return;
	}
	if (!search) {
		search = @"";
	}
	
	[[db playlists] setValue:search 
				 forPlaylist:currentPlaylist 
				   attribute:PRSearchPlaylistAttribute 
					  _error:nil];
	NSDictionary *userInfo = 
      [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:currentPlaylist] 
                                  forKey:@"playlist"];
	[[NSNotificationCenter defaultCenter] postNotificationName:PRPlaylistDidChangeNotification 
														object:self
													  userInfo:userInfo];
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
        [self setCurrentPlaylist:[[db playlists] libraryPlaylist]];
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
    rect.origin.y -= 38;
    rect.origin.x += 185/2;
    return rect;
}

@end