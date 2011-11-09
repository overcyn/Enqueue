#import "PRLibraryViewController.h"
#import "PRInfoViewController.h"
#import "PRListViewController.h"
#import "PRAlbumListViewController.h"
#import "PRDb.h"
#import "PRLibrary.h"
#import "PRPlaylists.h"
#import "PRPlaylists+Extensions.h"
#import "PRNowPlayingController.h"
#import "PRLibraryViewSource.h"
#import "PRTimeFormatter2.h"
#import "PRSizeFormatter.h"
#import "PRGradientView.h"
#import "PRCore.h"


@implementation PRLibraryViewController

// ========================================
// Initialization
// ========================================

- (id)initWithCore:(PRCore *)core_
{
    if (!(self = [super initWithNibName:@"PRLibraryView" bundle:nil])) {return nil;}
    core = [core_ retain];
    db = [[core db] retain];
    now = [[core now] retain];
    
    playlist = -1;
    
    [self infoViewToggle];
    [self infoViewToggle];
	return self;
}

- (void)dealloc
{
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

- (void)setPlaylist:(PRPlaylist)newPlaylist;
{
	if (playlist == newPlaylist) {
		return;
	}
	playlist = newPlaylist;
	[self setLibraryViewMode:[self libraryViewMode]];
}

- (PRLibraryViewMode)libraryViewMode
{
    if (playlist == -1) {
        return -1;
    }
	return [[db playlists] libraryViewModeForPlaylist:playlist];
}

- (void)setLibraryViewMode:(PRLibraryViewMode)libraryViewMode
{   
	[listViewController setCurrentPlaylist:-1];
	[albumListViewController setCurrentPlaylist:-1];
    
    [[db playlists] setValue:[NSNumber numberWithInt:libraryViewMode] 
                 forPlaylist:playlist 
                   attribute:PRLibraryViewModePlaylistAttribute];
    
	id oldViewController = currentViewController;
	if (libraryViewMode == PRListMode) {
		currentViewController = listViewController;
	} else if (libraryViewMode == PRAlbumListMode) {
		currentViewController = albumListViewController;
	}
	
	[[currentViewController view] setFrame:[centerSuperview bounds]];
	[centerSuperview replaceSubview:[oldViewController view] with:[currentViewController view]];    
	[currentViewController setCurrentPlaylist:playlist];    
    
    [[NSNotificationCenter defaultCenter] postPlaylistChanged:playlist];
    [[NSNotificationCenter defaultCenter] postLibraryViewSelectionChanged];
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
    [[NSNotificationCenter defaultCenter] postInfoViewVisibleChanged];
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
	[editorSplitView setPosition:330 ofDividerAtIndex:0];
}

// ========================================
// SplitView Delegate
// ========================================

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
