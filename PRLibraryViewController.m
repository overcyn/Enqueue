#import "PRLibraryViewController.h"
#import "PRInfoViewController.h"
#import "PRListViewController.h"
#import "PRAlbumListViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRNowPlayingController.h"
#import "PRSmartPlaylistEditorViewController.h"
#import "PRStaticPlaylistEditorViewController.h"
#import "PRLibraryViewSource.h"
#import "PRTimeFormatter2.h"
#import "PRSizeFormatter.h"
#import "PRGradientView.h"
#import "PRCore.h"


NSString * const PRLibraryViewSelectionDidChangeNotification = @"PRLibraryViewSelectionDidChangeNotification";
NSString * const PRLibraryViewModeDidChangeNotification = @"PRLibraryViewModeDidChangeNotification";

@implementation PRLibraryViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    self = [super initWithNibName:@"PRLibraryView" bundle:nil];
	if (self) {
        core = [core_ retain];
        db = [[core db] retain];
		now = [[core now] retain];
		
		dividerPosition = 330;
		currentPlaylist = -1;
        
        [self infoViewToggle];
        [self infoViewToggle];
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PRLibraryViewModeDidChangeNotification object:nil];
    
    [smartPlaylistEditorViewController release];
    [staticPlaylistEditorViewController release];
    [infoViewController release];
    [listViewController release];
    [albumListViewController release];
    [db release];
    [now release];
    [super dealloc];
}

- (void)awakeFromNib
{	
	// Panes
//	smartPlaylistEditorViewController = [[[PRSmartPlaylistEditorViewController alloc] initWithDb:db] retain];
//	staticPlaylistEditorViewController = [[[PRStaticPlaylistEditorViewController alloc] init] retain];
	infoViewController = [[PRInfoViewController alloc] initWithCore:core];
	
	[[smartPlaylistEditorViewController view] setFrame:[paneSuperview bounds]];
	[paneSuperview addSubview:[smartPlaylistEditorViewController view]];
	currentPaneViewController = smartPlaylistEditorViewController;
	
	// SplitViews
	[editorSplitView setDelegate:self];
	[self paneViewCollapse];
	
	// ListView
	listViewController = [[PRListViewController alloc] initWithDb:db 
                                             nowPlayingController:now
                                            libraryViewController:self];
	// AlbumListView
	albumListViewController = [[PRAlbumListViewController alloc] initWithDb:db
                                                       nowPlayingController:now
                                                      libraryViewController:self];
	
	[[listViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview addSubview:[listViewController view]];
	currentViewController = listViewController;
    
    // PRGradientView
    [gradientView setTopGradient:[NSColor colorWithCalibratedWhite:0.89 alpha:1.0]];
    [gradientView setBotGradient:[NSColor colorWithCalibratedWhite:0.84 alpha:1.0]];
    [gradientView setTopBorder:[NSColor colorWithCalibratedWhite:0.98 alpha:1.0]];
    [gradientView setBotBorder:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
}

// ========================================
// Accessors
// ========================================

@synthesize currentViewController;

- (void)setCurrentPlaylist:(PRPlaylist)playlist;
{
	if (currentPlaylist == playlist) {
		return;
	}
	currentPlaylist = playlist;
	[self setLibraryViewMode:[self libraryViewMode]];
//	[smartPlaylistEditorViewController setCurrentPlaylist:currentPlaylist];
}

- (PRLibraryViewMode)libraryViewMode
{
    if (currentPlaylist == -1) {
        return -1;
    }
    
	int libraryViewMode;
	[[db playlists] intValue:&libraryViewMode 
                 forPlaylist:currentPlaylist 
                   attribute:PRLibraryViewModePlaylistAttribute 
                      _error:nil];
	return libraryViewMode;
}

- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode
{   
	[listViewController setCurrentPlaylist:-1];
	[albumListViewController setCurrentPlaylist:-1];
    
	[[db playlists] setIntValue:libraryViewMode 
                    forPlaylist:currentPlaylist
                      attribute:PRLibraryViewModePlaylistAttribute 
                         _error:nil];
    
	id oldViewController = currentViewController;
	if (libraryViewMode == PRListMode) {
		currentViewController = listViewController;
	} else if (libraryViewMode == PRAlbumListMode) {
		currentViewController = albumListViewController;
	}
	
	[[currentViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview replaceSubview:[oldViewController view] with:[currentViewController view]];    
	[currentViewController setCurrentPlaylist:currentPlaylist];    
    
	[[NSNotificationCenter defaultCenter] postNotificationName:PRLibraryViewModeDidChangeNotification 
														object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:PRLibraryViewSelectionDidChangeNotification object:currentViewController];
}

- (void)setListMode
{
    [self setLibraryViewMode:PRListMode];
}

- (void)setAlbumListMode
{
    [self setLibraryViewMode:PRAlbumListMode];
}

// ========================================
// UI
// ========================================

- (void)editorViewToggle
{
	if (edit && currentPaneViewController == smartPlaylistEditorViewController) {
		[self paneViewCollapse];
	} else {
		[self paneViewCollapse];
		[self paneViewUncollapse];
		[[smartPlaylistEditorViewController view] setFrame:[paneSuperview bounds]];
		[paneSuperview addSubview:[smartPlaylistEditorViewController view]];
		
		currentPaneViewController = smartPlaylistEditorViewController;
		
	}
}

- (void)infoViewToggle
{
	if (edit && currentPaneViewController == infoViewController) {
		[self paneViewCollapse];
	} else {
		[self paneViewCollapse];
		[self paneViewUncollapse];
		[[infoViewController view] setFrame:[paneSuperview bounds]];
		[paneSuperview addSubview:[infoViewController view]];
		
		currentPaneViewController = infoViewController;
	}
    [self willChangeValueForKey:@"infoViewVisible"];
    [self didChangeValueForKey:@"infoViewVisible"];
}

- (BOOL)infoViewVisible
{
    return edit && currentPaneViewController == infoViewController;
}

- (void)highlightFile:(PRFile)file
{
	[currentViewController highlightFile:file];
}

- (void)paneViewCollapse
{	
	edit = FALSE;
	[[currentPaneViewController view] removeFromSuperview];
	[editorSplitView setPosition:21 ofDividerAtIndex:0];
}

- (void)paneViewUncollapse
{
	edit = TRUE;
	[editorSplitView setPosition:dividerPosition ofDividerAtIndex:0];
}

// SplitView Delegate

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview 
{
    return (subview == centerSuperview);
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	return TRUE;
}

- (NSRect)splitView:(NSSplitView *)splitView 
	  effectiveRect:(NSRect)proposedEffectiveRect 
	   forDrawnRect:(NSRect)drawnRect 
   ofDividerAtIndex:(NSInteger)dividerIndex
{
    return NSZeroRect;
}

- (CGFloat)splitView:(NSSplitView *)splitView 
  constrainSplitPosition:(CGFloat)proposedPosition 
		 ofSubviewAt:(NSInteger)dividerIndex
{	
	if (!edit) {
		return [editorSplitView frame].size.height;
	} else {
        return [editorSplitView frame].size.height - 128;	
	}
	return proposedPosition;
}

@end
